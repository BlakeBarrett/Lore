import androidx.compose.desktop.ui.tooling.preview.Preview
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.onClick
import androidx.compose.material.Button
import androidx.compose.material.Card
import androidx.compose.material.DrawerState
import androidx.compose.material.DrawerValue
import androidx.compose.material.ExperimentalMaterialApi
import androidx.compose.material.Icon
import androidx.compose.material.ListItem
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Scaffold
import androidx.compose.material.ScaffoldState
import androidx.compose.material.SnackbarHostState
import androidx.compose.material.Text
import androidx.compose.material.TextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Send
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import androidx.compose.ui.window.rememberWindowState
import com.blakebarrett.Comment
import com.blakebarrett.Discourse
import com.blakebarrett.User
import com.blakebarrett.extensions.DropDataResult
import com.blakebarrett.extensions.onFileDrop
import com.blakebarrett.extensions.onTextDrop
import kotlinx.coroutines.launch
import java.nio.file.Files

fun main() = application {
    Window(onCloseRequest = ::exitApplication,
        title = "Lore",
        state = rememberWindowState(width = 600.dp, height = 1000.dp)
        ) {
        App()
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Preview
@Composable
fun App() {
    MaterialTheme {
        var droppedDataResultList by remember { mutableStateOf<List<DropDataResult>?>(value = null) }
        val scaffoldState by remember { mutableStateOf(
            ScaffoldState(
                drawerState = DrawerState(DrawerValue.Closed),
                snackbarHostState = SnackbarHostState()))}
        Scaffold (modifier = Modifier
            .fillMaxSize()
            .onFileDrop(true) { list -> droppedDataResultList = list }
            .onTextDrop(true) { list -> droppedDataResultList = list },
            drawerContent = {
                Column {
                    Icon(Icons.Default.AccountCircle, contentDescription = "Profile", modifier = Modifier.padding(16.dp))
                    Icon(Icons.Default.Search, contentDescription = "Search", modifier = Modifier.padding(16.dp))
                }
            },
            drawerShape = MaterialTheme.shapes.small,
        ) {
            val coroutineScope = rememberCoroutineScope()
            Column(modifier = Modifier
                .background(Color.Magenta)
                .onClick {
                    coroutineScope.launch {
                        toggleDrawerState(scaffoldState.drawerState)
//                        scaffoldState.snackbarHostState.showSnackbar("Hello there!")
                    }
                }
            ) {
                droppedDataResultList?.let { items ->
                    DroppedItemFeed(items = items)
                }
            }
        }
    }
}

suspend fun toggleDrawerState(drawerState: DrawerState) {
    if (drawerState.isOpen) {
        drawerState.open()
    } else {
        drawerState.close()
    }
}

@Composable
fun DroppedItemFeed(items: List<DropDataResult>? = null,
                    item: DropDataResult? = null,
                    modifier: Modifier = Modifier
                        .padding(16.dp)) {
    item?.let { DroppedItem(item = it, modifier = modifier) }
    items?.forEach { item -> DroppedItem(item = item, modifier = modifier) }
}

@OptIn(ExperimentalMaterialApi::class)
@Composable
fun DroppedItem(item: DropDataResult,
                currentUser: User = User(id = "1"),
                modifier: Modifier = Modifier) {
    var commentHistory by remember { mutableStateOf<List<Comment>>(
        listOf(Comment("1", User(id = "1"), "Hello World!", System.currentTimeMillis().toString()),
            Comment("2", User(id = "2"), "Hello World!", System.currentTimeMillis().toString()),
            Comment("3", User(id = "3"), "DICKSAUCE!", System.currentTimeMillis().toString(), true),
        )
    ) }
    Column {
        Card(modifier = modifier) {
            Column {
    //            val icon = FileSystemView.getFileSystemView().getSystemIcon( item.file )
                ListItem (
                    modifier = Modifier.fillMaxWidth(),
                    text = { Text(text = "${item.file?.name}") },
                    secondaryText = { Text(text = item.md5sum) },
                    icon = { Icon(Icons.Default.Info, contentDescription = "${item.file?.name}") },
                )
                item.file?.let {file ->
                    Files.readAttributes(file.toPath(), "*").let { attributes ->
                        attributes.keys.sorted().forEach { key ->
                            Text(text = "$key: ${attributes[key]}", modifier = Modifier.padding(8.dp, 0.dp))
                        }
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
            }
        }
        Discourse(
            modifier = Modifier.padding(8.dp),
            history = commentHistory)
    }
    Row(modifier = Modifier.fillMaxWidth()) {
        var commentText by remember { mutableStateOf("") }
        TextField(value = commentText,
            onValueChange = {
                commentText = it
            },
            modifier = Modifier.padding(start = 8.dp).weight(1f))
        Button(
            modifier = Modifier.padding(8.dp),
            onClick = {
                Comment(
                    commentText,
                    currentUser,
                    commentText,
                    System.currentTimeMillis().toString()).also { comment ->
                        postNewComment(comment)
                        commentHistory = commentHistory.plus(comment)
                }
                commentText = ""
        }) {
            Icon(Icons.Default.Send, contentDescription = "Post Comment")
        }
    }
}

fun postNewComment(comment: Comment) {
    // go tell the server about this comment
}
