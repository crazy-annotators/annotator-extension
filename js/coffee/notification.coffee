uniqueId = (length=8) ->
    id = ""
    id += Math.random().toString(36).substr(2) while id.length < length
    id.substr 0, length

notificationDebug = false

###
    Example Usage:

    notification = new Notification
        title: 'Deneme',
        msg: 'Sadece bir message...',
        icon: 'img/a128.png',
        buttonListener: (notificationId, index) ->
            console.log index
            console.log notificationId

    notification.setButton 'Yes'
    notification.setButton 'No'

    notification.clearAfter 3

    notification.show()
###

class Notification
    constructor: (options) ->
        {@id, @title, @msg, @type, @icon, @buttonListener} = options

        # Define defaults...
        @id = uniqueId() unless @id?
        @type = 'basic' unless @type?
        @icon = '' unless @icon?
        @buttons = []
        @callbacks = []

        console.log 'Initialized new Notification class', @id if notificationDebug
        console.log @ if notificationDebug

    # TODO: Her buton icin yeni listener ekle. Parametre hazir. ;D
    setButton: (title, callback = null) ->
        throw 'You can add three buttons maximum.' if @buttons.length > 2

        @buttons.push title: title

        console.log 'Added new button', title, @id if notificationDebug

    setCallback: (@callback) ->
        @callbacks.push callback

        console.log 'Set new callback', @id if notificationDebug

    # Set a timeout to clear notification after tree seconds
    clearAfter: (@clearSeconds = 0, @clearCallback) ->
        @clearCallback = (wasCleared) -> console.log wasCleared if @clearCallback?
        console.log 'Notification will closed after', @seconds, '#', @id if notificationDebug and @clearSeconds > 0

    show: ->
        chrome.notifications.create 'notify',
            type : @type
            title: @title
            message: @msg
            buttons: @buttons || {}
            iconUrl: chrome.extension.getURL(@icon),
            (notificationId) =>
                callback.call null, notificationId for callback in @callbacks

                # Set timeout to close after @clearSeconds
                setTimeout chrome.notifications.clear, @clearSeconds * 1000, notificationId, @clearCallback if @clearSeconds

                # Create button listener
                chrome.notifications.onButtonClicked.addListener @buttonListener if @buttonListener?

                console.log 'Called callback', callback if notificationDebug