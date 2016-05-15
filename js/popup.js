// Generated by CoffeeScript 1.10.0
var ANNOTATION_TEMPLATE, ANNOTATION_TYPE, runPopup;

console.time('Popup Initialize');

String.prototype.stripslashes = function() {
  return (this + '').replace(/\\(.?)/g, function(s, n1) {
    switch (n1) {
      case '\\':
        return '\\';
      case '0':
        return '\u0000';
      case '':
        return '';
      default:
        return n1;
    }
  });
};

String.prototype.htmlspecialchars = function(quote_style, double_encode) {
  var OPTS, i, j, noquotes, optTemp, ref, string, style;
  if (quote_style == null) {
    quote_style = 2;
  }
  optTemp = 0;
  i = 0;
  if (quote_style === false) {
    noquotes = true;
  }
  OPTS = {
    ENT_NOQUOTES: 0,
    ENT_HTML_QUOTE_SINGLE: 1,
    ENT_HTML_QUOTE_DOUBLE: 2,
    ENT_COMPAT: 2,
    ENT_QUOTES: 3,
    ENT_IGNORE: 4
  };
  string = this.toString();
  if (double_encode !== false) {
    string = string.replace(/&/g, '&amp;');
  }
  string = string.replace(/</g, '&lt;').replace(/>/g, '&gt;');
  if (typeof quote_style !== 'number') {
    quote_style = [].concat(quote_style);
    for (style = j = 0, ref = quote_style; 0 <= ref ? j < ref : j > ref; style = 0 <= ref ? ++j : --j) {
      if (OPTS[style] === 0) {
        noquotes = true;
      } else if (OPTS[style]) {
        optTemp = optTemp | OPTS[style];
      }
      quote_style = optTemp;
    }
  }
  if (quote_style & OPTS.ENT_HTML_QUOTE_SINGLE) {
    string = string.replace(/'/g, '&#039;');
  }
  if (!noquotes) {
    string = string.replace(/"/g, '&quot;');
  }
  return string;
};

ANNOTATION_TYPE = null;

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
};

chrome.tabs.query({
  currentWindow: true,
  active: true
}, function(result) {
  var activeTab;
  activeTab = result[0];
  return chrome.storage.sync.get(null, function(settings) {
    if (activeTab.id === -1) {
      throw new Error('Current tab id cannot be -1!');
    } else {
      return runPopup(activeTab, settings);
    }
  });
});

runPopup = function(activeTab, settings) {
  var commandPageImagesListener, commandPageSelectionListener, showAlert, updateJson;
  showAlert = function(msg, type) {
    var $alertContainer;
    if (msg == null) {
      msg = '';
    }
    if (type == null) {
      type = 'warning';
    }
    $alertContainer = $('#alerts');
    $alertContainer.html(msg).removeClass('');
    if (type !== '') {
      $alertContainer.addClass('alert').addClass('alert-' + type).css('display', 'block');
    }
    if (msg === '') {
      return $alertContainer.css('display', 'none');
    } else {
      return $alertContainer.css('display', 'block');
    }
  };
  updateJson = function(extendingObject) {
    var now;
    now = {
      'created': new Date().toLocaleString()
    };
    $.extend(true, ANNOTATION_TEMPLATE, extendingObject, now);
    return $('#generated-json').val(JSON.stringify(ANNOTATION_TEMPLATE, null, ' '));
  };
  commandPageImagesListener = function(result) {
    var imagesCount, img, j, k, len, len1, linkedImagesCount, ref, ref1, ref2, ref3, ref4, ref5;
    imagesCount = ((ref = result.data) != null ? ref.images : void 0) != null ? (ref1 = result.data) != null ? ref1.images.length : void 0 : 0;
    linkedImagesCount = ((ref2 = result.data) != null ? ref2.linkedImages : void 0) != null ? (ref3 = result.data) != null ? ref3.linkedImages.length : void 0 : 0;
    if (imagesCount > 0 || linkedImagesCount > 0) {
      $('#create-post-form div.note-editor > div.note-editable').css('height', 110);
      $('#page-images').html('');
    } else {
      $('#page-images').html('<p class="form-control-static">' + chrome.i18n.getMessage('popup_html_new_post_form_no_images') + '</p>');
    }
    if (imagesCount > 0) {
      ref4 = result.data.images;
      for (j = 0, len = ref4.length; j < len; j++) {
        img = ref4[j];
        $('#page-images').append('<img src="' + img + '" alt="" class="img-thumbnail">');
      }
    }
    if (linkedImagesCount > 0) {
      ref5 = result.data.linkedImages;
      for (k = 0, len1 = ref5.length; k < len1; k++) {
        img = ref5[k];
        $('#page-images').append('<img src="' + img + '" alt="" class="img-thumbnail">');
      }
    }
    return console.timeEnd('page_images');
  };
  commandPageSelectionListener = function(mode, result) {
    var extendingObject;
    extendingObject = {
      'id': activeTab.url
    };
    extendingObject[mode] = {
      source: activeTab.url,
      selector: {
        type: 'XPathSelector',
        value: result.data.xpath,
        refinedBy: {
          type: 'TextQuoteSelector',
          exact: result.data.selection,
          prefix: 'FINDME',
          suffix: 'FINDME'
        }
      }
    };
    updateJson(extendingObject);
    return console.timeEnd('selection');
  };
  return $(function() {
    var db, executeScript, mode, toBeExecutedScripts;
    document.title = chrome.i18n.getMessage('popup_html_title');
    mode = 'target';
    if ((localStorage.getItem('stored-annotation')) != null) {
      mode = 'body';
      ANNOTATION_TEMPLATE = JSON.parse(localStorage.getItem('stored-annotation'));
    }
    $('#generated-json').val(JSON.stringify(ANNOTATION_TEMPLATE, null, ' '));
    db = new PouchDB(settings.dbUrl, {
      'auth': {
        'username': settings.dbUsername,
        'password': settings.dbPassword
      }
    });
    updateJson({
      'creator': {
        'id': settings.creatorId,
        'name': settings.creatorName,
        'nick': settings.creatorNick
      }
    });
    $('[data-i18n]').each(function() {
      var key;
      key = $(this).data('i18n');
      switch ($(this).attr('data-i18n-method')) {
        case 'placeholder':
          return $(this).attr('placeholder', chrome.i18n.getMessage(key));
        case 'value':
          return $(this).attr('value', chrome.i18n.getMessage(key));
        default:
          return $(this).html(chrome.i18n.getMessage(key));
      }
    });
    $('#anno-motivation').on('change', function(event) {
      var motivations;
      motivations = $(this).val();
      return updateJson({
        "motivation": motivations.length === 1 ? motivations[0] : motivations
      });
    });
    $('.anno-type').on('click', function(event) {
      var dummy, type;
      $('.anno-type').removeClass('button-primary');
      $(this).addClass('button-primary');
      type = $(this).text();
      ANNOTATION_TYPE = type;
      ANNOTATION_TEMPLATE[mode] = {};
      dummy = {};
      dummy[mode] = {
        'type': type
      };
      return updateJson(dummy);
    });
    $('#anno-content').on('keyup', function(event) {
      var dummy, val;
      val = $(this).val();
      ANNOTATION_TEMPLATE[mode] = {};
      dummy = {};
      switch (ANNOTATION_TYPE) {
        case 'Page':
          dummy[mode] = val;
          break;
        case 'Text':
          dummy[mode] = {
            'type': 'TextualBody',
            'text': val,
            'format': 'text/plain',
            'language': 'en'
          };
          break;
        default:
          dummy[mode] = {
            'type': ANNOTATION_TYPE,
            'id': val
          };
      }
      return updateJson(dummy);
    });
    $('.save-button').on('click', function(event) {
      return db.post(ANNOTATION_TEMPLATE, function(err, response) {
        return localStorage.removeItem('stored-annotation');
      });
    });
    $('.store-button').on('click', function(event) {
      return localStorage.setItem('stored-annotation', JSON.stringify(ANNOTATION_TEMPLATE));
    });
    $('.reset-button').on('click', function(event) {
      localStorage.removeItem('stored-annotation');
      return location.reload();
    });
    $('.nerd-mode-button').on('click', function(event) {
      return $('.nerd-mode').toggle('slow');
    });
    $('#page-images').on('click', 'img', function(event) {});
    $("form input[type=submit]").click(function() {
      $("input[type=submit]", $(this).parents("form")).removeAttr("clicked");
      return $(this).attr("clicked", "true");
    });
    Messager.read(['command', 'data'], function(result) {
      var parseUrl;
      if (result.command === 'selected_image' && (result.data.info.srcUrl != null)) {
        parseUrl = document.createElement('a');
        return parseUrl.href = result.data.tab.url;
      }
    });
    toBeExecutedScripts = ['selection', 'page_images'];
    executeScript = function() {
      var script;
      if ((script = toBeExecutedScripts.shift()) == null) {
        return;
      }
      return chrome.tabs.executeScript(activeTab.id, {
        file: 'js/content.' + script + '.js'
      }, function() {
        console.time(script);
        return Messager.read(['command', 'data'], function(result) {
          switch (result.command) {
            case 'selection':
              commandPageSelectionListener(mode, result);
              break;
            case 'page_images':
              commandPageImagesListener(mode, result);
          }
          Messager.clear();
          return executeScript();
        });
      });
    };
    chrome.tabs.executeScript(activeTab.id, {
      file: 'js/storage.js'
    }, function() {
      return executeScript();
    });
    Messager.clear();
    return console.timeEnd('Popup Initialize');
  });
};
