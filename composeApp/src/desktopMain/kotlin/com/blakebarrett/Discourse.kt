package com.blakebarrett

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.Card
import androidx.compose.material.ExperimentalMaterialApi
import androidx.compose.material.Icon
import androidx.compose.material.ListItem
import androidx.compose.material.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Person
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

data class User (
    val id: String,
    val displayName: String = "",
    val email: String = "",
    val creationDate: String = "",
)

data class Comment(
    val commentId: String,
    val commenter: User,
    val remark: String,
    val creationDate: String,
    var flagged: Boolean = false)

@OptIn(ExperimentalMaterialApi::class)
@Composable
fun Discourse(history: List<Comment>, modifier: Modifier = Modifier) {
    LazyColumn {
        items(history, key = { it.commentId }) {comment ->
            if (comment.flagged) {
                Spacer(modifier = Modifier.height(0.dp))
                return@items
            }
            Card (modifier = modifier.padding(8.dp)) {
                ListItem (
                    modifier = Modifier.fillMaxWidth(),
                    text = { Text(text = "${comment.remark}") },
                    secondaryText = { Text(text = comment.creationDate) },
                    icon = { Icon(Icons.Default.Person, contentDescription = "${comment.commenter.displayName}") },
                )
            }
        }
    }
}