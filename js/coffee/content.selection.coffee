# https://gist.github.com/SeavantUUz/9830668
`function getPathTo(element) {
    if (element===document.body)
        return element.tagName;

    var ix= 0;
    var siblings= element.parentNode.childNodes;
    for (var i= 0; i<siblings.length; i++) {
        var sibling= siblings[i];
        if (sibling===element)
            return getPathTo(element.parentNode)+'/'+element.tagName+'['+(ix+1)+']';
        if (sibling.nodeType===1 && sibling.tagName===element.tagName)
            ix++;
    }
}`

# Send selection to popup
if window.getSelection().toString() isnt ''
    Messager.send
        command: 'selection',
        data: {
            start: window.getSelection().anchorOffset,
            end: window.getSelection().focusOffset,
            selectedString: window.getSelection().toString(),
            xpath: getPathTo window.getSelection().getRangeAt(0).commonAncestorContainer,
            pageTitle: document.title,
            pageUrl: window.location.href
        },
        -> console.log 'Sent command selection', window.getSelection().toString()