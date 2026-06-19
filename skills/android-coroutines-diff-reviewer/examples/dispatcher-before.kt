package com.example.calls

class CallRepository(
    private val api: CallApi,
    private val dao: CallDao
) {
    suspend fun refreshCalls(): List<CallItem> {
        val response = api.fetchCalls()
        val items = response.items.map { item ->
            CallItem(id = item.id, name = item.name.trim())
        }
        dao.replaceAll(items)
        return items
    }
}
