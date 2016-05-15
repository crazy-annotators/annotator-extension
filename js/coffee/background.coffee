# Detect is extension installed first time?
chrome.runtime.onInstalled.addListener (reason, previousVersion) ->
    if reason.reason is 'install'
        Messager.send extension_installed: 'first_time'

# When extension started, clear the badge for new startings. :)
chrome.browserAction.setBadgeText text: ''

# Just I'm doing Git tests.
Messager.addListener (r) -> console.log r

# Add menu item into selected text's menu context.
# info type properties: editable, linkUrl, mediaType, menuItemId, pageUrl, srcUrl
# selectionContext = chrome.contextMenus.create
#     title: 'Create a anonotation with selection'
#     contexts: ['selection']
#     onclick: (info, tab) ->
#         Messager.send command: 'selected_text', data: { type: 'text', info: info, tab: tab }, ->
#             notification = new Notification
#                 title: 'context_menu_selected_text_title',
#                 msg: 'context_menu_selected_text_msg',
#                 icon: 'img/a128.png'
#             notification.clearAfter 2
#             notification.show()

#             chrome.browserAction.setBadgeText text: ''
#             timer = new CensorBadge 5 * 1000, 600
#             timer.start()

# Add menu item into selected image's menu context.
imageContext = chrome.contextMenus.create
    title: 'Create anonotation for this image'
    contexts: ['image']
    onclick: (info, tab) ->
        console.log info, tab
        Messager.send command: 'selected_image', data: { type: 'image', info: info, tab: tab }, ->
            notification = new Notification
                title: 'context_menu_image_text_title',
                msg: 'context_menu_image_text_msg',
                icon: 'img/a128.png'
            notification.clearAfter 2
            notification.show()

            chrome.browserAction.setBadgeText text: ''
            timer = new CensorBadge 5 * 1000, 600
            timer.start()
