package com.example.aicointrack

import android.content.ContentResolver
import android.database.Cursor
import android.os.Handler
import android.os.Looper
import android.provider.Telephony
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

class NotificationService : NotificationListenerService() {

    companion object {
        const val CHANNEL = "com.cointrack/notifications"
        const val PREFS_NAME = "NativePendingTransactions"
        const val PREFS_KEY = "pending_transactions"

        val WATCHED_APPS = mapOf(
            "com.safaricom.mpesa" to "M-Pesa",
            "com.kcbgroup.mobilebanking" to "KCB Bank",
            "ke.co.equity.mobile" to "Equity Bank",
            "com.ncba.ke.android" to "NCBA Bank",
            "com.google.android.gm" to "Gmail",
        )

        val SMS_SENDERS = listOf(
            "MPESA", "M-PESA", "SAFARICOM", "KCB", "EQUITY", "NCBA",
            "CO-OP", "COOPERATIVE", "STANDARD CHARTERED",
            "ABSABANK", "DTB", "I&M",
        )

        // ── Historical SMS Scanner ──────────────────────────────────────────
        // Returns ALL financial SMS as raw data (body + sender).
        // Parsing happens on the Dart side which has the latest patterns.
        fun scanHistoricalMessages(
            contentResolver: ContentResolver,
            durationDays: Int,
        ): JSONArray {
            val results = JSONArray()

            try {
                val uri = Telephony.Sms.Inbox.CONTENT_URI
                val cutoff = System.currentTimeMillis() - (durationDays * 24L * 60L * 60L * 1000L)
                val cursor: Cursor? = contentResolver.query(
                    uri,
                    arrayOf("body", "address", "date"),
                    "date > ?",
                    arrayOf(cutoff.toString()),
                    "date DESC",
                )

                if (cursor == null) {
                    android.util.Log.w("NotificationService", "SMS cursor is null")
                    return results
                }

                var scannedCount = 0

                while (cursor.moveToNext()) {
                    val body = cursor.getString(cursor.getColumnIndexOrThrow("body")) ?: ""
                    val address = cursor.getString(cursor.getColumnIndexOrThrow("address")) ?: ""
                    val senderUpper = address.uppercase()

                    // Check if this looks like a financial SMS
                    val isFinancialSender = SMS_SENDERS.any { senderUpper.contains(it) }

                    if (!isFinancialSender) continue
                    scannedCount++

                    // Return raw data — Dart side does the parsing
                    val entry = JSONObject().apply {
                        put("body", body)
                        put("sender", address)
                    }
                    results.put(entry)
                }
                cursor.close()
                android.util.Log.d("NotificationService", "Historical scan: $scannedCount financial SMS found")
            } catch (e: Exception) {
                android.util.Log.e("NotificationService", "Historical scan error", e)
            }
            return results
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        android.util.Log.d("NotificationService", "Connected")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        requestRebind(android.content.ComponentName(this, NotificationService::class.java))
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            val extras = sbn.notification.extras
            val title = extras.getString("android.title") ?: ""
            val text = extras.getCharSequence("android.text")?.toString() ?: ""
            val pkg = sbn.packageName

            if (pkg !in WATCHED_APPS.keys && !containsFinancialContent("$title $text")) return

            val parsed = parseTransaction(title, text, pkg)
            if (parsed == null) return

            writeToSharedPrefs(parsed)

            val channel = MainActivity.notifChannel
            if (channel == null) return

            Handler(Looper.getMainLooper()).post {
                try {
                    channel.invokeMethod("onNotification", mapOf("pkg" to pkg, "title" to title, "text" to text))
                } catch (_: Exception) {}
            }
        } catch (_: Exception) {}
    }

