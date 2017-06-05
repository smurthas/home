const path = require('path');
const fs = require('fs');

const sift = require('sift');
const fiddle = require('fiddle');
const uuid = require('uuid');

let persistence;
let data;
var generateID = uuid.v4;
const sorters = {};

function ensureApp(appID) {
  data[appID] = data[appID] || {};
  data[appID].meta = data[appID].meta || {};
  data[appID].accounts = data[appID].accounts || {};
  return data[appID];
}

module.exports.createAccount = function (options, callback) {
  var app = ensureApp(options.appID);
  if (!options.account) {
    return callback({
      invalid: 'account'
    });
  }

  if (options.account._id && app.accounts[options.account._id]) {
    // already exists!
    return callback({
      exists: true
    });
  }

  var accountID = options.account._id || generateID();
  // TODO: check for uniqueness!
  var account = app.accounts[accountID] = {
    meta: options.account,
    collections: {}
  };

  module.exports.ensureIdentity(options.publicKey);

  module.exports.save();

  setImmediate(callback.bind(null, null, {
    _id: accountID
  }));
};

module.exports.getAccounts = function getAccounts(appID) {
  return data[appID] && data[appID].accounts && Object.keys(data[appID].accounts);
}

module.exports.getAccount = function getAccount(appID, accountID) {
  return data[appID] && data[appID].accounts &&
    data[appID].accounts[accountID];
}

module.exports.getCollections = function getCollections(appID, accountID) {
  return data[appID] && data[appID].accounts &&
    data[appID].accounts[accountID] &&
    data[appID].accounts[accountID].collections;
}

module.exports.getCollection = function getCollection(appID, accountID, collectionID) {
  return data[appID] && data[appID].accounts &&
    data[appID].accounts[accountID] &&
    data[appID].accounts[accountID].collections &&
    data[appID].accounts[accountID].collections[collectionID];
};

module.exports.createCollection = function(options, callback) {
  const account = module.exports.getAccount(options.appID, options.accountID);
  const filteredAccounts = sift(options.filter, [account.meta]);
  if (!(filteredAccounts && filteredAccounts.length === 1)) {
    return callback({
      notFound: true
    });
  }

  const collections = module.exports.getCollections(options.appID, options.accountID);
  if (!collections) {
    return callback({
      notFound: true
    });
  }

  let collectionID = options.attributes._id;
  if (collectionID && collections[collectionID]) {
    return callback({
      exists: true
    });
  }

  if (!collectionID) {
    // we might have a collision, so loop until we get an unsed ID, but limit the
    // number of times we try
    for (let i = 0; i < 10; i++) {
      collectionID = generateID();
      if (!collections[collectionID]) {
        break;
      }
    }
  }

  const collection = module.exports.ensureCollection(options.appID, options.accountID, collectionID);

  // if we got all id collisions something is really wrong, buy a lotto ticket
  if (!collection) {
    return callback({
      failed: true
    });
  }

  var operation = { $set: options.attributes };

  fiddle(operation, null, collection.meta);
  collection.meta._id = collectionID;

  module.exports.save();

  callback(null, collection.meta);
};

module.exports.upsertCollection = function(options, callback) {
  var collections = module.exports.getCollections(options.appID, options.accountID);
  if (!collections) {
    return callback({
      notFound: true
    });
  }

  var collection = module.exports.getCollection(options.appID, options.accountID, options.collectionID);

  if (!collection) {
    return module.exports.createCollection(options, callback);
  }

  let filteredCollections = sift(options.filter, [collection.meta]);

  if (!(filteredCollections && filteredCollections.length === 1)) {
    return callback({
      unauthorized: true // TODO: should be notFound?
    });
  }

  var operation = { $set: options.attributes };

  fiddle(operation, null, collection.meta);
  collection.meta._id = options.collectionID;

  module.exports.save();

  callback(null, collection.meta);
};

module.exports.ensureCollection = function ensureCollection(appID, accountID, collectionID) {
  var collections = data[appID].accounts[accountID].collections;
  var collection = collections[collectionID] = collections[collectionID] || {};
  collection.meta = collection.meta || {
    _grants: {}
  };
  collection.data = collection.data || [];
  return collection;
}

module.exports.deleteCollection = function(options, callback) {
  var collection = module.exports.getCollection(options.appID, options.accountID, options.collectionID);

  if (!collection) {
    return callback({
      notFound: true
    });
  }

  let filteredCollections = sift(options.filter, [collection.meta]);

  if (!(filteredCollections && filteredCollections.length === 1)) {
    return callback({
      unauthorized: true // TODO: should be notFound?
    });
  }

  let collections = module.exports.getCollections(options.appID, options.accountID);
  delete collections[options.collectionID];

  module.exports.save();

  callback();
};

module.exports.ensureIdentity = function ensureIdentity(publicKey) {
  data._identities = data._identities || {};
  data._identities[publicKey] = data._identities[publicKey] || {};
  data._identities[publicKey]._grants = data._identities[publicKey]._grants || {};
  return data._identities[publicKey];
}

