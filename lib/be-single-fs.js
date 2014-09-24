var fs = require('fs');

var sift = require('sift');
var fiddle = require('fiddle');
var async = require('async');
var uuid = require('uuid');


var PATH = process.env.BE_HOME_FILE || './home.json';

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

function ensureApp(appID) {
  data[appID] = data[appID] || {};
  data[appID].meta = data[appID].meta || {};
  data[appID].accounts = data[appID].accounts || {};
  return data[appID];
}

function getCollection(appID, accountID, collectionID) {
  return data[appID] && data[appID].accounts &&
    data[appID].accounts[accountID] &&
    data[appID].accounts[accountID].collections &&
    data[appID].accounts[accountID].collections[collectionID];
}

function ensureCollection(appID, accountID, collectionID) {
  var collections = data[appID].accounts[accountID].collections;
  var collection = collections[collectionID] = collections[collectionID] || {};
  collection.meta = collection.meta || {};
  collection.data = collection.data || [];
  return collection;
}

function generateID() {
  return uuid.v4();
}


module.exports.createAccount = function(options, callback) {
  var app = ensureApp(options.appID);
  var accountID = generateID();
  var account = app.accounts[accountID] = {
    meta: {
      grants: []
    },
    collections: {}
  };

  account.meta.grants.push({
    _id: options.grantID
  });

  save();

  setImmediate(callback.bind(null, null, {
    _id: accountID
  }));
};

module.exports.getAccounts = function(options, callback) {
  var accounts = data[options.appID] && data[options.appID].accounts;
  if (!accounts) return callback();
  return callback(null, Object.keys(accounts));
};

module.exports.createGrantForAccount = function(options, callback) {
  var accounts = data[options.appID] && data[options.appID].accounts;
  if (!accounts) return callback('invalid app');
  var account = accounts[options.accountID] && accounts[options.accountID].meta;
  if (!account) return callback('invalid account');

  account.grants.push({
    _id: options.grantID
  });

  save();

  setImmediate(callback);
};

module.exports.get = function(options, callback) {
  var collection = getCollection(options.appID, options.accountID, options.collectionID);
  if (!collection) return callback();
  collection = collection.data;
  if (options.filter) collection = sift(options.filter, collection);
  callback(null, collection);
};

module.exports.insert = function(options, callback) {
  var collection = ensureCollection(options.appID, options.accountID, options.collectionID).data;
  var object = options.object;
  object._id = generateID();
  var d = new Date().toISOString();
  object._createdAt = d;
  object._updatedAt = d;
  collection.push(object);
  save();
  callback(null, object);
};

module.exports.updateCollection = function(options, callback) {
  var collectionMeta = ensureCollection(options.appID, options.accountID, options.collectionID).meta;
  fiddle(options.operation, null, collectionMeta);

  save();
  callback(null, collectionMeta);
};

module.exports.update = function(options, callback) {
  var _id = options._id || options.object._id;
  delete options.object._id;
  options.object._updateAt = new Date().toISOString();
  var operation = {$set: options.object};
  var filter = {_id: _id};

  var collection = ensureCollection(options.appID, options.accountID, options.collectionID).data;
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
  var collection = ensureCollection(options.appID, options.accountID, options.collectionID).data;
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
