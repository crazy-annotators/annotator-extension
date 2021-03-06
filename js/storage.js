// Generated by CoffeeScript 1.10.0
var Messager;

Messager = (function() {
  function Messager() {}

  Messager.read = function(keys, callback) {
    return chrome.storage.local.get(keys, callback);
  };

  Messager.readAll = function(callback) {
    return chrome.storage.local.get(callback);
  };

  Messager.send = function(items, callback) {
    if (callback != null) {
      return chrome.storage.local.set(items, callback);
    } else {
      return chrome.storage.local.set(items);
    }
  };

  Messager.remove = function(keys, callback) {
    if (callback != null) {
      return chrome.storage.local.remove(keys, callback);
    } else {
      return chrome.storage.local.remove(keys);
    }
  };

  Messager.clear = function(callback) {
    if (callback != null) {
      return chrome.storage.local.clear(callback);
    } else {
      return chrome.storage.local.clear();
    }
  };

  Messager.addListener = function(callback) {
    return chrome.storage.onChanged.addListener(callback);
  };

  return Messager;

})();
