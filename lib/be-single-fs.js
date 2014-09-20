var fs = require('fs');

var sift = require('sift');
var fiddle = require('fiddle');
var async = require('async');


var PATH = process.env.HOME_FILE || './home.json';

var data;
function load() {
  try {
    data = JSON.parse(fs.readFileSync(PATH).toString());
  } catch(err) {
    data = {};
  }
}

load();

function save() {
  fs.writeFileSync(PATH, JSON.stringify(data, 2, 2));
}

function ensureCollection(appID, collection) {
  data[appID] = data[appID] || {};
  data[appID][collection] = data[appID][collection] || [];
  return data[appID][collection];
}

function generateID() {
  return Math.random().toString().substring(2);
}

module.exports.get = function(options, callback) {
  console.error('options', options);
  var collection = data[options.appID] && data[options.appID][options.collection];
  console.error('collection', collection);
  if (!collection) return callback();
  if (options.filter) collection = sift(options.filter, collection);
  callback(null, collection);
};

module.exports.insert = function(options, callback) {
  var collection = ensureCollection(options.appID, options.collection);
  var object = options.object;
  object._id = generateID();
  var d = new Date().toISOString();
  object._createdAt = d;
  object._updatedAt = d;
  collection.push(object);
  save();
  callback(null, object);
};

module.exports.update = function(options, callback) {
  var _id = options._id || options.object._id;
  delete options.object._id;
  options.object._updateAt = new Date().toISOString();
  var operation = {$set: options.object};
  var filter = {_id: _id};

  var collection = ensureCollection(options.appID, options.collection);
  fiddle(operation, filter, collection);
  var items = sift(filter, collection);

  save();
  if (!(items && items.length === 1)) {
    return callback();
  }
  callback(null, items[0]);
};

module.exports.updateMulti = function(options, callback) {
  async.forEach(options.objects, function(object, cbObject) {
    module.exports.update({
      appID: options.appID,
      collection: options.collection,
      object: object
    }, cbObject);
  }, callback);
};

module.exports.delete = function(options, callback) {
  var collection = ensureCollection(options.appID, options.collection);
  var filter = {_id: options._id};
  var items = sift(filter, collection);

  if (!items || items.length < 1) {
    return callback('not found');
  }

  var item = items[0];

  var index = collection.indexOf(item);

  delete collection[index];
  save();
  callback();
};
