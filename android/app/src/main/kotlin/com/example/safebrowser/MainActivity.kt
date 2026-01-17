package com.example.safebrowser

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app.channel.shared.data"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openDefaultBrowserSettings") {
                try {
                    val intent = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                } catch (e: Exception) {
                    try {
                        // Fallback for older Android versions
                        val intent = Intent(Settings.ACTION_SETTINGS)
                        startActivity(intent)
                        result.success(null)
                    } catch (ex: Exception) {
                        result.error("UNAVAILABLE", "Could not open settings", null)
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
