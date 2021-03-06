// Generated by CoffeeScript 1.10.0
var CensorBadge;

CensorBadge = (function() {
  CensorBadge.even = true;

  function CensorBadge(total, period) {
    this.total = total != null ? total : 10000;
    this.period = period != null ? period : 1000;
  }

  CensorBadge.prototype.start = function() {
    var timer;
    timer = window.setInterval((function() {
      chrome.browserAction.setBadgeText({
        text: this.even ? 'click' : ''
      });
      return this.even = this.even ? false : true;
    }), this.period);
    setTimeout(this._destructor, this.total, timer);
    return this.even = this.even ? false : true;
  };

  CensorBadge.prototype._destructor = function(timer) {
    window.clearInterval(timer);
    return chrome.browserAction.setBadgeText({
      text: ''
    });
  };

  return CensorBadge;

})();
