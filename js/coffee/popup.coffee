console.time 'Popup Initialize'

String::stripslashes = ->
    (@ + '').replace(/\\(.?)/g, (s, n1) -> 
       switch n1
            when '\\' then return '\\'
            when '0' then return '\u0000'
            when '' then return ''
            else return n1
    )

String::htmlspecialchars = (quote_style = 2, double_encode) ->
    optTemp = 0
    i = 0
    noquotes = true if quote_style is false
    OPTS =
        ENT_NOQUOTES: 0
        ENT_HTML_QUOTE_SINGLE: 1
        ENT_HTML_QUOTE_DOUBLE: 2
        ENT_COMPAT: 2
        ENT_QUOTES: 3
        ENT_IGNORE: 4

    string = @.toString()
    string = string.replace(/&/g, '&amp;') if double_encode isnt false
    string = string.replace(/</g, '&lt;').replace(/>/g, '&gt;')

    if typeof quote_style isnt 'number'
        quote_style = [].concat(quote_style)
        for style in [0...quote_style]
            if OPTS[style] is 0
                noquotes = true
            else if OPTS[style]
                optTemp = optTemp | OPTS[style]
            quote_style = optTemp

    string = string.replace(/'/g, '&#039;') if quote_style & OPTS.ENT_HTML_QUOTE_SINGLE
    string = string.replace(/"/g, '&quot;') if !noquotes
    string

ANNOTATION_TYPE = null
ANNOTATION_TEMPLATE = {
    "@context": "http://www.w3.org/ns/anno.jsonld",
    "id": null,
    "type": "Annotation",
    "motivation": null,
    "created": null,
    "creator": {
        "id": "http://example.org/user1",
        "type": "Person",
        "name": "A. Person",
        "nick": "user1"
    },
    "generator": {
        "id": "https://github.com/crazy-annotators",
        "type": "SoftwareAgent",
        "name": "Annotator",
        "homepage": "https://github.com/crazy-annotators"
    },
    "body": {},
    "target": {}
}

chrome.tabs.query {currentWindow: true, active : true}, (result) ->
    activeTab = result[0]
    chrome.storage.sync.get null, (settings) ->
        if activeTab.id is -1
            throw new Error 'Current tab id cannot be -1!'
        else runPopup activeTab, settings

runPopup = (activeTab, settings) ->
    showAlert = (msg = '', type = 'warning') ->
        $alertContainer = $('#alerts')
        $alertContainer.html(msg).removeClass('')
        $alertContainer.addClass('alert').addClass('alert-' + type).css('display', 'block') if type isnt ''
        if msg is '' then $alertContainer.css('display', 'none') else $alertContainer.css('display', 'block')

    updateJson = (extendingObject) ->
        now = { 'created': new Date().toLocaleString() }
        $.extend true, ANNOTATION_TEMPLATE, extendingObject, now
        $('#generated-json').val JSON.stringify ANNOTATION_TEMPLATE, null, ' '

    commandPageImagesListener = (result) ->
        imagesCount = if result.data?.images? then result.data?.images.length else 0
        linkedImagesCount = if result.data?.linkedImages? then result.data?.linkedImages.length else 0

        if imagesCount > 0 or linkedImagesCount > 0
            $('#create-post-form div.note-editor > div.note-editable').css 'height', 110

            $('#page-images').html ''
        else
            $('#page-images').html '<p class="form-control-static">' + chrome.i18n.getMessage('popup_html_new_post_form_no_images') + '</p>'

        if imagesCount > 0
            for img in result.data.images
                $('#page-images').append '<img src="' + img + '" alt="" class="img-thumbnail">'

        if linkedImagesCount > 0
            for img in result.data.linkedImages
                $('#page-images').append '<img src="' + img + '" alt="" class="img-thumbnail">'

        console.timeEnd 'page_images'

    commandPageSelectionListener = (result) ->
        extendingObject =
            id: activeTab.url
            target:
                source: activeTab.url
                selector:
                        type: 'XPathSelector'
                        value: result.data.xpath
                        refinedBy:
                            type: 'TextQuoteSelector'
                            exact: result.data.selection
                            prefix: 'FINDME'
                            suffix: 'FINDME'
        updateJson extendingObject

        console.timeEnd 'selection'

    $ ->
        document.title = chrome.i18n.getMessage 'popup_html_title'

        mode = 'body'
        if (localStorage.getItem 'stored-annotation')?
            mode = 'target'
            ANNOTATION_TEMPLATE = JSON.parse localStorage.getItem 'stored-annotation'
        $('#generated-json').val JSON.stringify ANNOTATION_TEMPLATE, null, ' '

        # Connect to DB
        db = new PouchDB settings.dbUrl, {
            'auth':
                'username': settings.dbUsername
                'password': settings.dbPassword
        }

        updateJson {'creator': {
            'id': settings.creatorId,
            'name': settings.creatorName,
            'nick': settings.creatorNick,
        }}

        $('[data-i18n]').each ->
            key = $(@).data 'i18n'
            switch $(@).attr 'data-i18n-method'
                when 'placeholder' then $(@).attr 'placeholder', chrome.i18n.getMessage key
                when 'value' then $(@).attr 'value', chrome.i18n.getMessage key
                else $(@).html chrome.i18n.getMessage key

        $('#anno-motivation').on 'change', (event) ->
            motivations = $(@).val()
            updateJson { "motivation": if motivations.length is 1 then motivations[0] else motivations }

        $('.anno-type').on 'click', (event) ->
            $('.anno-type').removeClass 'button-primary'
            $(@).addClass 'button-primary'
            type = $(@).text()
            ANNOTATION_TYPE = type
            ANNOTATION_TEMPLATE[mode] = {}
            debugger;
            updateJson { mode: { 'type': type } }

        $('#anno-content').on 'keyup', (event) ->
            val = $(@).val()
            switch ANNOTATION_TYPE
                when 'Page'
                    updateJson { mode: val }
                when 'Text'
                    updateJson { mode: {'type': 'TextualBody', 'text': val, 'format': 'text/plain', 'language': 'en'} }
                else
                    updateJson { mode: {'type': ANNOTATION_TYPE, 'id': val} }

        $('.save-button').on 'click', (event) ->
            db.post ANNOTATION_TEMPLATE, (err, response) ->
                localStorage.removeItem 'stored-annotation'

        $('.store-button').on 'click', (event) ->
            localStorage.setItem 'stored-annotation', JSON.stringify ANNOTATION_TEMPLATE

        $('.reset-button').on 'click', (event) ->
            localStorage.removeItem 'stored-annotation'
            location.reload()

        $('.nerd-mode-button').on 'click', (event) ->
            $('.nerd-mode').toggle 'slow'

        $('#page-images').on 'click', 'img', (event) ->
            return

        $("form input[type=submit]").click ->
            $("input[type=submit]", $(this).parents("form")).removeAttr("clicked")
            $(this).attr("clicked", "true")

        Messager.read ['command', 'data'], (result) ->
            # When user select a image...
            if result.command is 'selected_image' and result.data.info.srcUrl?
                parseUrl = document.createElement 'a'
                parseUrl.href = result.data.tab.url


        # We will get images on the page and get selection if exists
        toBeExecutedScripts = ['selection', 'page_images']
        executeScript = ->
            return unless (script = toBeExecutedScripts.shift())?
            chrome.tabs.executeScript activeTab.id,
                file: 'js/content.' + script + '.js',
                ->
                    console.time script
                    Messager.read ['command', 'data'], (result) ->
                        switch result.command
                            when 'selection' then commandPageSelectionListener result
                            when 'page_images' then commandPageImagesListener result

                        Messager.clear()
                        executeScript()

        # Execute scripts recursively
        chrome.tabs.executeScript activeTab.id, { file: 'js/storage.js' }, ->
            executeScript()

        # Tidy your room
        Messager.clear()

        console.timeEnd 'Popup Initialize'