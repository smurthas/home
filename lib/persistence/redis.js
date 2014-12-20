var url = require('url');

var client;
var KEY;

module.exports.init = function(options, callback) {
  KEY = options.key || process.env.REDIS_KEY || 'SLAB_DATA';

  var REDIS_URL = url.parse(options.url ||
                            process.env.REDISCLOUD_URL ||
                            process.env.OPENREDIS_URL ||
                            process.env.REDISTOGO_URL);
  var password;
  if (REDIS_URL.auth) {
    password = REDIS_URL.auth.split(':')[1];
  }

  var redis = require(options.module || 'redis');
  client = redis.createClient(REDIS_URL.port, REDIS_URL.hostname, {});
  if (!password) return callback();

  client.auth(password, callback);
};

module.exports.load = function(callback) {
  client.get(KEY, function(err, data) {
    if(process.env.DEBUG) console.error('DEBUG REDIS data', data);
    if (err) return callback(err);
    if (!data) return callback(null, {});

    try {
      data = JSON.parse(data.toString());
    } catch(err) {
      console.error('DEBUG REDIS failed parse');
      data = {};
    }
    if(process.env.DEBUG) console.error('DEBUG REDIS data 2', data);
    callback(null, data);
  });
};

module.exports.save = function(data, callback) {
  if (!data) {
    console.error('Cowardly refusing to persist falsy data object:', data);
    if (callback) callback();
  }
  var stringData = JSON.stringify(data);
  client.set(KEY, stringData, callback || function (err) {
    if (err) console.error('error reading from redis key: ' + KEY, err);
  });
};
