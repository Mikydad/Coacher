package io.sidepal.app

import android.content.Intent
import android.os.Build
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(
            "NotifTap",
            "onNewIntent action=${intent.action} extras=${intent.extras}"
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Device model + OS version for feedback reports (see AppDelegate.swift
        // for why this is in-house instead of device_info_plus).
        // Stake reveal viewer (accountability PRD P-6): FLAG_SECURE while the
        // reveal route is on screen - screenshots and recents previews come
        // out black. Cleared when the route pops.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "sidepal/secure_screen"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSecure" -> {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                "disableSecure" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "sidepal/device_info"
        ).setMethodCallHandler { call, result ->
            if (call.method == "getDeviceInfo") {
                result.success(
                    mapOf(
                        "model" to "${Build.MANUFACTURER} ${Build.MODEL}",
                        "osVersion" to Build.VERSION.RELEASE
                    )
                )
            } else {
                result.notImplemented()
            }
        }
    }
}
