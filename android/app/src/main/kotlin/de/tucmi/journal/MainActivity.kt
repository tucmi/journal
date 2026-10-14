package de.tucmi.journal

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Turns the `journal://record` link (sent by the home screen widget) into a
 * "start recording" request for the Dart side.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var recordPending = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        recordPending = consumeRecordRequest(intent)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeRecordRequest" -> {
                        result.success(recordPending)
                        recordPending = false
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (consumeRecordRequest(intent)) channel?.invokeMethod("recordRequested", null)
    }

    /** True if [intent] is the record link; clears it so a recreate does not repeat it. */
    private fun consumeRecordRequest(intent: Intent?): Boolean {
        val data = intent?.data ?: return false
        if (data.scheme != "journal" || data.host != "record") return false
        intent.data = null
        return true
    }

    companion object {
        const val CHANNEL = "de.tucmi.journal/launch"
    }
}
