package com.blakebarrett.extensions

import java.io.File
import java.io.InputStream

fun InputStream.md5sum(): String = java.security.MessageDigest
    .getInstance("MD5")
    .digest(readBytes())
    .joinToString("") {
        "%02x".format(it)
    }

// Read the contents of a file and return the md5sum of the contents as a String
fun File.md5sum(): String? = this.takeIf { it.exists() }?.inputStream()?.use { stream ->
    return stream.md5sum()
}

fun String.md5sum(): String = this.byteInputStream().use { stream ->
    return stream.md5sum()
}
