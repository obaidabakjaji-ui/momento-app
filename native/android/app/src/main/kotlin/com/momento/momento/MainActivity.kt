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
import com.momento.momento.ui.AuthGate
import com.momento.momento.ui.theme.DeepPlum
import com.momento.momento.ui.theme.HuddlexTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            HuddlexTheme {
                // AuthGate mirrors the Flutter routing: auth → verify →
                // onboarding → home. Home is the real HomeScreen (Phase 3);
                // onboarding stays a placeholder until Phase 6 lands.
                AuthGate(
                    onboarding = { PlaceholderScreen("Onboarding — coming in Phase 6") },
                )
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
