class AspectCalculator
    @calc: (w, h) ->
        return 1 if !w or !h
        
        gcd = @calcGcd w, h

        (w / gcd) / (h / gcd)

    @calcGcd: (a, b) ->
        if b is 0 then a else @calcGcd a, a%b

getSize = (url) ->
    img = document.createElement 'img'
    img.src = url

    w: img.width, h: img.height

filterImages = (images) ->
    result = []

    typeString = Object.prototype.toString.call images

    if typeString is '[object Array]'
        for src in images
            testElement = document.createElement 'a'
            testElement.href = src

            if testElement.protocol in ['http:', 'https:']
                {w, h} = getSize(src)

                continue if w is 0 or h is 0

                result.push src unless h < 50 or w < 85 or 0.4 > AspectCalculator.calc(w, h) > 4

    else if typeString is '[object Object]'
        for src, dummy of images
            testElement = document.createElement 'a'
            testElement.href = src

            if testElement.protocol in ['http:', 'https:']
                {w, h} = getSize(src)

                continue if w is 0 or h is 0

                result.push src unless h < 50 or w < 85 or 0.4 > AspectCalculator.calc(w, h) > 4
    result

` var imageDownloader = {
  imageRegex: /(?:([^:\/?#]+):)?(?:\/\/([^\/?#]*))?([^?#]*\.(?:jpe?g|gif|png))(?:\?([^#]*))?(?:#(.*))?/,
  mapElement: function (element) {
    if (element.tagName.toLowerCase() === 'img') {
      var src = element.src;
      var hashIndex = src.indexOf('#');
      if (hashIndex >= 0) {
        src = src.substr(0, hashIndex);
      }
      return src;
    }

    if (element.tagName.toLowerCase() === 'a') {
      var href = element.href;
      if (imageDownloader.isImageURL(href)) {
        imageDownloader.linkedImages[href] = '0';
        return href;
      }
    }

    var backgroundImage = element.style['background-image'];
    if (backgroundImage) {
      var parsedURL = imageDownloader.extractURLFromStyle(backgroundImage);
      if (imageDownloader.isImageURL(parsedURL)) {
        return parsedURL;
      }
    }

    return '';
  },

  extractURLFromStyle: function (url) {
    return url.replace(/^url\(["']?/, '').replace(/["']?\)$/, '');
  },

  isImageURL: function (url) {
    return url.substring(0, 10) === 'data:image' || imageDownloader.imageRegex.test(url);
  },

  removeDuplicateOrEmpty: function (images) {
    var result = [],
        hash = {};

    for (var i = 0; i < images.length; i++) {
      hash[images[i]] = 0;
    }
    for (var key in hash) {
      if (key !== '') {
        result.push(key);
      }
    }
    return result;
  }
};

imageDownloader.linkedImages = {};
imageDownloader.images = [].slice.apply(document.getElementsByTagName('*'));
imageDownloader.images = imageDownloader.images.map(imageDownloader.mapElement);

for (var i = 0; i < document.styleSheets.length; i++) { // Extract images from styles
  var cssRules = document.styleSheets[i].cssRules;
  if (cssRules) {
    for (var j = 0; j < cssRules.length; j++) {
      var style = cssRules[j].style;
      if (style && style['background-image']) {
        var url = imageDownloader.extractURLFromStyle(style['background-image']);
        if (imageDownloader.isImageURL(url)) {
          imageDownloader.images.push(url);
        }
      }
    }
  }
}

imageDownloader.images = imageDownloader.removeDuplicateOrEmpty(imageDownloader.images);

Messager.send({
  command: 'page_images',
  data: {
    linkedImages: filterImages(imageDownloader.linkedImages),
    images: filterImages(imageDownloader.images),
    pageTitle: document.title,
    pageUrl: window.location.href
  }
}, function() {
  return console.log('Sent command: page_images');
});

imageDownloader.linkedImages = null;
imageDownloader.images = null;`
