var exec = require('cordova/exec');

module.exports = {
    start: function (apSsid, apBssid, apPassword, deviceCountData, broadcastData, successCallback, failCallback) {
      console.log("EspTouch.start")
      exec(successCallback, failCallback, "EspTouch", "start", [apSsid, apBssid, apPassword, deviceCountData, broadcastData]);
    },
    stop: function (successCallback, failCallback) {
      console.log("EspTouch.stop")
      exec(successCallback, failCallback, "EspTouch", "stop", []);
    }
}
