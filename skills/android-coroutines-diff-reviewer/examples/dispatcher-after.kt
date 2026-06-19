package com.example.calls

import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.withContext

class CallRepository(
    private val api: BlockingCallApi,
    private val dao: BlockingCallDao,
    private val ioDispatcher: CoroutineDispatcher
) {
    suspend fun refreshCalls(): List<CallItem> = withContext(ioDispatcher) {
        // Legacy blocking calls with unknown dispatcher behavior.
        val response = api.fetchCalls()
        val items = response.items.map { item ->
            CallItem(id = item.id, name = item.name.trim())
        }
        dao.replaceAll(items)
        items
    }
}
