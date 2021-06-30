import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/utils.dart';
import '../utils/constants.dart';
import '../utils/web_history.dart';
import '../controller/web.dart';
import '../utils/dart_ui_fix.dart' as ui;
import '../utils/x_frame_options_bypass.dart';

/// Web implementation
class WebViewXWidget extends StatefulWidget {
  /// Initial content
  final String src;

  final bool adaptHeight;

  /// Widget width
  final double? width;

  /// Widget height
  final double? height;

  /// Callback which returns a referrence to the [WebViewXController]
  /// being created.
  final Function(HtmlController controller)? onWebViewCreated;

  /// Callback for when the page starts loading.
  final void Function(String src)? onPageStarted;

  /// Callback for when the page has finished loading (i.e. is shown on screen).
  final void Function(String src)? onPageFinished;

  /// Callback for when something goes wrong in while page or resources load.
  final void Function(WebResourceError error)? onWebResourceError;

  /// Parameters specific to the web version.
  /// This may eventually be merged with [mobileSpecificParams],
  /// if all features become cross platform.
  final WebSpecificParams webSpecificParams;

  /// Parameters specific to the web version.
  /// This may eventually be merged with [webSpecificParams],
  /// if all features become cross platform.
  final MobileSpecificParams mobileSpecificParams;

  /// Constructor
  WebViewXWidget({
    Key? key,
    this.src = '',
    this.adaptHeight = false,
    this.width,
    this.height,
    this.onWebViewCreated,
    this.onPageStarted,
    this.onPageFinished,
    this.onWebResourceError,
    this.webSpecificParams = const WebSpecificParams(),
    this.mobileSpecificParams = const MobileSpecificParams(),
  }) : super(key: key);

  @override
  _WebViewXWidgetState createState() => _WebViewXWidgetState();
}

class _WebViewXWidgetState extends State<WebViewXWidget> {
  late String elementViewType;
  late StreamSubscription iframeOnLoadSubscription;
  late js.JsObject jsWindowObject;

  late html.Element element;

  late HtmlController controller;
  double contentHeight = 100;

  // Pseudo state used to find out if the current iframe
  // has started or finished loading.
  late bool _pageLoadFinished;

  bool get isIframe => element.runtimeType is html.IFrameElement;

  @override
  void initState() {
    super.initState();
    // Initialize to true, because it will start loading once it is created
    _pageLoadFinished = false;

    controller = _createWebViewXController();

    elementViewType = _createViewType();
    // final iframe = html.IFrameElement()
    //   ..srcdoc = widget.src
    //   ..style.border = 'none';
    element = widget.adaptHeight ? _createDivElement() : _createIFrame();

    _addXFrameElement();

    _registerIframeOnLoadCallback();

    _connectJsToFlutter();

    ui.platformViewRegistry.registerViewFactory(
      elementViewType,
      (int id) {
        html.window.onMessage.listen(
          (event) {
            final Map<String, dynamic> data = jsonDecode(event.data);
            if (data.containsKey('contentHeight')) {
              var height = data['contentHeight'];
              print('on message contentHeight: $height');
              setState(() {
                contentHeight = height;
              });
            }
          },
        );
        return element;
      },
    );

    widget.onWebViewCreated?.call(controller);

    // Hack to allow the iframe to reach the "begin loading" state.
    // Otherwise it will fail loading the initial content.
    // Future.delayed(Duration.zero, () {
    //   final newContentModel = controller.value;
    //   _updateSource(newContentModel);
    // });
  }

  void _addXFrameElement() {
    var head = html.document.head!;

    var script = html.ScriptElement()
      ..text = XFrameOptionsBypass.build(
          cssloader: widget.webSpecificParams.cssLoadingIndicator,
          printDebugInfo: widget.webSpecificParams.printDebugInfo,
          id: element.id);

    if (!head.contains(script)) {
      head.append(script);
    }

    /*var jquery = html.ScriptElement();
    jquery.src = "https://code.jquery.com/jquery-3.6.0.min.js";
    head.append(jquery);*/

    _printIfDebug('The XFrameBypass custom iframe element has loaded');
  }

  html.IFrameElement _createIFrame() {
    // ignore: unsafe_html
    var xFrameBypassElement = html.Element.html(
      '<iframe is="x-frame-bypass"></iframe>',
      validator: null,
      treeSanitizer: html.NodeTreeSanitizer.trusted,
    ) as html.IFrameElement;

    var iframeElement = xFrameBypassElement
      ..src = widget.src
      ..id = 'id_$elementViewType'
      ..name = 'name_$elementViewType'
      ..style.border = 'none'
      ..style.top = "0px"
      ..style.bottom = "0px"
      ..style.left = "0px"
      ..style.right = "0px"
      ..width = '100%'
      ..height = '100%'
      ..allowFullscreen = widget.webSpecificParams.webAllowFullscreenContent;

    widget.webSpecificParams.additionalSandboxOptions
        .forEach(iframeElement.sandbox!.add);

    iframeElement.sandbox!.add('allow-scripts');

    var allow = widget.webSpecificParams.additionalAllowOptions;

    iframeElement.allow = allow.reduce((curr, next) => '$curr; $next');

    return iframeElement;
  }

