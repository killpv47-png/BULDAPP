import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'proxy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保 Flutter 环境初始化
  runApp(const GateApp());
}

class GateApp extends StatelessWidget {
  const GateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue.shade200,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFE3F2FD),
        useMaterial3: true,
      ),
      home: const GateHome(),
    );
  }
}

class GateHome extends StatefulWidget {
  const GateHome({super.key});

  @override
  State<GateHome> createState() => _GateHomeState();
}

class _GateHomeState extends State<GateHome> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _scriptController = TextEditingController();
  InAppWebViewController? _webController;
  GoogleScriptProxy? _proxy;
  bool _googleMode = true;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedScript = prefs.getString('script_url');
    if (savedScript != null) {
      _scriptController.text = savedScript;
      _startProxy(savedScript);
    }
  }

  Future<void> _startProxy(String scriptUrl) async {
    _proxy?.stop();
    _proxy = GoogleScriptProxy(scriptUrl);
    await _proxy!.start();
    _applyProxySettings();
  }

  Future<void> _toggleGoogleMode(bool value) async {
    setState(() => _googleMode = value);
    _applyProxySettings();
    _reloadCurrentUrl();
  }

  // ----- 这里是用官方方法设置代理的地方 -----
  Future<void> _applyProxySettings() async {
    if (!mounted) return;

    // 检查平台是否支持该功能
    bool proxyAvailable = await WebViewFeature.isFeatureSupported(WebViewFeature.PROXY_OVERRIDE);
    if (!proxyAvailable) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('当前设备不支持代理设置')),
        );
      }
      return;
    }

    ProxyController proxyController = ProxyController.instance();
    
    if (_googleMode && _proxy != null) {
      // 启用代理：将所有流量定向到我们的本地代理服务器
      await proxyController.setProxyOverride(
        settings: ProxySettings(
          proxyRules: [
            ProxyRule(url: "127.0.0.1:${_proxy!.port}"),
          ],
        ),
      );
    } else {
      // 禁用代理：清除覆盖，使用系统默认设置
      await proxyController.clearProxyOverride();
    }
  }
  // ----- 修改结束 -----

  void _reloadCurrentUrl() {
    if (_currentUrl.isNotEmpty && _webController != null) {
      _webController!.loadUrl(urlRequest: URLRequest(url: WebUri(_currentUrl)));
    }
  }

  void _navigate(String url) {
    var uri = url;
    if (!uri.startsWith('http://') && !uri.startsWith('https://')) {
      uri = 'https://$url';
    }
    setState(() => _currentUrl = uri);
    _webController?.loadUrl(urlRequest: URLRequest(url: WebUri(uri)));
  }

  Future<void> _saveScript() async {
    final url = _scriptController.text.trim();
    if (url.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('script_url', url);
    await _startProxy(url);
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اسکریپت ذخیره و پروکسی فعال شد')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gate'),
        backgroundColor: Colors.lightBlue.shade300,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomPaint(
            painter: KavianiPainter(),
          ),
        ),
        actions: [
          // Google Mode 开关
          Switch(
            value: _googleMode,
            onChanged: _toggleGoogleMode,
            activeColor: Colors.white,
            inactiveThumbColor: Colors.grey,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'آدرس سایت را وارد کنید',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (value) => _navigate(value),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _navigate(_urlController.text),
                ),
              ],
            ),
          ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri('about:blank')),
              onWebViewCreated: (controller) {
                _webController = controller;
                _applyProxySettings();
              },
              onLoadStart: (controller, url) {
                setState(() => _currentUrl = url.toString());
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تنظیمات اسکریپت گوگل'),
        content: TextField(
          controller: _scriptController,
          decoration: const InputDecoration(
            hintText: 'شناسه Deployment اسکریپت را وارد کنید',
          ),
        ),
        actions: [
          TextButton(onPressed: _saveScript, child: const Text('ذخیره')),
        ],
      ),
    );
  }
}

// 波斯帝国旗标绘制器（保持不变）
class KavianiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFC62828);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    final goldPaint = Paint()..color = Colors.amber.shade700;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.4, 0, size.width * 0.2, size.height), goldPaint);
    final sunPaint = Paint()..color = Colors.yellow;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.15, sunPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
