var fs = require('fs');

var PATH = process.env.BE_HOME_FILE || './home.json';
var FLUSH_DELAY = 5000;


module.exports.load = function(callback) {
  fs.readFile(PATH, function(err, data) {
    if (err) return callback(err);
    if (!data) return callback(null, {});
    try {
      data = JSON.parse(data.toString());
    } catch(err) {
      data = {};
    }
    callback(null, data);
  });
};

var saveTimeout;

function doSave(data, callback) {
  if (saveTimeout) return callback();
  saveTimeout = setTimeout(function() {
    saveTimeout = null;
    fs.writeFile(PATH, JSON.stringify(data, 2, 2), callback);
  }, FLUSH_DELAY);
}

module.exports.save = function(data, callback) {
  if (!data) {
    console.error('Cowardly refusing to persist falsy data object:', data);
    if (callback) callback();
  }
  doSave(data, callback || function (err) {
    if (err) console.error('error writing to ' + PATH, err);
  });
};
