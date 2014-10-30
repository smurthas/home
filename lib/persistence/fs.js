var fs = require('fs');

var PATH = process.env.BE_HOME_FILE || './home.json';


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

module.exports.save = function(data, callback) {
  if (!data) {
    console.error('Cowardly refusing to persist falsy data object:', data);
    if (callback) callback();
  }
  fs.writeFile(PATH, JSON.stringify(data, 2, 2), callback || function (err) {
    if (err) console.error('error reading from ' + PATH, err);
  });
};
