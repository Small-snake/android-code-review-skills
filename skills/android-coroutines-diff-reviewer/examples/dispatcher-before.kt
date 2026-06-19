package com.example.calls

class CallRepository(
    private val api: BlockingCallApi,
    private val dao: BlockingCallDao
) {
    suspend fun refreshCalls(): List<CallItem> {
        // Legacy blocking calls with unknown dispatcher behavior.
        val response = api.fetchCalls()
        val items = response.items.map { item ->
            CallItem(id = item.id, name = item.name.trim())
        }
        dao.replaceAll(items)
        return items
    }
}
