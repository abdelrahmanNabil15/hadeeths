package com.example.mynewapp.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import com.example.mynewapp.MainActivity
import com.example.mynewapp.R

/**
 * Home-screen widget: the next prayer time and the one after it, from the snapshot the app wrote.
 * It never runs Dart and needs no permission. It redraws itself at each prayer time (exactly when
 * the user allowed exact alarms for reminders, otherwise when the system lets it), after a restart
 * and after a change of clock or time zone. Tapping it opens the app's Prayer section.
 */
class NextPrayerWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_REFRESH,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> render(context)
        }
    }

    override fun onDisabled(context: Context) {
        schedule(context, null)
    }

    companion object {
        const val ACTION_REFRESH = "com.hadeeths.widget.REFRESH"
        private const val PREFS = "hadeeths_widget"
        private const val KEY = "snapshot"

        /** Stores what the app sent (null forgets it) and redraws every widget. */
        fun save(context: Context, snapshot: String?) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            if (snapshot == null) prefs.remove(KEY) else prefs.putString(KEY, snapshot)
            prefs.apply()
            render(context, snapshot)
        }

        fun render(context: Context, snapshotText: String? = null) {
            val text = snapshotText
                ?: context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
            val content = NextPrayerSelector.select(
                WidgetSnapshot.parse(text),
                System.currentTimeMillis(),
            )
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, NextPrayerWidget::class.java))
            if (ids.isEmpty()) {
                schedule(context, null)
                return
            }
            manager.updateAppWidget(ids, views(context, content))
            schedule(context, (content as? WidgetContent.Next)?.refreshAtMillis)
        }

        private fun views(context: Context, content: WidgetContent): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_next_prayer)
            when (content) {
                is WidgetContent.Next -> {
                    views.setViewVisibility(R.id.widget_message, View.GONE)
                    views.setViewVisibility(R.id.widget_heading, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_next, View.VISIBLE)
                    views.setTextViewText(R.id.widget_heading, content.heading)
                    // Name and time in one text, so the reading order follows the language.
                    views.setTextViewText(
                        R.id.widget_next,
                        "${content.next.name}  ${content.next.time}",
                    )
                    val then = content.then
                    if (then == null) {
                        views.setViewVisibility(R.id.widget_then, View.GONE)
                    } else {
                        views.setViewVisibility(R.id.widget_then, View.VISIBLE)
                        views.setTextViewText(
                            R.id.widget_then,
                            "${content.thenLabel} ${then.name}  ${then.time}",
                        )
                    }
                }
                WidgetContent.OpenApp -> {
                    views.setViewVisibility(R.id.widget_heading, View.GONE)
                    views.setViewVisibility(R.id.widget_next, View.GONE)
                    views.setViewVisibility(R.id.widget_then, View.GONE)
                    views.setViewVisibility(R.id.widget_message, View.VISIBLE)
                }
            }
            views.setOnClickPendingIntent(R.id.widget_root, openPrayer(context))
            return views
        }

        private fun openPrayer(context: Context): PendingIntent {
            val intent = Intent(context, MainActivity::class.java)
                .putExtra(MainActivity.EXTRA_ROUTE, MainActivity.ROUTE_PRAYER)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            return PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }

        /** Redraw just after [atMillis]; null cancels. */
        private fun schedule(context: Context, atMillis: Long?) {
            val alarms = context.getSystemService(AlarmManager::class.java) ?: return
            val refresh = PendingIntent.getBroadcast(
                context,
                1,
                Intent(context, NextPrayerWidget::class.java).setAction(ACTION_REFRESH),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            alarms.cancel(refresh)
            if (atMillis == null) return
            val at = atMillis + 1_000
            val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()
            try {
                if (exact) {
                    alarms.setExactAndAllowWhileIdle(AlarmManager.RTC, at, refresh)
                } else {
                    window(alarms, at, refresh)
                }
            } catch (_: SecurityException) {
                window(alarms, at, refresh)
            }
        }

        /**
         * Without exact alarms: within ten minutes of the time (the shortest window the system grants)
         * rather than "some time in the next hour". Not an allow-while-idle alarm: the widget is only seen
         * with the screen on, which ends idle, and due alarms are then delivered.
         */
        private fun window(alarms: AlarmManager, at: Long, refresh: PendingIntent) {
            alarms.setWindow(AlarmManager.RTC, at, WINDOW_MILLIS, refresh)
        }

        private const val WINDOW_MILLIS = 10 * 60 * 1_000L
    }
}
