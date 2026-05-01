package com.example.aicointrack

import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

class NotificationService : NotificationListenerService() {

    companion object {
        const val CHANNEL = "com.cointrack/notifications"
        const val PREFS_NAME = "NativePendingTransactions"
        const val PREFS_KEY = "pending_transactions"
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        android.util.Log.d("NotificationService", "Service connected successfully")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        android.util.Log.w("NotificationService", "Service disconnected")
        requestRebind(
            android.content.ComponentName(
                this,
                NotificationService::class.java,
            ),
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            val extras = sbn.notification.extras
            val title  = extras.getString("android.title") ?: ""
            val text   = extras.getCharSequence("android.text")?.toString() ?: ""
            val pkg    = sbn.packageName

            val watchedApps = setOf(
                "com.safaricom.mpesa",
                "com.kcbgroup.mobilebanking",
                "ke.co.equity.mobile",
                "com.ncba.ke.android",
                "com.google.android.gm",
            )

            val body = "$title $text"
            if (pkg !in watchedApps && !body.containsFinancialKeywords()) {
                android.util.Log.d("NotificationService", "Ignoring notification from $pkg: $body")
                return
            }

            android.util.Log.d("NotificationService", "Processing notification from $pkg title='$title'")
            val parsed = parseTransaction(title, text, pkg)
            if (parsed == null) {
                android.util.Log.d("NotificationService", "Notification did not match transaction patterns; nothing stored")
                return
            }

            writeToSharedPrefs(parsed)

            val channel = MainActivity.notifChannel
            android.util.Log.d("NotificationService", "notifChannelAvailable=${channel != null}")
            if (channel == null) {
                android.util.Log.d("NotificationService", "Flutter channel unavailable; native storage retained transaction")
                return
            }

            Handler(Looper.getMainLooper()).post {
                try {
                    channel.invokeMethod(
                        "onNotification",
                        mapOf("pkg" to pkg, "title" to title, "text" to text),
                    )
                    android.util.Log.d("NotificationService", "Successfully sent notification to Flutter")
                } catch (e: Exception) {
                    android.util.Log.e("NotificationService", "Failed to send notification to Flutter; native storage already contains transaction", e)
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("NotificationService", "Error processing notification", e)
        }
    }

    private fun parseTransaction(title: String, text: String, pkg: String): JSONObject? {
        val body = "$title $text"
        val lower = body.lowercase()

        val patterns = listOf(
            Regex("""received\s+Ksh\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE) to "income",
            Regex("""(?:sent|paid)\s+Ksh\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE) to "expense",
            Regex("""debited\s+(?:Ksh|KES)\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE) to "expense",
            Regex("""credited\s+(?:Ksh|KES)\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE) to "income",
            Regex("""(?:Ksh|KES)\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE) to null,
        )

        var amount: Double? = null
        var txType: String? = null

        for ((pattern, type) in patterns) {
            val match = pattern.find(body)
            if (match != null) {
                amount = match.groupValues[1].replace(",", "").toDoubleOrNull()
                txType = type
                android.util.Log.d("NotificationService", "Matched amount pattern='${pattern.pattern}' amount=$amount explicitType=$type")
                break
            }
        }

        if (amount == null || amount <= 0) {
            android.util.Log.d("NotificationService", "Failed to extract valid amount from body='$body'")
            return null
        }

        txType = txType ?: if (lower.contains("received") || lower.contains("credited")) {
            "income"
        } else {
            "expense"
        }

        val merchantRegex = Regex(
            """(?:to|from|at|by)\s+([A-Z][A-Za-z0-9\s&]{2,30}?)(?:\s+(?:Ksh|KES|on\s|Ref|via|\.)|$)""",
        )
        val description =
            merchantRegex.find(body)?.groupValues?.get(1)?.trim()
                ?: appName(pkg)
                ?: title

        android.util.Log.d("NotificationService", "Parsed tx type=$txType amount=$amount description='$description'")

        val now = System.currentTimeMillis()
        val minuteBucket = now / 60_000
        val hash = "${amount}_${txType}_${minuteBucket}".hashCode()

        return JSONObject().apply {
            put("id", "${hash}_${now}")
            put("amount", amount)
            put("type", txType)
            put("description", description)
            put("source", appName(pkg) ?: "Notification")
            put("category", if (txType == "income") "Income" else "General")
            put("detectedAt", java.time.Instant.ofEpochMilli(now).toString())
            put("rawText", body)
        }
    }

    private fun writeToSharedPrefs(tx: JSONObject) {
        try {
            val prefs = applicationContext.getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
            val existing = prefs.getString(PREFS_KEY, null)
            val list = try {
                if (existing != null && existing.trim().startsWith("[")) JSONArray(existing) else JSONArray()
            } catch (e: Exception) {
                android.util.Log.w("NotificationService", "Existing pending payload is not valid JSON array; resetting", e)
                JSONArray()
            }

            android.util.Log.d("NotificationService", "writeToSharedPrefs existingCount=${list.length()}")

            val newPrefix = tx.getString("id").split("_").first()
            for (i in 0 until list.length()) {
                val stored = JSONObject(list.getString(i))
                if (stored.getString("id").startsWith(newPrefix)) {
                    android.util.Log.d("NotificationService", "Skipping duplicate pending tx prefix=$newPrefix")
                    return
                }
            }

            list.put(tx.toString())
            val success = prefs.edit().putString(PREFS_KEY, list.toString()).commit()
            if (!success) {
                android.util.Log.e("NotificationService", "Failed to write transaction to SharedPreferences")
            } else {
                android.util.Log.d("NotificationService", "Stored pending tx id=${tx.optString("id")} newCount=${list.length()}")
            }
        } catch (e: Exception) {
            android.util.Log.e("NotificationService", "Error writing transaction to SharedPreferences", e)
        }
    }

    private fun String.containsFinancialKeywords(): Boolean {
        val lower = lowercase()
        return listOf(
            "ksh", "kes", "received", "sent", "debited",
            "credited", "payment", "transaction", "transferred",
        ).any { lower.contains(it) }
    }

    private fun appName(pkg: String): String? = mapOf(
        "com.safaricom.mpesa" to "M-Pesa",
        "com.kcbgroup.mobilebanking" to "KCB Bank",
        "ke.co.equity.mobile" to "Equity Bank",
        "com.ncba.ke.android" to "NCBA Bank",
        "com.google.android.gm" to "Gmail",
    )[pkg]
}
