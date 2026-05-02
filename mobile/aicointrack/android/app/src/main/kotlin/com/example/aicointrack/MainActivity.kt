package com.example.aicointrack

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

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
                "getPendingTransactions" -> {
                    try {
                        val prefs = getSharedPreferences(NotificationService.PREFS_NAME, MODE_PRIVATE)
                        val raw = prefs.getString(NotificationService.PREFS_KEY, null)
                        Log.d("MainActivity", "getPendingTransactions rawPresent=${raw != null} rawLength=${raw?.length ?: 0}")
                        if (raw == null) {
                            result.success(emptyList<String>())
                        } else {
                            val trimmed = raw.trim()
                            if (!trimmed.startsWith("[")) {
                                // Corrupt native pending payload; clear and continue.
                                Log.w("MainActivity", "getPendingTransactions found non-JSON payload for ${NotificationService.PREFS_KEY}; clearing value")
                                prefs.edit().remove(NotificationService.PREFS_KEY).apply()
                                result.success(emptyList<String>())
                                return@setMethodCallHandler
                            }

                            // Parse JSONArray to List<String>
                            val arr = org.json.JSONArray(trimmed)
                            val out = ArrayList<String>()
                            for (i in 0 until arr.length()) {
                                out.add(arr.getString(i))
                            }
                            Log.d("MainActivity", "getPendingTransactions parsed count=${out.size}")
                            // Clear after reading so Flutter becomes authoritative
                            prefs.edit().remove(NotificationService.PREFS_KEY).apply()
                            result.success(out)
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("MainActivity", "getPendingTransactions failed", e)
                        result.error("error", "Failed to read pending transactions", null)
                    }
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

    override fun onDestroy() {
        super.onDestroy()
        // Prevent NotificationService from attempting to use a stale channel when Flutter is detached.
        notifChannel = null
        Log.d("MainActivity", "onDestroy cleared notifChannel")
    }
}
