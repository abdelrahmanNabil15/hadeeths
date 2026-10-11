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
 * widget asked for. A second channel, `hadeeths/adhan_sound`, lists a downloaded adhan recording in
 * the shared notification sounds so a notification channel can play it (see [AdhanSounds]).
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
        val adhan = AdhanSounds(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ADHAN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> result.success(adhan.supported)
                "register" -> {
                    val path = call.argument<String>("path")
                    val name = call.argument<String>("name")
                    if (path == null || name == null) {
                        result.error("bad_arguments", "path and name are required", null)
                    } else {
                        result.success(adhan.register(path, name))
                    }
                }
                "unregister" -> {
                    call.argument<String>("name")?.let { adhan.unregister(it) }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
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
        const val ADHAN_CHANNEL = "hadeeths/adhan_sound"
        const val EXTRA_ROUTE = "hadeeths.route"
        const val ROUTE_PRAYER = "prayer"
    }
}
