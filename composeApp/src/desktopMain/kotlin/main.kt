
import androidx.compose.desktop.ui.tooling.preview.Preview
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.onClick
import androidx.compose.material.Button
import androidx.compose.material.Card
import androidx.compose.material.DrawerState
import androidx.compose.material.DrawerValue
import androidx.compose.material.ExperimentalMaterialApi
import androidx.compose.material.Icon
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Scaffold
import androidx.compose.material.ScaffoldState
import androidx.compose.material.SnackbarHostState
import androidx.compose.material.Text
import androidx.compose.material.TextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Close
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
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import androidx.compose.ui.window.rememberWindowState
import com.blakebarrett.Artifact
import com.blakebarrett.ArtifactDetails
import com.blakebarrett.Comment
import com.blakebarrett.Discourse
import com.blakebarrett.User
import com.blakebarrett.extensions.DropDataResult
import com.blakebarrett.extensions.onFileDrop
import com.blakebarrett.extensions.onTextDrop
import kotlinx.coroutines.launch

fun main() = application {
    Window(onCloseRequest = ::exitApplication,
        title = "Lore",
        state = rememberWindowState(width = 600.dp, height = 700.dp)
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
            bottomBar = {
                val signedInUser: User?
                signedInUser = User(id = "1")
                signedInUser.let {
                    CommentArea(modifier = Modifier.padding(0.dp).fillMaxWidth(), it) { comment, user ->
                        postNewComment(comment, user)
                    }
                }
            },
        ) {
            val coroutineScope = rememberCoroutineScope()
            Column(modifier = Modifier
                .background(Color.Magenta)
                .fillMaxSize()
                .onClick {
                    coroutineScope.launch {
                        toggleDrawerState(scaffoldState.drawerState)
//                        scaffoldState.snackbarHostState.showSnackbar("Hello there!")
                    }
                }
            ) {
                droppedDataResultList?.let { items ->
                    DroppedItemFeed(items)
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
fun DroppedItemFeed(list: List<DropDataResult>,
                    modifier: Modifier = Modifier
                        .padding(16.dp)) {
    Column {
        var selectedTab by remember { mutableStateOf(0) }
        var tabs by remember { mutableStateOf(list) }
        var selectedItem by mutableStateOf( tabs.get(selectedTab) )
        if (tabs.size > 1) {
            LazyRow (modifier = Modifier.fillMaxWidth()) {
                items(tabs, key = { it.md5sum }) { dropDataResult ->
                    Button(
                        modifier = Modifier.padding(8.dp),
                        onClick = {
                            selectedTab = list.indexOf(dropDataResult)
                        }) {
                        Text(
                            text = "${dropDataResult.file?.name}",
                            style = if (selectedTab == list.indexOf(dropDataResult)) MaterialTheme.typography.button else MaterialTheme.typography.caption,
                            textDecoration = if (selectedTab == list.indexOf(dropDataResult)) TextDecoration.Underline else TextDecoration.None)
                        Button(
                            modifier = Modifier.padding(8.dp, 2.dp, 2.dp, 2.dp),
                            onClick = {
                                tabs = tabs.filterIndexed({ index, dropDataResult -> index != selectedTab })
                                selectedTab = 0
                                selectedItem = tabs.get(selectedTab)
                            }) {
                            Icon(Icons.Default.Close, contentDescription = "Close")
                        }
                    }
                }
            }
        }
        DroppedItem(item = selectedItem, modifier = modifier)
    }
}

@OptIn(ExperimentalMaterialApi::class)
@Composable
fun DroppedItem(item: DropDataResult,
                currentUser: User = User(id = "1"),
                modifier: Modifier = Modifier) {
    var commentHistory by remember { mutableStateOf(listOf(Comment("1", currentUser, "Hello World!", System.currentTimeMillis().toString()),
            Comment("2", User(id = "2"), "Hello World!", System.currentTimeMillis().toString()),
            Comment("3", User(id = "3"), "DICKSAUCE!", System.currentTimeMillis().toString(), true),
        ))}
    var artifact by remember { mutableStateOf(
        Artifact(
            md5sum = item.md5sum,
            comments = commentHistory,
            file = item.file,
            name = item.file?.name) ) }
    Column {
        Card(modifier = modifier) {
            ArtifactDetails(
                artifact,
                modifier
            )
        }
        Discourse(
            modifier = Modifier.padding(8.dp).weight(1f),
            artifact = artifact)
    }
}

@Composable
fun CommentArea(modifier: Modifier = Modifier, user: User, onSubmit: (comment: Comment, loggedInUser: User) -> Unit) {
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
                    user,
                    commentText,
                    System.currentTimeMillis().toString()).also { comment ->
                    onSubmit(comment, user)
                }
                commentText = ""
            }) {
            Icon(Icons.Default.Send, contentDescription = "Post Comment")
        }
    }
}

fun postNewComment(comment: Comment, user: User) {
    // go tell it on the server
}