import 'package:flutter/material.dart';
import '../utils/web_history.dart';

/// Facade controller
///
/// Throws UnimplementedError if used.
class HtmlController extends ValueNotifier<String> {
  /// Cross-platform webview connector
  ///
  /// At runtime, this will be either of type WebViewController or JsObject
  late dynamic connector;

  /// Constructor
  HtmlController({
    required String src
  })   : super(src);

  /// Set webview content to the specified URL.
  /// Example URL: https://flutter.dev
  ///
  /// If [fromAssets] param is set to true,
  /// [url] param must be a String path to an asset
  /// Example: 'assets/some_url.txt'
  void loadContent(
    String content,{
    Map<String, String> headers = const {},
  }) async =>
      throw UnimplementedError();

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
  Future<dynamic> callJsMethod(
    String name,
    List<dynamic> params,
  ) =>
      throw UnimplementedError();

  /// This function allows you to evaluate 'raw' javascript (e.g: 2+2)
  /// If you need to call a function you should use the method above ([callJsMethod])
  ///
  /// The [inGlobalContext] param should be set to true if you wish to eval your code
  /// in the 'window' context, instead of doing it inside the corresponding iframe's 'window'
  ///
  /// For more info, check Mozilla documentation on 'window'
  Future<dynamic> evalRawJavascript(
    String rawJavascript, {
    bool inGlobalContext = false,
  }) =>
      throw UnimplementedError();

  /// Returns a Future that completes with the value true, if you can go
  /// back in the history stack.
  Future<bool> canGoBack() => throw UnimplementedError();

  /// Go back in the history stack.
  Future<void> goBack() => throw UnimplementedError();

  /// Returns a Future that completes with the value true, if you can go
  /// forward in the history stack.
  Future<bool> canGoForward() => throw UnimplementedError();

  /// Go forward in the history stack.
  Future<void> goForward() => throw UnimplementedError();

  /// Reload the current content.
  Future<void> reload() => throw UnimplementedError();

  /// Dispose resources
  @override
  void dispose() {
    super.dispose();
    throw UnimplementedError();
  }
}
