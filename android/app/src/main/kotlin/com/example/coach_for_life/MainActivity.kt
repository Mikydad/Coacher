package com.example.coach_for_life

import android.content.Intent
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(
            "NotifTap",
            "onNewIntent action=${intent.action} extras=${intent.extras}"
        )
    }
}
