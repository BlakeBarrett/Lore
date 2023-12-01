import androidx.compose.desktop.ui.tooling.preview.Preview
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.Card
import androidx.compose.material.Icon
import androidx.compose.material.MaterialTheme
import androidx.compose.material.NavigationRail
import androidx.compose.material.Scaffold
import androidx.compose.material.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Search
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import com.blakebarrett.extensions.DropDataResult
import com.blakebarrett.extensions.md5sum
import com.blakebarrett.extensions.onFileDrop
import com.blakebarrett.extensions.onTextDrop

@Preview
@Composable
fun App() {
    MaterialTheme {
        var droppedDataResultList by remember { mutableStateOf<List<DropDataResult>?>(value = null) }
        Scaffold (modifier = Modifier
            .fillMaxSize()
            .onFileDrop(true) { list ->
                droppedDataResultList = list
            }
            .onTextDrop(true) { list ->
                droppedDataResultList = list
            }
        ) {
            Row(modifier = Modifier.fillMaxWidth()) {
                Column {
                    Icon(Icons.Default.AccountCircle, contentDescription = "Profile", modifier = Modifier.padding(16.dp))
                    Icon(Icons.Default.Search, contentDescription = "Search", modifier = Modifier.padding(16.dp))
                }
                NavigationRail(
                    modifier = Modifier.fillMaxWidth(),
                    content = {
                        droppedDataResultList?.let { items ->
                            DroppedItemFeed(items = items, modifier = Modifier.fillMaxSize())
                        }
                    }
                )
            }
        }
    }
}

@Composable
fun DroppedItemFeed(items: List<DropDataResult>, modifier: Modifier = Modifier) {
    items.forEach { item ->
        Column(modifier = modifier.background(Color.Magenta)) {
            Row {
                Text(text = item.md5sum)
            }
            Row(
                modifier = Modifier.fillMaxWidth(),
            ) {
                Card {
                    Text(text = item.droppedData.md5sum())
                }
            }
        }
    }
}

fun main() = application {
    Window(onCloseRequest = ::exitApplication, title = "Lore") {
        App()
    }
}
