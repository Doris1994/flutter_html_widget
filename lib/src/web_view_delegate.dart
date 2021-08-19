import 'controller/controller.dart';
import 'utils/webview_flutter_original_utils.dart';

class WebViewDelegate {
  void onWebViewCreated(HtmlController controller) {}

  bool shouldOverrideUrlLoading(String url) => true;

  void onPageStarted(String src) {}

  void onProgressChanged(int progress){}

  /// Callback for when the page has finished loading (i.e. is shown on screen).
  void onPageFinished(String src) {}

  /// Callback for when something goes wrong in while page or resources load.
  void onWebResourceError(WebResourceError error) {}

  String get customUserAgent => '';

  Map<String, String> get headers => const {};
}
