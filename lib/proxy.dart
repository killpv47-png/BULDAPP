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
      var body = await request.transform(utf8.decoder).join();

      var response = await http.post(
        Uri.parse(scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'url': request.uri.toString(),
          'method': request.method,
          'headers': Map<String, String>.from(request.headers),
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
