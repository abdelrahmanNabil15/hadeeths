package com.example.mynewapp

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import java.io.File

/**
 * Lists a downloaded adhan recording in the phone's shared "Notifications" sounds, so that a
 * notification channel can play it. A file in the app's private folder cannot be read by the system's
 * notification service; a media-store entry created by the app can, and the app needs no storage
 * permission to create or find its own entries (Android 10 and later).
 */
class AdhanSounds(private val context: Context) {
    val supported: Boolean
        get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

    private val collection: Uri
        get() = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)

    /** The address of the sound called [name], listing the file at [path] first if it is not yet listed. */
    fun register(path: String, name: String): String? {
        if (!supported) return null
        find(name)?.let { return it.toString() }
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, "$name.mp3")
            put(MediaStore.Audio.Media.TITLE, name)
            put(MediaStore.Audio.Media.MIME_TYPE, "audio/mpeg")
            put(MediaStore.Audio.Media.RELATIVE_PATH, RELATIVE_PATH)
            put(MediaStore.Audio.Media.IS_NOTIFICATION, 1)
            put(MediaStore.Audio.Media.IS_PENDING, 1)
        }
        val uri = resolver.insert(collection, values) ?: return null
        try {
            val out = resolver.openOutputStream(uri) ?: throw java.io.IOException("no output stream")
            out.use { stream -> File(path).inputStream().use { it.copyTo(stream) } }
            values.clear()
            values.put(MediaStore.Audio.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        } catch (error: Exception) {
            resolver.delete(uri, null, null)
            return null
        }
        return uri.toString()
    }

    /** Removes the sound called [name] from the shared list. */
    fun unregister(name: String) {
        if (!supported) return
        context.contentResolver.delete(collection, SELECTION, arrayOf("$name.mp3", "$RELATIVE_PATH/"))
    }

    private fun find(name: String): Uri? {
        context.contentResolver.query(
            collection,
            arrayOf(MediaStore.Audio.Media._ID),
            SELECTION,
            arrayOf("$name.mp3", "$RELATIVE_PATH/"),
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) return ContentUris.withAppendedId(collection, cursor.getLong(0))
        }
        return null
    }

    private companion object {
        const val RELATIVE_PATH = "Notifications/Sakina"
        const val SELECTION =
            "${MediaStore.Audio.Media.DISPLAY_NAME}=? AND ${MediaStore.Audio.Media.RELATIVE_PATH}=?"
    }
}
