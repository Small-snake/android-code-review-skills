package com.example.calls

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.collectAsState

@Composable
fun CallLogScreen(viewModel: CallLogViewModel) {
    val uiState by viewModel.uiState.collectAsState()

    if (uiState.isLoading) {
        Text("Loading")
    }

    uiState.errorMessage?.let { message ->
        Text(message)
    }

    uiState.items.forEach { item ->
        Text(item.name)
    }
}
