var fs = require('fs');

var _ = require('lodash');
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
  collection.meta = collection.meta || {
    _grants: {}
  };
  collection.data = collection.data || [];
  return collection;
}

var generateID = uuid.v4;

//
// Account management functions
//

module.exports.createAccount = function(options, callback) {
  var app = ensureApp(options.appID);
  var accountID = generateID();
  var account = app.accounts[accountID] = {
    meta: {
      grants: {}
    },
    collections: {}
  };

  account.meta.grants[accountID] = {
    createCollections: true,
    createGrants: true
  };

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
  if (!accounts) {
    return callback({
      notFound: 'app'
    });
  }
  var accountMeta = accounts[options.forAccountID] && accounts[options.forAccountID].meta;
  if (!accountMeta) {
    return callback({
      notFound: 'account'
    });
  }

  var asAccountPerms = accountMeta.grants && accountMeta.grants[options.asAccountID];
  var hasPermission = options.isManager || (asAccountPerms && asAccountPerms.createGrants);
  if (!hasPermission) {
    return callback({
      unauthorized: 'createGrants'
    });
  }

  accountMeta.grants[options.toAccountID] = {
    createCollections: options.permissions.createCollections,
    createGrants: options.permissions.createGrants
  };

  save();

  setImmediate(callback);
};

//
// Collection management functions
//

function hasCreateCollectionPermission(appID, accountID, grantID) {
  var attributes = data[appID] && data[appID].accounts &&
    data[appID].accounts[accountID] && data[appID].accounts[accountID].meta;
  if (!attributes) return false;

  return attributes.grants[grantID] &&
    attributes.grants[grantID].createCollections;
}

module.exports.getCollections = function(options, callback) {
  var collections = data[options.appID] && data[options.appID].accounts &&
    data[options.appID].accounts[options.accountID] &&
    data[options.appID].accounts[options.accountID].collections;

  if (!collections) {
    return callback({
      notFound: true
    });
  }

  var collectionMetas = _.pluck(collections, 'meta');
  var grantFilter = { _grants: {} };
  grantFilter._grants[options.grantID] = {$exists:true};
  collectionMetas = sift(grantFilter, collectionMetas);

  if (options.filter) collectionMetas = sift(options.filter, collectionMetas);

  callback(null, collectionMetas);
};

module.exports.createCollection = function(options, callback) {
  var collections = data[options.appID] && data[options.appID].accounts &&
    data[options.appID].accounts[options.accountID] &&
    data[options.appID].accounts[options.accountID].collections;
  if (!collections) {
    return callback({
      notFound: true
    });
  }

  if (!hasCreateCollectionPermission(options.appID, options.accountID, options.grantID)) {
    return callback({
      unauthorized: true
    });
  }

  var collection;
  var collectionID;
  for (var i = 0; i < 10; i++) {
    collectionID = generateID();
    if (collections[collectionID]) continue;

    collection = ensureCollection(options.appID, options.accountID, collectionID);
    break;
  }

  if (!collection) {
    return callback({
      failed: true
    });
  }

  options.attributes._createdAt = options.attributes._updatedAt =
    new Date().toISOString();
  var operation = {$set: options.attributes};

  fiddle(operation, null, collection.meta);
  collection.meta._id = collectionID;

  save();

  callback(null, collection.meta);
};

module.exports.upsertCollection = function(options, callback) {

  callback();
};


/* unused for now
module.exports.updateCollection = function(options, callback) {
  var collectionMeta = ensureCollection(options.appID, options.accountID, options.collectionID).meta;

  if (collectionMeta.grants.indexOf(options.grantID) === -1) {
    return callback({
      unauthorized: true
    });
  }
  fiddle(options.operation, null, collectionMeta);

  save();
  callback(null, collectionMeta);
};*/


//
// Object management functions
//

module.exports.get = function(options, callback) {
  var collection = getCollection(options.appID, options.accountID, options.collectionID);
  if (!collection) return callback();
  collection = collection.data;
  if (options.filter) collection = sift(options.filter, collection);

  // objects must be permissioned for this grantID
  collection = sift({_grants: {$all: [options.grantID]}}, collection);

  callback(null, collection);
};

module.exports.insert = function(options, callback) {
  var collection = getCollection(options.appID, options.accountID, options.collectionID);

  var permissions = collection && collection.meta && collection.meta._grants[options.grantID];
  if (!permissions || !permissions.createObjects) {
    // check if grant has createCollections permission
    var account = data[options.appID] && data[options.appID].accounts &&
      data[options.appID].accounts[options.accountID];
    var appPermissions = account && account.meta && account.meta.grants &&
      account.meta.grants[options.accountID];

    if (!appPermissions || !appPermissions.createCollections) {
      // no app or collection perms
      return callback({
        unauthorized: true
      });
    }
  }

  if (!collection) {
    // if we've made it this far, either the collection exists, or we have
    // permission to create it
    collection = ensureCollection(options.appID, options.accountID, options.collectionID);
  }

  // ensure this grant has permission to createObjects
  collection.meta._grants[options.grantID] = collection.meta._grants[options.grantID] || {};
  collection.meta._grants[options.grantID].createObjects = true;

  var object = options.object;
  object._id = generateID();
  var d = new Date().toISOString();
  object._createdAt = d;
  object._updatedAt = d;
  collection.data.push(object);
  save();
  callback(null, object);
};

module.exports.update = function(options, callback) {
  var collection = getCollection(options.appID, options.accountID, options.collectionID);
  if (!collection || !collection.data) {
    return callback({
      notFound: true
    });
  }

  collection = collection.data;

  var _id = options._id || options.object._id;
  var filter = {_id: _id};

  var items = sift(filter, collection);
  if (!(items && items.length === 1)) {
    return callback({
      notFound: true
    });
  }

  var item = items[0];

  var hasWritePermission = item._grants && item._grants[options.grantID] && item._grants[options.grantID].write;
  if (!hasWritePermission) {
    return callback({
      unauthorized: true
    });
  }

  options.object._updatedAt = new Date().toISOString();
  var operation = {$set: _.omit(options.object, ['_createdAt', '_id'])};

  // exists and grant is authorized
  fiddle(operation, null, item);

  save();
  callback(null, item);
};

module.exports.updateMulti = function(options, callback) {
  async.forEach(options.objects, function(object, cbObject) {
    module.exports.update({
      appID: options.appID,
      collectionID: options.collectionID,
      grantID: options.grantID,
      object: object
    }, cbObject);
  }, callback);
};

module.exports.delete = function(options, callback) {
  var collection = ensureCollection(options.appID, options.accountID, options.collectionID).data;
  var filter = {_id: options._id};
  var items = sift(filter, collection);

  if (!items || items.length < 1) {
    return callback({
      notFound: true
    });
  }

  var item = items[0];

  var hasWritePermission = item._grants && item._grants[options.grantID] && item._grants[options.grantID].write;

  if (!hasWritePermission) {
    return callback({
      unauthorized: true
    });
  }

  var index = collection.indexOf(item);

  delete collection[index];
  save();
  callback();
};
