import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../utils/utils.dart';
import '../controller/controller.dart';
import '../web_view_delegate.dart';

/// Mobile implementation
class WebViewXWidget extends StatefulWidget {
  /// Initial content
  final String src;

  /// Widget width
  final double? width;

  /// Widget height
  final double? height;

  final bool adaptHeight;

  final WebViewDelegate? delegate;

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
    this.delegate,
    this.adaptHeight = false,
    this.width,
    this.height,
    this.webSpecificParams = const WebSpecificParams(),
    this.mobileSpecificParams = const MobileSpecificParams(),
  }) : super(key: key);

  @override
  _WebViewXWidgetState createState() => _WebViewXWidgetState();
}

class _WebViewXWidgetState extends State<WebViewXWidget> {
  late HtmlController webViewXController;
  late WebViewDelegate? _delegate;
  double contentHeight = 0;
  late InAppWebViewGroupOptions options;

  @override
  void initState() {
    super.initState();
    _delegate = widget.delegate;
    contentHeight = widget.height ?? 100;
    webViewXController = HtmlController(src: widget.src);
    options = InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
            userAgent: _delegate?.customUserAgent ?? '',
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
  }

  @override
  Widget build(BuildContext context) {
    final onWebViewCreated = (InAppWebViewController webViewController) {
      webViewXController.connector = webViewController;
      _delegate?.onWebViewCreated(webViewXController);
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
      if (Platform.isAndroid) {
        String? title = await controller.getTitle();
        if (title != null && title.isNotEmpty) {
          _delegate?.onTitleChanged(title);
        }
      }
      _delegate?.onPageFinished(url.toString());
    };

    return Container(
      height: contentHeight,
      child: InAppWebView(
        key: widget.key,
        initialUrlRequest:
            URLRequest(url: Uri.parse(widget.src), headers: _delegate?.headers),
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
          Uri? uri = navigationAction.request.url;
          debugPrint(uri.toString());
          bool result =
              _delegate?.shouldOverrideUrlLoading(uri.toString()) ?? true;
          return result
              ? NavigationActionPolicy.ALLOW
              : NavigationActionPolicy.CANCEL;
        },
        onLoadStart: (controller, url) {
          _delegate?.onPageStarted(url.toString());
        },
        onLoadStop: onWebViewFinished,
        onProgressChanged: (controller, progress) {
          //print('=================$progress======================');
          _delegate?.onProgressChanged(progress);
        },
        onTitleChanged: (controller, title) {
          _delegate?.onTitleChanged(title ?? '');
        },
        onLoadError: (controller, url, code, message) {
          _delegate?.onWebResourceError(
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

  @override
  void dispose() {
    super.dispose();
  }
}
