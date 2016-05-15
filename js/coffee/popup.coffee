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

    commandPageSelectionListener = (mode, result) ->
        extendingObject = { }
        extendingObject[mode] = 
            source: activeTab.url
            selector:
                type: 'XPathSelector'
                value: result.data.xpath
                refinedBy:
                    type: 'TextPositionSelector'
                    exact: result.data.selectedText
                    start: result.data.start
                    end: result.data.end
        updateJson extendingObject

        console.timeEnd 'selection'

    commandSelectedImageListener = (mode, srcUrl) ->
        extendingObject = { }
        extendingObject[mode] = 
            id: srcUrl
            type: 'Image'
        updateJson extendingObject

        console.timeEnd 'selection'

    $ ->
        document.title = chrome.i18n.getMessage 'popup_html_title'

        if (localStorage.getItem 'stored-annotation-id')?
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
            ANNOTATION_TEMPLATE['body'] = {}
            dummy = {}
            dummy['body'] = { 'type': type }
            updateJson dummy

        $('#anno-content').on 'keyup', (event) ->
            val = $(@).val()
            ANNOTATION_TEMPLATE['body'] = {}
            dummy = {}
            switch ANNOTATION_TYPE
                when 'Page'
                    dummy['body'] = val
                when 'Text'
                    dummy['body'] = {'type': 'TextualBody', 'text': val, 'format': 'text/plain', 'language': 'en'}
                else
                    dummy['body'] = {'type': ANNOTATION_TYPE, 'id': val}
            updateJson dummy

        $('.save-button').on 'click', (event) ->
            db.post ANNOTATION_TEMPLATE, (err, response) ->
                status = document.getElementById 'doc-id'
                status.textContent = response.id
                $('#info-bar').show()

                localStorage.removeItem 'stored-annotation-id'
                localStorage.removeItem 'stored-annotation'

        $('.store-button').on 'click', (event) ->
            status = document.getElementById 'info-bar'
            status.textContent = 'Now you can go to another page to complete annotation.'
            $('#info-bar').show()

            localStorage.setItem 'stored-annotation-id', activeTab.id
            localStorage.setItem 'stored-annotation', JSON.stringify ANNOTATION_TEMPLATE

        $('.reset-button').on 'click', (event) ->
            localStorage.removeItem 'stored-annotation-id'
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
                stored_annotation_tab = localStorage.getItem 'stored-annotation-id'
                if stored_annotation_tab? and stored_annotation_tab != activeTab.id
                    mode = 'body'
                else
                    mode = 'target'
                commandSelectedImageListener mode, result.data.info.srcUrl


        # We will get images on the page and get selection if exists
        toBeExecutedScripts = ['selection', 'page_images']
        executeScript = ->
            return unless (script = toBeExecutedScripts.shift())?
            chrome.tabs.executeScript activeTab.id,
                file: 'js/content.' + script + '.js',
                ->
                    console.time script
                    Messager.read ['command', 'data'], (result) ->
                        stored_annotation_tab = localStorage.getItem 'stored-annotation-id'
                        if stored_annotation_tab? and stored_annotation_tab != activeTab.id
                            mode = 'body'
                        else
                            mode = 'target'

                        switch result.command
                            when 'selection' then commandPageSelectionListener mode, result
                            when 'page_images' then commandPageImagesListener mode, result

                        Messager.clear()
                        executeScript()

        # Execute scripts recursively
        chrome.tabs.executeScript activeTab.id, { file: 'js/storage.js' }, ->
            executeScript()

        # Tidy your room
        Messager.clear()

        console.timeEnd 'Popup Initialize'