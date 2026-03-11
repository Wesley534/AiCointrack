package com.example.aicointrack

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

/**
 * MainActivity — single entry point for the Flutter app on Android.
 *
 * Deep link callback handling for Coinbase Wallet SDK:
 *
 *   When the user approves the connection in Coinbase Wallet / Base Wallet app,
 *   Android fires an intent matching our `aicointrack://` scheme back at this
 *   activity. Because launchMode="singleTask" the activity is already running,
 *   so Android calls [onNewIntent] rather than [onCreate].
 *
 *   We must call [setIntent] with the new intent AND notify Flutter's engine
 *   so the coinbase_wallet_sdk plugin receives the callback URL and unblocks
 *   the pending [initiateHandshake] / [makeRequest] future.
 *
 *   Without setIntent + handleNewIntent, the Dart side hangs at Step 1 forever.
 */
class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // If the app was launched cold via a deep link (rare but possible),
        // the intent is already set — nothing extra needed here.
    }

    override fun onNewIntent(intent: Intent) {
        // 1. Update the activity's current intent so Flutter can read it.
        setIntent(intent)
        // 2. Forward to Flutter engine — this is what wakes up the Dart plugin.
        super.onNewIntent(intent)
    }
}