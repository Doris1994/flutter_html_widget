import 'package:flutter/material.dart';
import 'dart:async' show Future;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../utils/utils.dart';

/// Mobile implementation
class HtmlController extends ValueNotifier<String> {
  /// Webview controller connector
  late InAppWebViewController connector;

  HtmlController({required String src}) : super(src);

  void _setContent(String url) {
    super.value = url;
  }

  void load(
    String url, {
    Map<String, String> headers = const {},
  }) async {
    _setContent(url);
    connector.loadUrl(
        urlRequest: URLRequest(url: Uri.parse(url), headers: headers));
  }

  /// This function allows you to call Javascript functions defined inside the webview.
  ///
  /// Suppose we have a defined a function (using [EmbeddedJsContent]) as follows:
  ///
  /// ```javascript
  /// function someFunction(param) {
  ///   return 'This is a ' + param;
  /// }
  /// ```
  /// Example call:
  ///
  /// ```dart
  /// var resultFromJs = await callJsMethod('someFunction', ['test'])
  /// print(resultFromJs); // prints "This is a test"
  /// ```
  //TODO This should return an error if the operation failed, but it doesn't
  Future<dynamic> callJsMethod(
    String name,
    List<dynamic> params,
  ) async {
    // This basically will transform a "raw" call (evaluateJavascript)
    // into a little bit more "typed" call, that is - calling a method.
    var result = await connector.evaluateJavascript(
      source: HtmlUtils.buildJsFunction(name, params),
    );

    // (MOBILE ONLY) Unquotes response if necessary
    //
    // In the mobile version responses from Js to Dart come wrapped in single quotes (')
    // The web works fine because it is already into it's native environment
    return HtmlUtils.unQuoteJsResponseIfNeeded(result);
  }

  /// This function allows you to evaluate 'raw' javascript (e.g: 2+2)
  /// If you need to call a function you should use the method above ([callJsMethod])
  ///
  /// The [inGlobalContext] param should be set to true if you wish to eval your code
  /// in the 'window' context, instead of doing it inside the corresponding iframe's 'window'
  ///
  /// For more info, check Mozilla documentation on 'window'
  Future<dynamic> evalRawJavascript(
    String rawJavascript, {
    bool inGlobalContext = false, // NO-OP HERE
  }) {
    return connector.evaluateJavascript(source: rawJavascript);
  }

  /// Returns a Future that completes with the value true, if you can go
  /// back in the history stack.
  Future<bool> canGoBack() {
    return connector.canGoBack();
  }

  /// Go back in the history stack.
  Future<void> goBack() {
    return connector.goBack();
  }

  /// Returns a Future that completes with the value true, if you can go
  /// forward in the history stack.
  Future<bool> canGoForward() {
    return connector.canGoForward();
  }

  /// Go forward in the history stack.
  Future<void> goForward() {
    return connector.goForward();
  }

  /// Reload the current content.
  Future<void> reload() {
    return connector.reload();
  }

  /// Dispose resources
  @override
  void dispose() {
    super.dispose();
  }
}
