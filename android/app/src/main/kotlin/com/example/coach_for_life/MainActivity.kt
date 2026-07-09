package com.example.coach_for_life

import android.content.Intent
import android.os.Build
import android.util.Log
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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "pathpal/device_info"
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
