package com.money.findo

import com.money.findo.bankcapture.BankCapturePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        BankCapturePlugin.attach(flutterEngine.dartExecutor.binaryMessenger, applicationContext)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        BankCapturePlugin.detach()
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
