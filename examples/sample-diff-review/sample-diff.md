# Sample Diff

This synthetic diff combines two common Android review problems:

- Compose collects a `Flow` with `collectAsState()` instead of lifecycle-aware collection.
- A repository starts refresh work in `GlobalScope`, which can outlive the caller and hide failures.

```diff
diff --git a/app/src/main/java/com/example/calls/CallLogScreen.kt b/app/src/main/java/com/example/calls/CallLogScreen.kt
index 8d1b334..91ac057 100644
--- a/app/src/main/java/com/example/calls/CallLogScreen.kt
+++ b/app/src/main/java/com/example/calls/CallLogScreen.kt
@@ -1,13 +1,23 @@
 package com.example.calls

 import androidx.compose.material3.Text
 import androidx.compose.runtime.Composable
+import androidx.compose.runtime.collectAsState
 import androidx.compose.runtime.getValue

 @Composable
 fun CallLogScreen(viewModel: CallLogViewModel) {
-    val uiState = viewModel.currentState
+    val uiState by viewModel.uiState.collectAsState()

-    Text(uiState.title)
+    if (uiState.isLoading) {
+        Text("Loading")
+    }
+
+    uiState.errorMessage?.let { message ->
+        Text(message)
+    }
+
+    uiState.items.forEach { item ->
+        Text(item.name)
+    }
 }
diff --git a/app/src/main/java/com/example/calls/CallRepository.kt b/app/src/main/java/com/example/calls/CallRepository.kt
index fbb92ad..45e7e12 100644
--- a/app/src/main/java/com/example/calls/CallRepository.kt
+++ b/app/src/main/java/com/example/calls/CallRepository.kt
@@ -1,15 +1,23 @@
 package com.example.calls

+import kotlinx.coroutines.GlobalScope
+import kotlinx.coroutines.launch
+
 class CallRepository(
     private val api: BlockingCallApi,
     private val dao: BlockingCallDao
 ) {
-    suspend fun refreshCalls(): List<CallItem> {
-        val response = api.fetchCalls()
-        val items = response.items.map { item ->
-            CallItem(id = item.id, name = item.name.trim())
+    fun refreshCalls() {
+        GlobalScope.launch {
+            val response = api.fetchCalls()
+            val items = response.items.map { item ->
+                CallItem(id = item.id, name = item.name.trim())
+            }
+            dao.replaceAll(items)
         }
-        dao.replaceAll(items)
-        return items
     }
 }
```
