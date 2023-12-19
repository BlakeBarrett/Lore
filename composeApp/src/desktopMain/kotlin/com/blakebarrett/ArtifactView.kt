package com.blakebarrett

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.ExperimentalMaterialApi
import androidx.compose.material.Icon
import androidx.compose.material.ListItem
import androidx.compose.material.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Info
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import java.io.File
import java.nio.file.Files

@Composable
fun AssetIcon(item: File, modifier: Modifier) {
//    val icon = FileSystemView.getFileSystemView().getSystemIcon( item.file )
}

@OptIn(ExperimentalMaterialApi::class)
@Composable
fun ArtifactDetails(artifact: Artifact, modifier: Modifier) {
    Column {
        artifact.file?.let {file ->
            AssetIcon(file, modifier)
        }
        ListItem (
            modifier = Modifier.fillMaxWidth(),
            text = { Text(text = "${artifact.name}") },
            secondaryText = { Text(text = artifact.md5sum) },
            icon = { Icon(Icons.Default.Info, contentDescription = "${artifact.name}") },
        )
        artifact.file?.let {file ->
            Files.readAttributes(file.toPath(), "*").let { attributes ->
                attributes.keys.sorted().forEach { key ->
                    Text(text = "$key: ${attributes[key]}",
                        modifier = Modifier.padding(8.dp, 0.dp))
                }
            }
        }
        Spacer(modifier = Modifier.height(8.dp))
    }
}