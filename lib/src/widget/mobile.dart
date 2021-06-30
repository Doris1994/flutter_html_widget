import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../utils/utils.dart';
import '../controller/controller.dart';

/// Mobile implementation
class WebViewXWidget extends StatefulWidget {
  /// Initial content
  final String src;

  /// Widget width
  final double? width;

  /// Widget height
  final double? height;

  final bool adaptHeight;

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
    required this.src,
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
  late InAppWebViewController originalWebViewController;
  late HtmlController webViewXController;
  double contentHeight = 0;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false,
          supportZoom: false,
          //horizontalScrollBarEnabled: false,
          verticalScrollBarEnabled: false),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  @override
  void initState() {
    super.initState();
    webViewXController = _createWebViewXController();
  }

  @override
  Widget build(BuildContext context) {
    final onWebViewCreated = (InAppWebViewController webViewController) {
      originalWebViewController = webViewController;
      webViewXController.connector = originalWebViewController;
      widget.onWebViewCreated?.call(webViewXController);
    };

    final onWebViewFinished =
        (InAppWebViewController controller, Uri? url) async {
      if (widget.adaptHeight) {
        int resultFromJs = await controller.evaluateJavascript(
            source: 'document.body.scrollHeight');
        double height = resultFromJs.toDouble();
        setState(() {
          contentHeight = height;
          // contentHeight = min(400, height);
        });
      }
      widget.onPageFinished?.call(url.toString());
    };

    return Container(
      height: contentHeight,
      child: InAppWebView(
        key: widget.key,
        initialUrlRequest: URLRequest(url: Uri.parse(widget.src)),
        onWebViewCreated: onWebViewCreated,
        initialUserScripts: UnmodifiableListView<UserScript>([]),
        initialOptions: options,
        gestureRecognizers:
            widget.mobileSpecificParams.mobileGestureRecognizers,
        androidOnPermissionRequest: (controller, origin, resources) async {
          return PermissionRequestResponse(
              resources: resources,
              action: PermissionRequestResponseAction.GRANT);
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          return NavigationActionPolicy.ALLOW;
        },
        onLoadStart: (controller, url) {
          widget.onPageStarted?.call(url.toString());
        },
        onLoadStop: onWebViewFinished,
        onLoadError: (controller, url, code, message) {
          widget.onWebResourceError?.call(
              WebResourceError(
                description: message,
                errorCode: code,
                failingUrl: url.toString(),
              ),
            );
        },
      ),
    );
  }

  // Creates a WebViewXController and adds the listener
  HtmlController _createWebViewXController() {
    return HtmlController(
      src: widget.src,
    )
      ..addListener(_handleChange);
  }

  // Called when WebViewXController updates it's value
  void _handleChange() {
    final url = webViewXController.value;
    originalWebViewController.loadUrl(urlRequest: URLRequest(url: Uri.parse(url)));
  }


  @override
  void dispose() {
    webViewXController.removeListener(_handleChange);
    super.dispose();
  }
}
