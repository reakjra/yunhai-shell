pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import qs.services
import Quickshell;
import Quickshell.Io;
import QtQuick;

/**
 * A service for interacting with various booru APIs.
 */
Singleton {
    id: root
    property Component booruResponseDataComponent: BooruResponseData {}

    signal tagSuggestion(string query, var suggestions)
    signal responseFinished()

    property string failMessage: Translation.tr("That didn't work. Tips:\n- Check your tags and NSFW settings\n- If you don't have a tag in mind, type a page number")
    property var responses: []
    property int runningRequests: 0
    property var defaultUserAgent: Config.options?.networking?.userAgent || "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
    readonly property string apiUserAgent: "yunhai-shell/1.0 (booru viewer)"
    property var providerList: Object.keys(providers).filter(provider => provider !== "system" && providers[provider].api)
    readonly property var booruKeys: KeyringStorage.keyringData?.booruKeys ?? {}

    Component.onCompleted: {
        if (!KeyringStorage.loaded) KeyringStorage.fetchKeyringData()
    }

    // For providers behind cloudflare where XHR gets blocked
    property Component curlRequestComponent: Component {
        Process {
            property string requestUrl
            property var onFinished
            property bool finished: false
            running: false
            command: ["curl", "-g", "-s", "-L", "--compressed",
                "-H", `User-Agent: ${root.apiUserAgent}`,
                "-H", "Accept: application/json, text/plain, */*",
                "-H", "Accept-Language: en-US,en;q=0.5",
                requestUrl]
            stdout: StdioCollector {
                onStreamFinished: {
                    finished = true
                    onFinished(text)
                }
            }
            onExited: (exitCode, exitStatus) => {
                if (exitCode !== 0 && !finished) onFinished("")
            }
        }
    }
    property var providers: {
        "system": { "name": Translation.tr("System") },
        "yandere": {
            "name": "yande.re",
            "configKey": "yandere",
            "url": "https://yande.re",
            "api": "https://yande.re/post.json",
            "description": Translation.tr("All-rounder | Good quality, decent quantity"),
            "mapFunc": (response) => {
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags,
                        "rating": item.rating,
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_url,
                        "sample_url": item.sample_url ?? item.file_url,
                        "file_url": item.file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            },
            "tagSearchTemplate": "https://yande.re/tag.json?order=count&limit=10&name={{query}}*",
            "tagMapFunc": (response) => {
                return response.map(item => {
                    return {
                        "name": item.name,
                        "count": item.count
                    }
                })
            }
        },
        "konachan": {
            "name": "Konachan",
            "configKey": "konachan",
            "url": "https://konachan.net",
            "api": "https://konachan.net/post.json",
            "description": Translation.tr("For desktop wallpapers | Good quality"),
            "mapFunc": (response) => {
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags,
                        "rating": item.rating,
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_url,
                        "sample_url": item.sample_url ?? item.file_url,
                        "file_url": item.file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            },
            "tagSearchTemplate": "https://konachan.net/tag.json?order=count&limit=10&name={{query}}*",
            "tagMapFunc": (response) => {
                return response.map(item => {
                    return {
                        "name": item.name,
                        "count": item.count
                    }
                })
            }
        },
        "zerochan": {
            "name": "Zerochan",
            "configKey": "zerochan",
            "url": "https://www.zerochan.net",
            "api": "https://www.zerochan.net/?json",
            "description": Translation.tr("Clean stuff | Excellent quality, no NSFW"),
            "mapFunc": (response) => {
                response = response.items
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags.join(" "),
                        "rating": "safe", // Zerochan doesn't have nsfw
                        "is_nsfw": false,
                        "md5": item.md5,
                        "preview_url": item.thumbnail,
                        "sample_url": item.thumbnail,
                        "file_url": item.thumbnail,
                        "file_ext": "avif",
                        "source": getWorkingImageSource(item.source) ?? item.thumbnail,
                        "character": item.tag
                    }
                })
            }
        },
        "danbooru": {
            "name": "Danbooru",
            "configKey": "danbooru",
            "url": "https://danbooru.donmai.us",
            "api": "https://danbooru.donmai.us/posts.json",
            "requires_key": true,
            "key_id": "danbooru",
            "useCurl": true,
            "description": Translation.tr("The popular one | Best quantity, but quality can vary wildly"),
            "mapFunc": (response) => {
                return response.filter(item => item.preview_file_url).map(item => {
                    return {
                        "id": item.id,
                        "width": item.image_width,
                        "height": item.image_height,
                        "aspect_ratio": item.image_width / item.image_height,
                        "tags": item.tag_string,
                        "rating": item.rating,
                        "is_nsfw": (item.rating !== 'g'),
                        "md5": item.md5,
                        "preview_url": item.preview_file_url,
                        "sample_url": item.large_file_url ?? item.file_url,
                        "file_url": item.file_url ?? item.large_file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            },
            "tagSearchTemplate": "https://danbooru.donmai.us/tags.json?limit=10&search[name_matches]={{query}}*",
            "tagMapFunc": (response) => {
                return response.map(item => {
                    return {
                        "name": item.name,
                        "count": item.post_count
                    }
                })
            }
        },
        "gelbooru": {
            "name": "Gelbooru",
            "configKey": "gelbooru",
            "url": "https://gelbooru.com",
            "api": "https://gelbooru.com/index.php?page=dapi&s=post&q=index&json=1",
            "requires_key": true,
            "key_id": "gelbooru",
            "description": Translation.tr("The hentai one | Great quantity, a lot of NSFW, quality varies wildly"),
            "mapFunc": (response) => {
                response = response.post
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags,
                        "rating": item.rating.replace('general', 's').charAt(0),
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_url,
                        "sample_url": item.sample_url ?? item.file_url,
                        "file_url": item.file_url,
                        "file_ext": item.file_url.split('.').pop(),
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            },
            "tagSearchTemplate": "https://gelbooru.com/index.php?page=dapi&s=tag&q=index&json=1&orderby=count&limit=10&name_pattern={{query}}%",
            "tagMapFunc": (response) => {
                return response.tag.map(item => {
                    return {
                        "name": item.name,
                        "count": item.count
                    }
                })
            }
        },
        "waifu.im": {
            "name": "waifu.im",
            "configKey": "waifuIm",
            "url": "https://waifu.im",
            "api": "https://api.waifu.im/search",
            "description": Translation.tr("Waifus only | Excellent quality, limited quantity"),
            "mapFunc": (response) => {
                response = response.images
                return response.map(item => {
                    return {
                        "id": item.image_id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags.map(tag => {return tag.name}).join(" "),
                        "rating": item.is_nsfw ? "e" : "s",
                        "is_nsfw": item.is_nsfw,
                        "md5": item.md5,
                        "preview_url": item.sample_url ?? item.url, // preview_url just says access denied (maybe i fucked up and sent too many requests idk)
                        "sample_url": item.url,
                        "file_url": item.url,
                        "file_ext": item.extension,
                        "source": getWorkingImageSource(item.source) ?? item.url,
                    }
                })
            },
            "tagSearchTemplate": "https://api.waifu.im/tags",
            "tagMapFunc": (response) => {
                return [...response.versatile.map(item => {return {"name": item}}), 
                    ...response.nsfw.map(item => {return {"name": item}})]
            }
        },
        "t.alcy.cc": {
            "name": "Alcy",
            "configKey": "tAlcyCc",
            "url": "https://t.alcy.cc",
            "api": "https://t.alcy.cc/",
            "description": Translation.tr("Large images | God tier quality, no NSFW."),
            "fixedTags": [
                {
                    "name": "ycy",
                    "count": "General"
                },
                {
                    "name": "moez",
                    "count": "Moe"
                },
                {
                    "name": "ysz",
                    "count": "Genshin Impact"
                },
                {
                    "name": "fj",
                    "count": "Landscape"
                },
                {
                    "name": "bd",
                    "count": "Girl on white background"
                },
                {
                    "name": "xhl",
                    "count": "Shiggy"
                },
            ],
            "manualParseFunc": (responseText) => {
                // Alcy just returns image links, each on a new line
                const lines = responseText.trim().split('\n');
                return lines.map(line => {
                    return {
                        "id": Qt.md5(line),
                        // Alcy doesn't provide dimensions and images are often of god resolution
                        "width": 1000,
                        "height": 1000,
                        "aspect_ratio": 1,
                        "tags": "[no tags]",
                        "rating": "s",
                        "is_nsfw": false,
                        "md5": Qt.md5(line),
                        "preview_url": line,
                        "sample_url": line,
                        "file_url": line,
                        "file_ext": line.split('.').pop(),
                        "source": "",
                    }
                });
            },
        }
    }
    property var currentProvider: Persistent.states.booru.provider

    function getWorkingImageSource(url) {
        if (url.includes('pximg.net')) {
            return `https://www.pixiv.net/en/artworks/${url.substring(url.lastIndexOf('/') + 1).replace(/_p\d+\.(png|jpg|jpeg|gif)$/, '')}`;
        }
        return url;
    }
    
    function downloadPathFor(providerKey: string): string {
        const configKey = root.providers[providerKey]?.configKey
        const override = configKey ? Config.options.booru[configKey].downloadPath : ""
        return FileUtils.expandHome(override || Config.options.booru.downloadPath)
    }

    function saveFolderFor(providerKey: string, nsfw: bool): string {
        const base = root.downloadPathFor(providerKey)
        const nsfwFolder = Config.options.booru.nsfwFolder
        return (nsfw && nsfwFolder.length > 0) ? `${base}/${nsfwFolder}` : base
    }

    function setProvider(provider) {
        provider = provider.toLowerCase()
        if (providerList.indexOf(provider) !== -1) {
            Persistent.states.booru.provider = provider
            root.addSystemMessage(Translation.tr("Provider set to ") + providers[provider].name
                + (provider == "zerochan" ? Translation.tr(". Notes for Zerochan:\n- You must enter a color\n- Set your zerochan username in `booru.zerochan.username` config option. You [might be banned for not doing so](https://www.zerochan.net/api#:~:text=The%20request%20may%20still%20be%20completed%20successfully%20without%20this%20custom%20header%2C%20but%20your%20project%20may%20be%20banned%20for%20being%20anonymous.)!") : ""))
        } else {
            root.addSystemMessage(Translation.tr("Invalid API provider. Supported: \n- ") + providerList.join("\n- "))
        }
    }

    function clearResponses() {
        responses = []
    }

    function addSystemMessage(message) {
        responses = [...responses, root.booruResponseDataComponent.createObject(null, {
            "provider": "system",
            "tags": [],
            "page": -1,
            "images": [],
            "message": `${message}`
        })]
    }

    function constructRequestUrl(tags, nsfw=true, limit=20, page=1) {
        var provider = providers[currentProvider]
        var baseUrl = provider.api
        var url = baseUrl
        var tagString = tags.join(" ")
        if (!nsfw && !(["zerochan", "waifu.im", "t.alcy.cc"].includes(currentProvider))) {
            if (currentProvider == "gelbooru" || currentProvider == "danbooru")
                tagString += " rating:general";
            else
                tagString += " rating:safe";
        }
        var params = []
        // Tags & limit
        if (currentProvider === "zerochan") {
            params.push("c=" + tagString) // zerochan doesn't have search in api, so we use color
            params.push("l=" + limit)
            params.push("s=" + "fav")
            params.push("t=" + 1)
            params.push("p=" + page)
        }
        else if (currentProvider === "waifu.im") {
            var tagsArray = tagString.split(" ");
            tagsArray.forEach(tag => {
                params.push("included_tags=" + encodeURIComponent(tag));
            });
            params.push("limit=" + Math.min(limit, 30)) // Only admin can do > 30
            params.push("is_nsfw=" + (nsfw ? "null" : "false")) // null is random
        }
        else if (currentProvider === "t.alcy.cc") {
            url += tagString
            params.push("json")
            params.push("quantity=" + limit)
        }
        else {
            params.push("tags=" + encodeURIComponent(tagString))
            params.push("limit=" + limit)
            if (currentProvider == "gelbooru") {
                params.push("pid=" + page)
            }
            else {
                params.push("page=" + page)
            }
        }
        // Auth for providers that need it
        const providerInfo = providers[currentProvider]
        if (providerInfo.requires_key) {
            const creds = root.booruKeys?.[providerInfo.key_id]
            if (creds?.apiKey) params.push("api_key=" + encodeURIComponent(creds.apiKey))
            if (creds?.login) params.push("login=" + encodeURIComponent(creds.login))
            if (creds?.userId) params.push("user_id=" + encodeURIComponent(creds.userId))
        }

        if (baseUrl.indexOf("?") === -1) {
            url += "?" + params.join("&")
        } else {
            url += "&" + params.join("&")
        }
        return url
    }

    function handleResponseText(responseText, providerKey, newResponse) {
        try {
            const provider = providers[providerKey]
            let response;
            if (provider.manualParseFunc) {
                response = provider.manualParseFunc(responseText)
            } else {
                response = JSON.parse(responseText)
                response = provider.mapFunc(response)
            }
            newResponse.images = response
            newResponse.message = response.length > 0 ? "" : root.failMessage
        } catch (e) {
            console.log("[Booru] Failed to parse response:", e)
            newResponse.message = root.failMessage
        }
        root.runningRequests--;
        root.responses = [...root.responses, newResponse]
        root.responseFinished()
    }

    function makeRequest(tags, nsfw=false, limit=20, page=1) {
        if (!KeyringStorage.loaded) KeyringStorage.fetchKeyringData()
        const providerKey = currentProvider
        var url = constructRequestUrl(tags, nsfw, limit, page)

        const newResponse = root.booruResponseDataComponent.createObject(null, {
            "provider": providerKey,
            "tags": tags,
            "page": page,
            "images": [],
            "message": ""
        })

        root.runningRequests++;
        const provider = providers[providerKey]

        if (provider.useCurl) {
            const proc = curlRequestComponent.createObject(root, {
                requestUrl: url,
                onFinished: (text) => {
                    if (text.length === 0) {
                        console.log("[Booru] curl request returned empty response")
                        newResponse.message = root.failMessage
                        root.runningRequests--
                        root.responses = [...root.responses, newResponse]
                        root.responseFinished()
                    } else {
                        root.handleResponseText(text, providerKey, newResponse)
                    }
                    proc.destroy()
                }
            })
            proc.running = true
            return
        }

        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                root.handleResponseText(xhr.responseText, providerKey, newResponse)
            }
            else if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("[Booru] Request failed with status:", xhr.status)
                newResponse.message = root.failMessage
                root.runningRequests--;
                root.responses = [...root.responses, newResponse]
                root.responseFinished()
            }
        }

        try {
            if (currentProvider == "zerochan") {
                const userAgent = Config.options.booru.zerochan.username ? `Desktop sidebar booru viewer - username: ${Config.options.booru.zerochan.username}` : defaultUserAgent
                xhr.setRequestHeader("User-Agent", userAgent)
            }
        } catch (error) {
            console.log("[Booru] Could not set User-Agent:", error)
        }
        xhr.send()
    }

    property var currentTagRequest: null
    function triggerTagSearch(query) {
        if (currentTagRequest) {
            currentTagRequest.abort();
        }

        var provider = providers[currentProvider]
        if (provider.fixedTags) {
            root.tagSuggestion(query, provider.fixedTags)
            return provider.fixedTags;
        } else if (!provider.tagSearchTemplate) {
            return
        }
        var url = provider.tagSearchTemplate.replace("{{query}}", encodeURIComponent(query))
        if (provider.requires_key) {
            const creds = root.booruKeys?.[provider.key_id]
            const authParams = []
            if (creds?.apiKey) authParams.push("api_key=" + encodeURIComponent(creds.apiKey))
            if (creds?.login) authParams.push("login=" + encodeURIComponent(creds.login))
            if (creds?.userId) authParams.push("user_id=" + encodeURIComponent(creds.userId))
            if (authParams.length > 0) url += (url.includes("?") ? "&" : "?") + authParams.join("&")
        }

        if (provider.useCurl) {
            if (currentTagRequest) currentTagRequest.destroy()
            const proc = curlRequestComponent.createObject(root, {
                requestUrl: url,
                onFinished: (text) => {
                    currentTagRequest = null
                    try {
                        var response = JSON.parse(text)
                        response = provider.tagMapFunc(response)
                        root.tagSuggestion(query, response)
                    } catch (e) {
                        console.log("[Booru] Failed to parse tag response:", e)
                    }
                    proc.destroy()
                }
            })
            currentTagRequest = proc
            proc.running = true
            return
        }

        var xhr = new XMLHttpRequest()
        currentTagRequest = xhr
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                currentTagRequest = null
                try {
                    var response = JSON.parse(xhr.responseText)
                    response = provider.tagMapFunc(response)
                    root.tagSuggestion(query, response)
                } catch (e) {
                    console.log("[Booru] Failed to parse response: " + e)
                }
            }
            else if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("[Booru] Request failed with status: " + xhr.status)
            }
        }

        xhr.send()
    }

    function setBooruKey(provider, args) {
        const providerInfo = providers[provider]
        if (!providerInfo?.requires_key) {
            root.addSystemMessage(Translation.tr("%1 does not require an API key").arg(providerInfo?.name ?? provider))
            return
        }
        if (provider === "gelbooru") {
            // /key gelbooru <user_id> <api_key>
            if (args.length < 2) {
                root.addSystemMessage(Translation.tr("Usage: /key gelbooru <user_id> <api_key>\nFind these in My Account > Options > API credentials"))
                return
            }
            KeyringStorage.setNestedField(["booruKeys", providerInfo.key_id], { userId: args[0], apiKey: args[1] })
            root.addSystemMessage(Translation.tr("API key set for %1 (user_id: %2)").arg(providerInfo.name).arg(args[0]))
            return
        }
        // Danbooru style: /key danbooru <profile_url>
        try {
            const url = new URL(args[0])
            const login = url.searchParams.get("login")
            const apiKey = url.searchParams.get("api_key")
            if (!login || !apiKey) {
                root.addSystemMessage(Translation.tr("Could not parse URL. Expected format:\nhttps://danbooru.donmai.us/profile.json?api_key=YOUR_KEY&login=YOUR_LOGIN"))
                return
            }
            KeyringStorage.setNestedField(["booruKeys", providerInfo.key_id], { login, apiKey })
            root.addSystemMessage(Translation.tr("API key set for %1 (login: %2)").arg(providerInfo.name).arg(login))
        } catch (e) {
            root.addSystemMessage(Translation.tr("Invalid URL. Expected format:\nhttps://danbooru.donmai.us/profile.json?api_key=YOUR_KEY&login=YOUR_LOGIN"))
        }
    }

    function getBooruKey(provider) {
        const providerInfo = providers[provider]
        if (!providerInfo?.requires_key) {
            root.addSystemMessage(Translation.tr("%1 does not require an API key").arg(providerInfo?.name ?? provider))
            return
        }
        const creds = root.booruKeys?.[providerInfo.key_id]
        if (creds?.login) {
            root.addSystemMessage(Translation.tr("API key for %1:\n\n```\nLogin: %2\nAPI key: %3\n```").arg(providerInfo.name).arg(creds.login).arg(creds.apiKey))
        } else {
            root.addSystemMessage(Translation.tr("No API key stored for %1.\nUse /key %2 <profile_url> to set one.").arg(providerInfo.name).arg(provider))
        }
    }

    function clearBooruKey(provider) {
        const providerInfo = providers[provider]
        if (!providerInfo?.requires_key) {
            root.addSystemMessage(Translation.tr("%1 does not require an API key").arg(providerInfo?.name ?? provider))
            return
        }
        KeyringStorage.setNestedField(["booruKeys", providerInfo.key_id], {})
        root.addSystemMessage(Translation.tr("API key cleared for %1").arg(providerInfo.name))
    }
}

