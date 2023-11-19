package com.blakebarrett.extensions

import androidx.compose.runtime.Composable
import androidx.compose.ui.DragData
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.onExternalDrag
import java.io.File

interface DropDataResult {
    val droppedData: String
    val file: File? get() = File(droppedData.replaceFirst("file:", "")).takeIf { it.exists() }
    val md5sum: String get() = file?.md5sum() ?: droppedData.md5sum()
}

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun Modifier.onFileDrop(enabled: Boolean, onDrop: (result: List<DropDataResult>) -> Unit): Modifier {
    return this.onExternalDrag(
        enabled = enabled
    ) { externalDragValue ->
        val result = ArrayList<DropDataResult>()
        (externalDragValue.dragData as? DragData.FilesList).also { filesList ->
            filesList?.let { list ->
                result.addAll( list.readFiles().map { object : DropDataResult {
                    override val droppedData: String
                        get() = it
                }})
            }
        }
        onDrop(result)
    }
}
