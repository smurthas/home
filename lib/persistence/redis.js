var url = require('url');

var redis = require('redis');

var KEY = process.env.REDIS_KEY || 'SLAB_DATA';

var REDIS_URL = url.parse(process.env.REDISCLOUD_URL ||
                          process.env.OPENREDIS_URL ||
                          process.env.REDISTOGO_URL);
var password;
if (REDIS_URL.auth) {
  password = REDIS_URL.auth.split(':')[1];
}

var client = redis.createClient(REDIS_URL.port, REDIS_URL.hostname, {});

module.exports.load = function(callback) {
  function get() {
    client.get(KEY, function(err, data) {
      console.error('DEBUG REDIS data', data);
      if (err) return callback(err);
      if (!data) return callback(null, {});
      try {
        data = JSON.parse(data.toString());
      } catch(err) {
        console.error('DEBUG REDIS failed parse');
        data = {};
      }
      console.error('DEBUG REDIS data 2', data);
      callback(null, data);
    });
  }

  if (!password) return get();

  client.auth(password, function(err) {
    if (err) return callback(err);
    get();
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
