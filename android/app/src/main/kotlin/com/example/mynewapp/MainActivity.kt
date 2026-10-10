package com.example.mynewapp

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import com.example.mynewapp.widget.NextPrayerWidget
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The Flutter host. It also carries the `hadeeths/home_widget` channel: the app sends the widget's
 * snapshot, switches the widget on or off with the prayer section, and learns which page a tap on the
 * widget asked for.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var launchRoute: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        launchRoute = intent?.getStringExtra(EXTRA_ROUTE)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "update" -> {
                        NextPrayerWidget.save(this@MainActivity, call.arguments as? String)
                        result.success(null)
                    }
                    "clear" -> {
                        NextPrayerWidget.save(this@MainActivity, null)
                        result.success(null)
                    }
                    "setEnabled" -> {
                        setWidgetEnabled(call.arguments == true)
                        result.success(null)
                    }
                    "takeLaunchRoute" -> {
                        result.success(launchRoute)
                        launchRoute = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intent.getStringExtra(EXTRA_ROUTE)?.let { channel?.invokeMethod("openRoute", it) }
    }

    /** The widget is listed in the launcher only while the prayer section is on. */
    private fun setWidgetEnabled(enabled: Boolean) {
        packageManager.setComponentEnabledSetting(
            ComponentName(this, NextPrayerWidget::class.java),
            if (enabled) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            },
            PackageManager.DONT_KILL_APP,
        )
    }

    companion object {
        const val CHANNEL = "hadeeths/home_widget"
        const val EXTRA_ROUTE = "hadeeths.route"
        const val ROUTE_PRAYER = "prayer"
    }
}
