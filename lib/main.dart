import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() => runApp(const GateApp());

class GateApp extends StatelessWidget {
  const GateApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(home: const GateHome());
}

class GateHome extends StatefulWidget {
  const GateHome({super.key});
  @override
  State<GateHome> createState() => _GateHomeState();
}

class _GateHomeState extends State<GateHome> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/gmail.modify']
  );
  bool _isConnected = false;
  late WebViewController _webController;

  Future<void> _connect() async {
    try {
      await _googleSignIn.signIn();
      setState(() {
        _isConnected = true;
        _webController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse('https://www.google.com'));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطا: $e"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gate Browser")),
      body: _isConnected
          ? WebViewWidget(controller: _webController)
          : Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text("ورود با گوگل و فعال‌سازی تونل"),
                onPressed: _connect,
              ),
            ),
    );
  }
}
