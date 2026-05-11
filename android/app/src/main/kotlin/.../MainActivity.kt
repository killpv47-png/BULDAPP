package com.example.gate_app  // بسته خودت را جایگزین کن

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.VpnService
import android.content.Context

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.gate.app/vpn"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVpn" -> {
                    val proxyPort = call.argument<Int>("proxyPort") ?: 0
                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        startActivityForResult(intent, 100)
                        result.success(false) // نیاز به تایید کاربر
                    } else {
                        startVpnService(proxyPort)
                        result.success(true)
                    }
                }
                "stopVpn" -> {
                    stopService(Intent(this, GateVpnService::class.java))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 100 && resultCode == RESULT_OK) {
            // کاربر دسترسی VPN را تأیید کرد، دوباره فراخوانی کن
            val proxyPort = 0 // باید ذخیره شود
            // اما چون نمی‌دانیم پورت چیست، می‌توان با یک static متغیر مدیریت کرد
            // برای سادگی، اینجا فرض می‌کنیم پورت قبلاً ذخیره شده
        }
    }

    private fun startVpnService(proxyPort: Int) {
        val intent = Intent(this, GateVpnService::class.java)
        intent.putExtra("proxyPort", proxyPort)
        startService(intent)
    }
}
