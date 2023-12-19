package com.blakebarrett

import java.io.File

data class User (
    val id: String,
    val displayName: String = "",
    val email: String = "",
    val creationDate: String = "",
    val JWT_Token: String? = null
)

data class Comment(
    val commentId: String,
    val commenter: User,
    val remark: String,
    val creationDate: String,
    var flagged: Boolean = false)

data class Artifact(
    val md5sum: String,
    val name: String? = null,
    val file: File? = null,
    val comments: List<Comment>?
)
