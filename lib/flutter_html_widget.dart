library flutter_html_widget;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'src/widget/view.dart';
import 'src/web_view_delegate.dart';
import 'src/utils/utils.dart';

export 'src/utils/webview_flutter_original_utils.dart';
export 'src/web_view_delegate.dart' show WebViewDelegate;
export 'src/controller/controller.dart';

class HtmlWidget extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final bool adaptHeight; //高度自适应，高度自适应后不应该接受手势操作
  ///
  /// It is possible for other gesture recognizers to be competing with the player on pointer
  /// events, e.g if the player is inside a [ListView] the [ListView] will want to handle
  /// vertical drags. The player will claim gestures that are recognized by any of the
  /// recognizers on this list.
  ///
  /// By default vertical and horizontal gestures are absorbed by the player.
  /// Passing an empty set will ignore the defaults.
  ///
  /// This is ignored on web.
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final WebViewDelegate? delegate;

  const HtmlWidget(
      {Key? key,
      required this.url,
      this.adaptHeight = false,
      this.gestureRecognizers,
      this.width,
      this.height,
      this.delegate})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext buildContext, BoxConstraints constraints) {
      return WebViewXWidget(
        key: key,
        src: url,
        width: width ?? constraints.maxWidth,
        height: height ?? constraints.maxHeight,
        adaptHeight: adaptHeight,
        delegate: delegate,
        webSpecificParams: WebSpecificParams(),
        mobileSpecificParams: MobileSpecificParams(
          gestureNavigationEnabled: true,
          mobileGestureRecognizers: adaptHeight
              ? null
              : (Set()
                ..add(
                  Factory<VerticalDragGestureRecognizer>(
                    () => VerticalDragGestureRecognizer(),
                  ),
                )),
        ),
      );
    });
  }
}
