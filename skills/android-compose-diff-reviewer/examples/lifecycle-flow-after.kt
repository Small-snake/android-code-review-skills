package com.example.calls

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@Composable
fun CallLogScreen(viewModel: CallLogViewModel) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    when (val state = uiState) {
        CallLogUiState.Loading -> Text("Loading")
        CallLogUiState.Empty -> Text("No calls")
        is CallLogUiState.Error -> Text(state.message)
        is CallLogUiState.Content -> {
            state.items.forEach { item ->
                Text(item.name)
            }
        }
    }
}
