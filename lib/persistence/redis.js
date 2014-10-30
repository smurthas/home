var url = require('url');

var redis = require('redis');

var KEY = process.env.REDIS_KEY || 'SLAB_DATA';

var REDIS_URL = url.parse(process.env.OPENREDIS_URL || process.env.REDISTOGO_URL);
var password = REDIS_URL.auth.split(':')[1];

var client = redis.createClient(REDIS_URL.port, REDIS_URL.hostname, {});

module.exports.load = function(callback) {
  client.auth(password, function(err) {
    if (err) return callback(err);
    client.get(KEY, function(err, data) {
      if (err) return callback(err);
      if (!data) return callback(null, {});
      try {
        data = JSON.parse(data.toString());
      } catch(err) {
        data = {};
      }
      callback(null, data);
    });
  });
};

module.exports.save = function(data, callback) {
  if (!data) {
    console.error('Cowardly refusing to persist falsy data object:', data);
    if (callback) callback();
  }
  client.set(KEY, JSON.stringify(data, 2, 2), callback || function (err) {
    if (err) console.error('error reading from redis key: ' + KEY, err);
  });
};
