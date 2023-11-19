package com.blakebarrett.extensions

import androidx.compose.runtime.Composable
import androidx.compose.ui.DragData
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.onExternalDrag

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun Modifier.onTextDrop(enabled: Boolean, onDrop: (result: List<DropDataResult>) -> Unit): Modifier {
    return this.onExternalDrag(
        enabled = enabled
    ) { externalDragValue ->
        (externalDragValue.dragData as? DragData.Text).also { text ->
            text?.let { onDrop(
                listOf( object : DropDataResult {
                    override val droppedData: String
                        get() = it.toString()
                })
            ) }
        }
    }
}
