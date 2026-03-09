package com.example.aicointrack

import android.content.Intent
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onNewIntent(intent: Intent) {
        setIntent(intent)
        super.onNewIntent(intent)

        val uri = intent.data
        Log.d("CoinbaseCallback", "onNewIntent fired. uri=$uri action=${intent.action}")

        if (uri != null && (uri.host == "cointrack-nu.vercel.app" || uri.scheme == "aicointrack")) {
            Log.d("CoinbaseCallback", "Caught return URL: $uri")
            onActivityResult(0, -1, intent)
        }
    }
}