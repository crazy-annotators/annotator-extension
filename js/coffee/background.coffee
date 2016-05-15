# Detect is extension installed first time?
chrome.runtime.onInstalled.addListener (reason, previousVersion) ->
    if reason.reason is 'install'
        Messager.send extension_installed: 'first_time'

# When extension started, clear the badge for new startings. :)
chrome.browserAction.setBadgeText text: ''

# Add menu item into selected image's menu context.
imageContext = chrome.contextMenus.create
    title: 'Create anonotation with this image'
    contexts: ['image']
    onclick: (info, tab) ->
        console.log info, tab
        Messager.send command: 'selected_image', data: { type: 'image', info: info, tab: tab }, ->
            chrome.browserAction.setBadgeText text: ''
            timer = new CensorBadge 5 * 1000, 600
            timer.start()
