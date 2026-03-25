package com.example.aicointrack

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        // Held here so NotificationService can invoke methods back to Flutter
        // without needing FlutterEngineCache (which requires a pre-warmed engine).
        var notifChannel: MethodChannel? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Log the intent that started the activity (useful for debugging deep-links)
        try {
            val startIntent = intent
            Log.d("MainActivity", "configureFlutterEngine startIntent action=${startIntent?.action} data=${startIntent?.dataString}")
        } catch (e: Exception) {
            Log.w("MainActivity", "configureFlutterEngine: failed to read start intent: $e")
        }

        notifChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NotificationService.CHANNEL,
        )

        notifChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationAccessGranted" -> {
                    val cn = packageName + "/" + NotificationService::class.java.name
                    val flat = Settings.Secure.getString(
                        contentResolver,
                        "enabled_notification_listeners",
                    )
                    val granted = flat != null && flat.contains(cn)
                    android.util.Log.d("MainActivity", "Notification access granted: $granted")
                    result.success(granted)
                }
                "openNotificationSettings" -> {
                    android.util.Log.d("MainActivity", "Opening notification settings")
                    startActivity(
                        Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS"),
                    )
                    result.success(null)
                }
                "testNotificationService" -> {
                    android.util.Log.d("MainActivity", "Testing notification service")
                    result.success("Notification service test completed")
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val startIntent = intent
            Log.d("MainActivity", "onCreate intent action=${startIntent?.action} data=${startIntent?.dataString}")
        } catch (e: Exception) {
            Log.w("MainActivity", "onCreate: failed to read intent: $e")
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        try {
            Log.d(
                "MainActivity",
                "onNewIntent action=${intent.action} data=${intent.dataString}",
            )
            // Update the activity's intent so subsequent calls to getIntent() return the new one.
            setIntent(intent)
        } catch (e: Exception) {
            Log.w("MainActivity", "onNewIntent: failed to log new intent: $e")
        }
    }
}
