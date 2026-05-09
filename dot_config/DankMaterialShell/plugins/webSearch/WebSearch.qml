import QtQuick
import Quickshell
import qs.Services

Item {
    id: root

    property var pluginService: null
    property string trigger: "?"
    property var searchEngines: []
    property string defaultEngine: "unduck"

    signal itemsChanged()

    property var builtInEngines: [
        {
            id: "unduck",
            name: "UnDuck",
            icon: "material:travel_explore",
            url: "https://unduck.link?q=%s",
            keywords: ["unduck", "search"]
        },
    ]

    Component.onCompleted: {
        loadSettings()
    }

    onPluginServiceChanged: {
        if (pluginService) {
            loadSettings()
        }
    }

    function loadSettings() {
        if (pluginService) {
            trigger = pluginService.loadPluginData("webSearch", "trigger", "?")
            defaultEngine = pluginService.loadPluginData("webSearch", "defaultEngine", "google")
            searchEngines = pluginService.loadPluginData("webSearch", "searchEngines", [])
        }
    }

    function getItems(query) {
        const items = []
        const allEngines = builtInEngines.concat(searchEngines)

        if (!query || query.trim().length === 0) {
            items.push({
                name: "Type a search query",
                icon: "unicode:🔍",
                comment: "Search the web with your default engine (" + getEngineName(defaultEngine) + ")",
                action: "noop",
                categories: ["Web Search"]
            })

            for (let i = 0; i < allEngines.length; i++) {
                const engine = allEngines[i]
                items.push({
                    name: engine.name,
                    icon: engine.icon || "unicode:🔍",
                    comment: engine.keywords ? engine.keywords.join(", ") : "Search engine",
                    action: "noop",
                    categories: ["Web Search"]
                })
            }

            return items
        }

        let matchedEngineId = null
        let searchQuery = query.trim()
        let fallbackQuery = query.trim()

        for (let i = 0; i < allEngines.length; i++) {
            const engine = allEngines[i]
            if (engine.keywords) {
                for (let k = 0; k < engine.keywords.length; k++) {
                    const keyword = engine.keywords[k]
                    if (searchQuery.toLowerCase().startsWith(keyword + " ")) {
                        matchedEngineId = engine.id
                        searchQuery = searchQuery.substring(keyword.length + 1).trim()
                        break
                    }
                }
                if (matchedEngineId) break
            }
        }

        const primaryEngineId = matchedEngineId || defaultEngine
        const primaryEngineObj = allEngines.find(e => e.id === primaryEngineId)

        if (primaryEngineObj) {
            items.push({
                name: "Search with " + primaryEngineObj.name + ": " + searchQuery,
                icon: primaryEngineObj.icon || "unicode:🔍",
                comment: "Open in browser",
                action: "search:" + primaryEngineId + ":" + searchQuery,
                categories: ["Web Search"]
            })
        }

        for (let i = 0; i < allEngines.length; i++) {
            const engine = allEngines[i]
            if (engine.id !== primaryEngineId) {
                items.push({
                    name: "Search with " + engine.name + ": " + (matchedEngineId ? fallbackQuery : searchQuery),
                    icon: engine.icon || "material:search",
                    comment: "Open in browser",
                    action: "search:" + engine.id + ":" + (matchedEngineId ? fallbackQuery : searchQuery),
                    categories: ["Web Search"]
                })
            }
        }

        return items
    }

    function executeItem(item) {
        if (!item || !item.action) {
            console.warn("WebSearch: Invalid item or action")
            return
        }

        console.log("WebSearch: Executing item:", item.name, "with action:", item.action)

        const actionParts = item.action.split(":")
        const actionType = actionParts[0]

        switch (actionType) {
            case "noop":
                return
            case "search":
                performSearch(actionParts)
                break
            default:
                console.warn("WebSearch: Unknown action type:", actionType)
                showToast("Unknown action: " + actionType)
        }
    }

    function performSearch(actionParts) {
        const engineId = actionParts[1]
        const query = actionParts.slice(2).join(":")

        const allEngines = builtInEngines.concat(searchEngines)
        const engine = allEngines.find(e => e.id === engineId)

        if (engine) {
            const encodedQuery = encodeQuery(query)
            const url = engine.url.replace("%s", encodedQuery)

            Quickshell.execDetached(["xdg-open", url])
            showToast("Searching " + engine.name + " for: " + query)
        } else {
            console.warn("WebSearch: Engine not found:", engineId)
            showToast("Search engine not found: " + engineId)
        }
    }

    function showToast(message) {
        if (typeof ToastService !== "undefined") {
            ToastService.showInfo("Web Search", message)
        } else {
            console.log("WebSearch Toast:", message)
        }
    }

    function getEngineName(engineId) {
        const allEngines = builtInEngines.concat(searchEngines)
        const engine = allEngines.find(e => e.id === engineId)
        return engine ? engine.name : "Unknown"
    }

    function encodeQuery(str) {
        return str.replace(/ /g, "+")
    }

    onTriggerChanged: {
        if (pluginService) {
            pluginService.savePluginData("webSearch", "trigger", trigger)
        }
        itemsChanged()
    }

    onDefaultEngineChanged: {
        if (pluginService) {
            pluginService.savePluginData("webSearch", "defaultEngine", defaultEngine)
        }
        itemsChanged()
    }

    onSearchEnginesChanged: {
        if (pluginService) {
            pluginService.savePluginData("webSearch", "searchEngines", searchEngines)
        }
        itemsChanged()
    }
}
