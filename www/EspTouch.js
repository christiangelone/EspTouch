var exec = require('cordova/exec');

module.exports = {
    start: function (apSsid, apBssid, apPassword, deviceCountData, broadcastData, successCallback, failCallback) {
      exec(successCallback, failCallback, "EspTouch", "start", [apSsid, apBssid, apPassword, deviceCountData, broadcastData]);
    },
    stop: function (successCallback, failCallback) {
      exec(successCallback, failCallback, "EspTouch", "stop", []);
    }
}
