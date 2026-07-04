package com.momento.momento

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.momento.momento.ui.theme.DeepPlum
import com.momento.momento.ui.theme.HuddlexTheme

/** Navigation routes — will mirror the Flutter AuthGate flow in Phase 1:
 *  unauthenticated → auth, unverified → verify, first-run → onboarding,
 *  else → home. */
object Routes {
    const val AUTH = "auth"
    const val HOME = "home"
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            HuddlexTheme {
                val nav = rememberNavController()
                NavHost(navController = nav, startDestination = Routes.AUTH) {
                    composable(Routes.AUTH) { PlaceholderScreen("Huddlex — native (Phase 0 scaffold)") }
                    composable(Routes.HOME) { PlaceholderScreen("Home") }
                }
            }
        }
    }
}

@Composable
private fun PlaceholderScreen(label: String) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(text = label, style = MaterialTheme.typography.titleLarge, color = DeepPlum)
    }
}
