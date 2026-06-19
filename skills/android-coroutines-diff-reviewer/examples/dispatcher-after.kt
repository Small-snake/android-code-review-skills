package com.example.calls

import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.withContext

class CallRepository(
    private val api: CallApi,
    private val dao: CallDao,
    private val ioDispatcher: CoroutineDispatcher
) {
    suspend fun refreshCalls(): List<CallItem> = withContext(ioDispatcher) {
        val response = api.fetchCalls()
        val items = response.items.map { item ->
            CallItem(id = item.id, name = item.name.trim())
        }
        dao.replaceAll(items)
        items
    }
}
