package com.momento.momento.ui.home

import androidx.annotation.StringRes
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.MeetingRoom
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.MeetingRoom
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.momento.momento.R
import com.momento.momento.ui.theme.DeepPlum

private data class HomeTab(
    @StringRes val labelRes: Int,
    val icon: ImageVector,
    val selectedIcon: ImageVector,
)

private val HomeTabs = listOf(
    HomeTab(R.string.home_feed, Icons.Outlined.Home, Icons.Filled.Home),
    HomeTab(R.string.home_rooms, Icons.Outlined.MeetingRoom, Icons.Filled.MeetingRoom),
    HomeTab(R.string.home_account, Icons.Outlined.Person, Icons.Filled.Person),
)

/**
 * Bottom-nav shell — port of the Dart `HomeScreen`
 * (lib/screens/home/home_screen.dart): Feed / Communities / Account tabs.
 * Rooms (Phase 5) and Account (Phase 6) are placeholders until their phases
 * land.
 *
 * Tab state is preserved across switches: the selected index survives process
 * recreation via rememberSaveable, and each tab's saveable state (feed pager
 * position etc.) is parked in a SaveableStateHolder while the tab is hidden.
 * The FeedViewModel is Activity-scoped, so the feed's subscriptions and data
 * also survive tab switches.
 */
@Composable
fun HomeScreen(uid: String) {
    var selectedTab by rememberSaveable { mutableIntStateOf(0) }
    val saveableStateHolder = rememberSaveableStateHolder()

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        // The inner tab content (e.g. FeedScreen's own Scaffold/app bar)
        // handles the status-bar inset itself; consuming it here too would
        // double the top spacing.
        contentWindowInsets = WindowInsets(0.dp),
        bottomBar = {
            NavigationBar {
                HomeTabs.forEachIndexed { index, tab ->
                    val selected = selectedTab == index
                    NavigationBarItem(
                        selected = selected,
                        onClick = { selectedTab = index },
                        icon = {
                            Icon(
                                imageVector = if (selected) tab.selectedIcon else tab.icon,
                                contentDescription = null,
                            )
                        },
                        label = { Text(stringResource(tab.labelRes)) },
                    )
                }
            }
        },
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
        ) {
            when (selectedTab) {
                0 -> saveableStateHolder.SaveableStateProvider("home_tab_feed") {
                    FeedScreen(uid = uid)
                }
                // Phase 5: RoomsScreen replaces this placeholder.
                1 -> saveableStateHolder.SaveableStateProvider("home_tab_rooms") {
                    PlaceholderTab("Communities — coming in Phase 5")
                }
                // Phase 6: AccountScreen replaces this placeholder.
                2 -> saveableStateHolder.SaveableStateProvider("home_tab_account") {
                    PlaceholderTab("Account — coming in Phase 6")
                }
            }
        }
    }
}

@Composable
private fun PlaceholderTab(label: String) {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Text(text = label, style = MaterialTheme.typography.titleLarge, color = DeepPlum)
    }
}
