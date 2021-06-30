import 'package:flutter/material.dart';
import 'dart:js' as js;

import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import '../utils/utils.dart';
import '../utils/web_history.dart';

/// Web implementation
class HtmlController extends ValueNotifier<String> {
  /// JsObject connector
  late js.JsObject connector;

  //late Future<void> Function(String function) invokeJavascript;

  // Stack-based custom history
  // First entry is the current url, last entry is the initial url
  final HistoryStack _history;

  bool printDebugInfo = false;

  /// Constructor
  HtmlController({
    required String src
  })  :_history = HistoryStack(
          initialEntry: HistoryEntry(
            source: src
          ),
        ), super(src){
          value = src;
          //invokeJavascript = (_) async{};
        }

   void _setContent(String url) {
    value = url;
  }

  /// Set webview content to the specified URL.
  /// Example URL: https://flutter.dev
  ///
  /// If [fromAssets] param is set to true,
  /// [url] param must be a String path to an asset
  /// Example: 'assets/some_url.txt'
  void loadContent(
    String content,{
    Map<String, String> headers = const {},
  }) async {
    _setContent(content);
    webAddHistory(HistoryEntry(source: content));
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
  Future<dynamic> callJsMethod(
    String name,
    List<dynamic> params,
  ) {
    var result = connector.callMethod(name, params);
    return Future<dynamic>.value(result);
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
    bool inGlobalContext = false,
  }) {
    var result = (inGlobalContext ? js.context : connector).callMethod(
      'eval',
      [rawJavascript],
    );
    return Future<dynamic>.value(result);
  }

  /// WEB-ONLY. YOU SHOULDN'T NEED TO CALL THIS FROM YOUR CODE.
  ///
  /// This is called internally by the web.dart view class, to add a new
  /// iframe navigation history entry.
  ///
  /// This, and all history-related stuff is needed because the history on web
  /// is basically reimplemented by me from scratch using the [HistoryEntry] class.
  /// This had to be done because I couldn't intercept iframe's navigation events and
  /// current url.
  void webAddHistory(HistoryEntry entry) {
    _history.addEntry(entry);
    _printIfDebug(_history.toString());
  }


  /// Returns a Future that completes with the value true, if you can go
  /// back in the history stack.
  Future<bool> canGoBack() {
    return Future.value(_history.canGoBack);
  }

  /// Go back in the history stack.
  Future<void> goBack() async {
    var entry = _history.moveBack();
    _setContent(entry.source);
    _printIfDebug(_history.toString());
  }

  /// Returns a Future that completes with the value true, if you can go
  /// forward in the history stack.
  Future<bool> canGoForward() {
    return Future.value(_history.canGoForward);
  }

  /// Go forward in the history stack.
  Future<void> goForward() async {
    var entry = _history.moveForward();
    _setContent(entry.source);
    _printIfDebug(_history.toString());
  }

  /// Reload the current content.
  Future<void> reload() async {
    _setContent(_history.currentEntry!.source);
  }

  void _printIfDebug(String text) {
    if (printDebugInfo) {
      print(text);
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    super.dispose();
  }
}
