var fs;

var PATH;
var FLUSH_DELAY;

module.exports.init = function(options, callback) {
  FLUSH_DELAY = options.flush || 5000;
  PATH = options.file || process.env.BE_HOME_FILE || './home.json';
  fs = options.module || require('fs');
  callback();
};

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
