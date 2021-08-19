import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/utils.dart';
import '../web_view_delegate.dart';

/// Facade widget
///
/// Trying to use this will throw UnimplementedError.
class WebViewXWidget extends StatefulWidget {
  /// Initial content
  final String src;

  final bool adaptHeight;

  /// Widget width
  final double? width;

  /// Widget height
  final double? height;

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
    this.adaptHeight = false,
    this.width,
    this.height,
    this.delegate,
    this.webSpecificParams = const WebSpecificParams(),
    this.mobileSpecificParams = const MobileSpecificParams(),
  }) : super(key: key);

  @override
  _WebViewXWidgetState createState() => _WebViewXWidgetState();
}

class _WebViewXWidgetState extends State<WebViewXWidget> {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError(
        'This is the unimplemented version of this widget. Please import "webviewx.dart" instead.');
  }
}
