# Our simple censor badge class.
# Used for alert user with nice badge.
class CensorBadge
    @even = yes

    constructor: (@total = 10000, @period = 1000) ->

    start: ->
        timer = window.setInterval (->
            chrome.browserAction.setBadgeText text: if @even then 'click' else ''
            @even = if @even then no else yes), @period

        setTimeout @_destructor, @total, timer

        @even = if @even then no else yes

    _destructor: (timer) ->
        window.clearInterval timer
        chrome.browserAction.setBadgeText text: ''