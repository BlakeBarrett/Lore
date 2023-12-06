package com.blakebarrett

data class User (
    val id: String,
    val displayName: String = "",
    val email: String = "",
    val creationDate: String = "",
    val JWT: String = ""
)

data class Comment(
    val commentId: String,
    val commenter: User,
    val remark: String,
    val creationDate: String,
    var flagged: Boolean = false)

data class Artifact(
    val md5sum: String,
    val comments: List<Comment>?
)
