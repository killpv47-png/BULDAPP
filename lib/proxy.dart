import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleScriptProxy {
  final String scriptUrl;
  HttpServer? _server;
  int? port;

  GoogleScriptProxy(this.scriptUrl);

  Future<int> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    port = _server!.port;
    _server!.listen(_handleRequest);
    return port!;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      // ----- 这里是修改的地方 -----
      // 将 Stream 先转换为 List<int>，再 decode，解决了 Utf8Decoder 类型错误
      final bodyBytes = await request.fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
      final body = utf8.decode(bodyBytes);
      
      // 手动构建一个 Map<String, String> 来兼容类型检查
      final headersMap = <String, String>{};
      request.headers.forEach((name, values) {
        headersMap[name] = values.join(', ');
      });
      // ----- 修改结束 -----

      var response = await http.post(
        Uri.parse(scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'url': request.uri.toString(),
          'method': request.method,
          'headers': headersMap,
          'body': body,
        }),
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        request.response.statusCode = jsonData['status'] ?? 200;
        var respHeaders = jsonDecode(jsonData['headers'] ?? '{}');
        respHeaders.forEach((k, v) {
          request.response.headers.set(k, v);
        });
        request.response.write(jsonData['body'] ?? '');
      } else {
        request.response.statusCode = 502;
        request.response.write('Error fetching page');
      }
    } catch (e) {
      request.response.statusCode = 500;
      request.response.write('Proxy error: $e');
    } finally {
      await request.response.close();
    }
  }

  void stop() => _server?.close();
}