    private fun parseTransaction(title: String, text: String, pkg: String): JSONObject? {
        val body = "$title $text".trim()
        if (body.isEmpty()) return null
        val lower = body.lowercase()

        // Transaction code detection
        var txCode = ""
        val txCodeRegex = Regex(
            """(?:transaction|txn|ref|reference|ID)\s*(?::|no|number)?\s*([A-Z0-9]{6,12})""",
            RegexOption.IGNORE_CASE,
        )
        val txCodeMatch = txCodeRegex.find(body)
        if (txCodeMatch != null) {
            txCode = txCodeMatch.groupValues[1]
        }
        if (txCode.isEmpty()) {
            val standaloneRegex = Regex("""^([A-Z0-9]{6,10})\s+(?:confirmed|is\s+your)""", RegexOption.IGNORE_CASE)
            val saMatch = standaloneRegex.find(body)
            if (saMatch != null) txCode = saMatch.groupValues[1]
        }

        // Patterns
        data class PatternEntry(val regex: Regex, val type: String?, val counterpartyGroup: Int = 0)

        val patterns = listOf(
            PatternEntry(
                Regex(
                    """(?:receive|received|you\s+have\s+received)\s+(?:Ksh|KES)\s*([\d,]+\.?\d*)\s*(?:from)\s+([A-Za-z][A-Za-z\s]{1,30}?)(?:\s+on|\s+at|\.|,|!|$)""",
                    setOf(RegexOption.IGNORE_CASE, RegexOption.DOT_MATCHES_ALL),
                ), "income", 2,
            ),
            PatternEntry(
                Regex(
                    """(?:send|sent|you\s+have\s+sent|paid)\s+(?:Ksh|KES)\s*([\d,]+\.?\d*)\s*(?:to)\s+([A-Za-z][A-Za-z\s]{1,30}?)(?:\s+on|\s+at|\.|,|!|$)""",
                    setOf(RegexOption.IGNORE_CASE, RegexOption.DOT_MATCHES_ALL),
                ), "expense", 2,
            ),
            PatternEntry(Regex("""(?:receive|received)\s+(?:Ksh|KES)\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE), "income"),
            PatternEntry(Regex("""(?:send|sent|paid)\s+(?:Ksh|KES)\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE), "expense"),
            PatternEntry(Regex("""(?:credited|deposited)\s+(?:with\s+)?(?:Ksh|KES)\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE), "income"),
            PatternEntry(Regex("""(?:debited|withdrawn|charged)\s+(?:with\s+)?(?:Ksh|KES)\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE), "expense"),
        )

        var amount: Double? = null
        var txType: String? = null
        var counterparty: String? = null

        for (pattern in patterns) {
            val match = pattern.regex.find(body)
            if (match != null) {
                val amountStr = match.groupValues[1].replace(",", "")
                amount = amountStr.toDoubleOrNull()
                txType = pattern.type
                if (pattern.counterpartyGroup > 0 && match.groupValues.size > pattern.counterpartyGroup) {
                    counterparty = match.groupValues[pattern.counterpartyGroup].trim()
                }
                break
            }
        }

        // Fallback to generic amount
        if (amount == null) {
            val genericRegex = Regex("""(?:Ksh|KES)\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE)
            val match = genericRegex.find(body)
            if (match != null) {
                val amountStr = match.groupValues[1].replace(",", "")
                amount = amountStr.toDoubleOrNull()
            }
        }

        if (amount == null || amount <= 0) return null

        txType = txType ?: if (lower.contains("receive") || lower.contains("credited") || lower.contains("deposited")) "income" else "expense"

        val description = if (!counterparty.isNullOrBlank()) counterparty!!
        else {
            val cpRegex = Regex(
                """(?:to|from|at|by|via)\s+([A-Za-z][A-Za-z0-9\s&.'-]{2,40}?)(?:\s+(?:Ksh|KES|on\s|Ref|reference|ID|transaction|\.|,|!)|$)""",
                setOf(RegexOption.IGNORE_CASE, RegexOption.DOT_MATCHES_ALL),
            )
            val cpMatch = cpRegex.find(body)
            if (cpMatch != null) cpMatch.groupValues[1].trim()
            else WATCHED_APPS[pkg] ?: title.ifBlank { "M-PESA Tx $txCode" }
        }

        val now = System.currentTimeMillis()
        val hashStr = "${amount}_${txType}_${txCode}_${now / 60000}"
        val hash = hashStr.hashCode()

        return JSONObject().apply {
            put("id", "${hash}_${now}")
            put("amount", amount)
            put("type", txType)
            put("description", description)
            put("source", WATCHED_APPS[pkg] ?: "Notification")
            put("category", if (txType == "income") "Income" else "General")
            put("detectedAt", java.time.Instant.ofEpochMilli(now).toString())
            put("rawText", body)
            put("transactionCode", txCode)
        }
    }

    private fun containsFinancialContent(body: String): Boolean {
        val lower = body.lowercase()
        val hasKeyword = listOf(
            "received", "receive", "sent", "send", "paid",
            "debited", "credited", "deposited", "withdrawn",
            "transaction", "transferred", "payment",
            "purchase", "withdrawal", "charge", "balance",
        ).any { lower.contains(it) }
        val hasMoney = listOf("ksh", "kes", "k.sh", "k.shs", "shillings").any { lower.contains(it) }
        return hasKeyword && hasMoney
    }

    private fun writeToSharedPrefs(tx: JSONObject) {
        try {
            val prefs = applicationContext.getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
            val existing = prefs.getString(PREFS_KEY, null)
            val list = try {
                if (existing != null && existing.trim().startsWith("[")) JSONArray(existing)
                else JSONArray()
            } catch (_: Exception) { JSONArray() }

            val newPrefix = tx.getString("id").split("_").first()
            for (i in 0 until list.length()) {
                val stored = JSONObject(list.getString(i))
                if (stored.getString("id").startsWith(newPrefix)) return
            }

            list.put(tx.toString())
            prefs.edit().putString(PREFS_KEY, list.toString()).commit()
        } catch (_: Exception) {}
    }
}
