package com.example.mynewapp.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetSnapshotTest {
    private val text = listOf(
        WidgetSnapshot.HEADER,
        "Next prayer",
        "Then",
        "3000\tDhuhr\t12:43 PM",
        "1000\tFajr\t5:27 AM",
        "2000\tSunrise\t6:53 AM",
    ).joinToString("\n")

    @Test
    fun readsAndSortsTheTimes() {
        val snapshot = WidgetSnapshot.parse(text)!!
        assertEquals("Next prayer", snapshot.heading)
        assertEquals("Then", snapshot.thenLabel)
        assertEquals(listOf(1000L, 2000L, 3000L), snapshot.times.map { it.atMillis })
        assertEquals("Fajr", snapshot.times.first().name)
    }

    @Test
    fun refusesAnythingElse() {
        assertNull(WidgetSnapshot.parse(null))
        assertNull(WidgetSnapshot.parse(""))
        assertNull(WidgetSnapshot.parse("hadeeths-widget 2\na\nb"))
        assertNull(WidgetSnapshot.parse("{\"json\": true}"))
    }

    @Test
    fun skipsDamagedLines() {
        val snapshot = WidgetSnapshot.parse(
            listOf(WidgetSnapshot.HEADER, "h", "t", "x\tA\t1", "5\tB", "7\tC\t3").joinToString("\n"),
        )!!
        assertEquals(listOf("C"), snapshot.times.map { it.name })
    }

    @Test
    fun theNextTimeIsTheFirstStillToCome() {
        val content = NextPrayerSelector.select(WidgetSnapshot.parse(text), 1500)
        assertTrue(content is WidgetContent.Next)
        content as WidgetContent.Next
        assertEquals("Sunrise", content.next.name)
        assertEquals("Dhuhr", content.then?.name)
        assertEquals(2000L, content.refreshAtMillis)
    }

    @Test
    fun atTheExactTimeTheFollowingOneIsNext() {
        val content = NextPrayerSelector.select(WidgetSnapshot.parse(text), 2000) as WidgetContent.Next
        assertEquals("Dhuhr", content.next.name)
        assertNull(content.then)
    }

    @Test
    fun aPassedTimeIsNeverShownAsNext() {
        assertSame(WidgetContent.OpenApp, NextPrayerSelector.select(WidgetSnapshot.parse(text), 3000))
        assertSame(WidgetContent.OpenApp, NextPrayerSelector.select(null, 0))
    }
}
