import androidx.compose.desktop.ui.tooling.preview.Preview
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material.Card
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import com.blakebarrett.extensions.DropDataResult
import com.blakebarrett.extensions.md5sum
import com.blakebarrett.extensions.onFileDrop
import com.blakebarrett.extensions.onTextDrop

@Composable
@Preview
fun App() {
    MaterialTheme {
        var droppedDataResultList by remember { mutableStateOf<List<DropDataResult>?>(value = null) }
        Column (modifier = Modifier
            .fillMaxSize()
            .onFileDrop(true) {
                droppedDataResultList = it
            }
            .onTextDrop(true) {
                droppedDataResultList = it
            },
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            droppedDataResultList?.let {
                DroppedItemFeed(items = it, modifier = Modifier.fillMaxWidth())
            }
//            repeat(droppedDataResultList?.size ?: 0) { index ->
//                droppedDataResultList?.get(index).let { dropData ->
//                    Row(
//                        modifier = Modifier
//                            .fillMaxWidth()
//                            .background(when (dropData) {
//                                null -> Color.Transparent
//                                else -> Color.Magenta
//                            }),
//                        verticalAlignment = Alignment.CenterVertically
//                    ) {
//                        Card {
//                            Text (text = "MD5Sum: ${dropData?.md5sum ?: "null"}")
//                        }
//                    }
//                }
//            }
        }
    }
}

@Composable
fun DroppedItemFeed(items: List<DropDataResult>, modifier: Modifier = Modifier) {
    Column(modifier = modifier) {
        items.forEach { item ->
            Row(
                modifier = Modifier.fillMaxWidth().background(Color.Magenta),
            ) {
                Card {
                    Text(text = item.droppedData.md5sum())
                }
            }
        }
    }
}

fun main() = application {
    Window(onCloseRequest = ::exitApplication) {
        App()
    }
}
