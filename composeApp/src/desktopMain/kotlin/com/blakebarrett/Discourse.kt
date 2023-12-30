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


@OptIn(ExperimentalMaterialApi::class)
@Composable
fun Discourse(artifact: Artifact, modifier: Modifier = Modifier) {
    artifact.comments?.let { comments ->
        LazyColumn {
            items(items = comments, key = { it.commentId }) { comment ->
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
}