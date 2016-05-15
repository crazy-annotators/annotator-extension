# Our simpliest Chrome Storage API Wrapper
class Messager
    @read: (keys, callback) ->
        chrome.storage.local.get keys, callback

    @readAll: (callback) ->
        chrome.storage.local.get callback

    @send: (items, callback) ->
        if callback?
            chrome.storage.local.set items, callback
        else
            chrome.storage.local.set items

    @remove: (keys, callback) ->
        if callback?
            chrome.storage.local.remove keys, callback
        else
            chrome.storage.local.remove keys

    @clear: (callback) ->
        if callback?
            chrome.storage.local.clear callback
        else
            chrome.storage.local.clear()

    @addListener: (callback) ->
        chrome.storage.onChanged.addListener callback