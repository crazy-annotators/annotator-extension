// Generated by CoffeeScript 1.10.0
var AspectCalculator, filterImages, getSize;

AspectCalculator = (function() {
  function AspectCalculator() {}

  AspectCalculator.calc = function(w, h) {
    var gcd;
    if (!w || !h) {
      return 1;
    }
    gcd = this.calcGcd(w, h);
    return (w / gcd) / (h / gcd);
  };

  AspectCalculator.calcGcd = function(a, b) {
    if (b === 0) {
      return a;
    } else {
      return this.calcGcd(a, a % b);
    }
  };

  return AspectCalculator;

})();

getSize = function(url) {
  var img;
  img = document.createElement('img');
  img.src = url;
  return {
    w: img.width,
    h: img.height
  };
};

filterImages = function(images) {
  var dummy, h, i, len, ref, ref1, ref2, ref3, ref4, ref5, result, src, testElement, typeString, w;
  result = [];
  typeString = Object.prototype.toString.call(images);
  if (typeString === '[object Array]') {
    for (i = 0, len = images.length; i < len; i++) {
      src = images[i];
      testElement = document.createElement('a');
      testElement.href = src;
      if ((ref = testElement.protocol) === 'http:' || ref === 'https:') {
        ref1 = getSize(src), w = ref1.w, h = ref1.h;
        if (w === 0 || h === 0) {
          continue;
        }
        if (!(h < 50 || w < 85 || (0.4 > (ref2 = AspectCalculator.calc(w, h)) && ref2 > 4))) {
          result.push(src);
        }
      }
    }
  } else if (typeString === '[object Object]') {
    for (src in images) {
      dummy = images[src];
      testElement = document.createElement('a');
      testElement.href = src;
      if ((ref3 = testElement.protocol) === 'http:' || ref3 === 'https:') {
        ref4 = getSize(src), w = ref4.w, h = ref4.h;
        if (w === 0 || h === 0) {
          continue;
        }
        if (!(h < 50 || w < 85 || (0.4 > (ref5 = AspectCalculator.calc(w, h)) && ref5 > 4))) {
          result.push(src);
        }
      }
    }
  }
  return result;
};

 var imageDownloader = {
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
imageDownloader.images = null;;