  html.DivElement _createDivElement() {
    // ignore: unsafe_html
    var div = html.Element.html(
      '<div>Loading...</div>',
      validator: null,
      treeSanitizer: html.NodeTreeSanitizer.trusted,
    ) as html.DivElement;

    var divElement = div
      //..srcdoc = widget.src
      ..id = 'id_$elementViewType'
      ..style.border = 'none'
      ..style.color = '#000000'
      ..style.textAlign = 'center'
      ..style.top = "0px"
      ..style.bottom = "0px"
      ..style.left = "0px"
      ..style.right = "0px";

    return divElement;
  }

  HtmlController _createWebViewXController() {
    return HtmlController(src: widget.src)..addListener(_handleChange);
  }

  // Keep js "window" object referrence, so we can call functions on it later.
  // This happens only if we use HTML (because you can't alter the source code
  // of some other webpage that you pass in using the URL param)
  //
  // Iframe viewType is used as a disambiguator.
  // Check function [embedWebIframeJsConnector] from [HtmlUtils] for details.
  void _connectJsToFlutter({VoidCallback? then}) {
    js.context['$JS_DART_CONNECTOR_FN$elementViewType'] = (window) {
      jsWindowObject = window;

      // Register history callback
      jsWindowObject[WEB_HISTORY_CALLBACK] = (newHref) {
        if (newHref != null) {
          controller.webAddHistory(
            HistoryEntry(
              source: newHref,
            ),
          );
          _printIfDebug('Got a new history entry');
        }
      };

      controller.connector = jsWindowObject;

      if (then != null) {
        then();
      }
    };
  }

  void _registerIframeOnLoadCallback() async {
    html.Element _element = isIframe ? element : html.document.body!;
    iframeOnLoadSubscription = _element.onLoad.listen((event) async {
      _printIfDebug('element $elementViewType has been (re)loaded.');

      if (_pageLoadFinished) {
        // This means it has loaded twice, so it has finished loading
        widget.onPageFinished?.call(controller.value);
        var height = controller.evalRawJavascript(
            'document.getElementById("${element.id}").contentWindow.document.body.scrollHeight;',
            inGlobalContext: true);
        print('content height: $height');
        _pageLoadFinished = false;
      } else {
        // This means it is the first time it loads
        widget.onPageStarted?.call(controller.value);
        _pageLoadFinished = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: SizedBox(
          width: widget.width,
          height: contentHeight,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return HtmlElementView(
                key: widget.key,
                viewType: elementViewType,
              );
            },)
          ),
    );
  }

  // This creates a unique String to be used as the view type of the HtmlElementView
  String _createViewType() {
    if (widget.adaptHeight) {
      return 'html-div-${controller.hashCode}';
    }
    return 'html-iframe-${controller.hashCode}';
  }

  // Called when WebViewXController updates it's value
  //
  // When the content changes from URL to HTML,
  // the connection must be remade in order to
  // add the connector to the controller (connector that
  // allows you to call JS methods)
  void _handleChange() {
    final newSrc = controller.value;

    _pageLoadFinished = false;
    _updateSource(newSrc);
  }

  // Updates the source depending if it is HTML or URL
  void _updateSource(String url) {
    var source = url;
    print('_update source : $url view type: ${element.id}');
    if (source.isEmpty) {
      _printIfDebug('Error: Cannot set empty source on webview');
      return;
    }

    if (source.startsWith(RegExp('http[s]?', caseSensitive: false))) {
      if (isIframe) {
        html.IFrameElement iframe = element as html.IFrameElement;
        if (iframe.contentWindow == null) return;
        iframe.contentWindow!.location.href = source;
      } else {
        /*controller.evalRawJavascript('\$("#${element.id}").load($source);',
            inGlobalContext: true);*/
        js.context.callMethod('loadUrl', [source]);
      }
    } else {
      _printIfDebug('Error: Invalid URL supplied for webview.');
    }
  }

  void _printIfDebug(String text) {
    if (widget.webSpecificParams.printDebugInfo) {
      print(text);
    }
  }

  @override
  void dispose() {
    iframeOnLoadSubscription.cancel();
    controller.removeListener(_handleChange);
    super.dispose();
  }
}
