/// HTML utils: wrappers, parsers, splitters etc.
class HtmlUtils {
  /// Builds a js function using the name and params passed to it.
  ///
  /// Example call: buildJsFunction('say', ["hello", "world"]);
  /// Result: say('hello', 'world')
  static String buildJsFunction(String name, List<dynamic> params) {
    var args = '';
    if (params.isEmpty) {
      return name + '()';
    }
    params.forEach((param) {
      args += addSingleQuotes(param.toString());
      args += ',';
    });
    args = args.substring(0, args.length - 1);
    var function = name + '(' + '$args' + ')';

    return function;
  }

  /// Adds single quotes to the param
  static String addSingleQuotes(String data) {
    return "'$data'";
  }

  /// Removes surrounding quotes around a string, if any
  static String unQuoteJsResponseIfNeeded(String rawJsResponse) {
    if ((rawJsResponse.startsWith('\"') && rawJsResponse.endsWith('\"')) ||
        (rawJsResponse.startsWith('\'') && rawJsResponse.endsWith('\''))) {
      return rawJsResponse.substring(1, rawJsResponse.length - 1);
    }
    return rawJsResponse;
  }
}