module.exports.addGrantToIdentity = function addGrantToIdentity(publicKey, grantID) {
  var identityExists = data._identities[publicKey] &&
    data._identities[publicKey]._grants;
  if (!identityExists) return false;
  data._identities[publicKey]._grants[grantID] = {};
  return true;
}

module.exports.getObjects = function(options, callback) {
  var collection = module.exports.getCollection(options.appID, options.accountID, options.collectionID);
  if (!collection) return callback();
  //var collectionMeta = collection.meta;
  collection = collection.data;
  if (options.filter) collection = sift(options.filter, collection);

  if (options.sort) {
    collection = collection.sort(sorters[options.sort.by](options.sort['with']));
  }

  if (options.limit) {
    collection = collection.slice(0, options.limit);
  }

  callback(null, collection);
};

//module.exports.upsertObject

module.exports.updateObject = function(options, callback) {
  let collection = module.exports.getCollection(options.appID, options.accountID, options.collectionID);
  if (!collection || !collection.data) {
    return callback({
      notFound: true
    });
  }

  collection = collection.data;

  var _id = options._id || options.object._id;
  var filter = {
    $and: [
      options.filter,
      { _id: _id }
    ]
  };

  var items = sift(filter, collection);
  if (!(items && items.length === 1)) {
    return callback({
      notFound: true
    });
  }

  var item = items[0];

  var operation = {$set: options.object};

  // exists and grant is authorized
  fiddle(operation, null, item);

  module.exports.save();
  callback(null, item);
};

module.exports.save = function() {
  persistence.save(data);
};

module.exports.getGrantsForIdentity = function(publicKey) {
  var grants = [publicKey];
  if (!(data._identities && data._identities[publicKey] && data._identities[publicKey]._grants)) return grants;

  Object.keys(data._identities[publicKey]._grants).forEach(function(grantID) {
    grants.push(grantID);
  });

  return grants;
};

module.exports.createTemporaryIdentity = function(options, callback) {
  data._temporaryIDs = data._temporaryIDs || {};

  var id;
  // we might have a collision, so loop until we get an unsed ID, but limit the
  // number of times we try
  for (var i = 0; i < 10; i++) {
    id = generateID();
    if (!data._temporaryIDs[id]) {
      data._temporaryIDs[id] = options.attributes;
      break;
    }
    id = null;
  }

  if (!id) {
    return callback({
      failed: 'generating id',
    });
  }

  module.exports.save();

  return callback(null, id);
};

function updateIdentity(identity, options) {
  identity._accountID = options.accountID;
  identity._baseUrl = options.baseUrl;
  identity._appData = identity._appData || {};
  for (var appName in options.appData) {
    var appData = identity._appData[appName] = identity._appData[appName] || {};
    for (var appDataKey in options.appData[appName]) {
      console.error('appDataKey', appDataKey);
      appData[appDataKey] = options.appData[appName][appDataKey];
    }
  }
}

module.exports.createIdentityFromTemporary = function(options, callback) {
  var temporaryIdentity = data._temporaryIDs &&
    data._temporaryIDs[options.temporaryIdentity];

  if (!temporaryIdentity) {
    console.error('temp id not found!');
    return callback({
      notFound: 'temporaryIdentity'
    });
  }


  var identity = module.exports.ensureIdentity(options.publicKey);
  for (var key in temporaryIdentity) {
    identity[key] = temporaryIdentity[key];
  }

  module.exports.addGrantToIdentity(options.publicKey, options.temporaryIdentity);

  console.error('creating or updating identity with options:', options);

  updateIdentity(identity, options);

  delete data._temporaryIDs[options.temporaryIdentity];

  module.exports.save();
  return callback();
};

module.exports.init = function init(options, callback) {
  persistence = options.persistence || require('../persistence/' + (process.env.PERSISTENCE || 'fs'));

  persistence.init({}, function(err) {
    if (err) {
      console.error('error initialzing persistence module!', err);
      return callback(err);
    }

    persistence.load(function(err, loadedData) {
      if (err) {
        console.error('error loading data!', err);
        return callback(err);
      }

      data = loadedData;
      if (options.log) console.error('loaded data', data);

      // load operators
      var operatorNames = fs.readdirSync(path.join(__dirname, '..', 'operators'));
      operatorNames.forEach(function(operatorName) {
        var operator = require(path.join(__dirname, '..', 'operators', operatorName));
        var siftOperator = {
          operators:{}
        };
        siftOperator.operators[operatorName] = operator;
        sift.use(siftOperator);
      });

      // load sorters
      var sorterNames = fs.readdirSync(path.join(__dirname, '..', 'sorters'));
      sorterNames.forEach(function(sorterName) {
        sorters[sorterName] = require(path.join(__dirname, '..', 'sorters', sorterName));
      });

      callback();
    });
  });
};

