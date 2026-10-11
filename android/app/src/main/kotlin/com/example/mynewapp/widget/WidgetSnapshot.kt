package com.example.mynewapp.widget

/**
 * What the app wrote for the widget (see lib/app/widget_snapshot.dart), read without any Android
 * class so it can be unit-tested on the JVM.
 *
 * Format: a header line, the heading ("Next prayer"), the label before the following one ("Then"),
 * then one line per time: UTC milliseconds, name and time as shown in the app, separated by tabs.
 */
data class PrayerTime(val atMillis: Long, val name: String, val time: String)

class WidgetSnapshot(
    val heading: String,
    val thenLabel: String,
    val times: List<PrayerTime>,
) {
    companion object {
        const val HEADER = "hadeeths-widget 1"

        /** Null for anything that is not a snapshot of this version. Bad lines are skipped. */
        fun parse(text: String?): WidgetSnapshot? {
            if (text == null) return null
            val lines = text.split('\n')
            if (lines.size < 3 || lines[0] != HEADER) return null
            val times = lines.drop(3).mapNotNull { line ->
                val parts = line.split('\t')
                val at = parts.getOrNull(0)?.toLongOrNull()
                if (parts.size != 3 || at == null) null else PrayerTime(at, parts[1], parts[2])
            }.sortedBy { it.atMillis }
            return WidgetSnapshot(lines[1], lines[2], times)
        }
    }
}

/** What the widget shows at a given moment. */
sealed class WidgetContent {
    /** The next time and the one after it; the widget must be redrawn at [refreshAtMillis]. */
    data class Next(
        val heading: String,
        val thenLabel: String,
        val next: PrayerTime,
        val then: PrayerTime?,
        val refreshAtMillis: Long,
    ) : WidgetContent()

    /** Nothing to show: no snapshot, or every time in it has passed. The app must be opened. */
    object OpenApp : WidgetContent()
}

object NextPrayerSelector {
    /**
     * The first time strictly after [nowMillis]: at the exact instant of a prayer, the next one is
     * the following (as on the app's Prayer page). A passed time is never shown as next.
     */
    fun select(snapshot: WidgetSnapshot?, nowMillis: Long): WidgetContent {
        if (snapshot == null) return WidgetContent.OpenApp
        val index = snapshot.times.indexOfFirst { it.atMillis > nowMillis }
        if (index < 0) return WidgetContent.OpenApp
        val next = snapshot.times[index]
        return WidgetContent.Next(
            heading = snapshot.heading,
            thenLabel = snapshot.thenLabel,
            next = next,
            then = snapshot.times.getOrNull(index + 1),
            refreshAtMillis = next.atMillis,
        )
    }
}
