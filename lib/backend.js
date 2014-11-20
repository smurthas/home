var url = require('url');

var request = require('request');
var _ = require('lodash');
var sift = require('sift');
var fiddle = require('fiddle');
var async = require('async');
var uuid = require('uuid');

var persistence = require('./persistence/' + (process.env.PERSISTENCE || 'fs'));

var data;

function ensureApp(appID) {
  data[appID] = data[appID] || {};
  data[appID].meta = data[appID].meta || {};
  data[appID].accounts = data[appID].accounts || {};
  return data[appID];
}

function getAccount(appID, accountID) {
  return data[appID] && data[appID].accounts &&
    data[appID].accounts[accountID];
}

function getCollections(appID, accountID) {
  return data[appID] && data[appID].accounts &&
    data[appID].accounts[accountID] &&
    data[appID].accounts[accountID].collections;
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

function followPointer(_pointer, callback) {
  request.get({
    uri: _pointer,
    json: true
  }, function(err, resp, body) {
    if (err) return callback(err);
    if (!resp) return callback({
      noResponse: body || true
    });

    if (resp.statusCode !== 200) {
      return callback({
        code: resp.statusCode
      });
    }

    return callback(null, body);
  });
}

var generateID = uuid.v4;


function ensureIdentity(publicKey) {
  data._identities = data._identities || {};
  data._identities[publicKey] = data._identities[publicKey] || {};
  data._identities[publicKey]._grants = data._identities[publicKey]._grants || {};
  return data._identities[publicKey];
}

function addGrantToIdentity(publicKey, grantID) {
  var identityExists = data._identities[publicKey] &&
    data._identities[publicKey]._grants;
  if (!identityExists) return false;
  data._identities[publicKey]._grants[grantID] = {};
  return true;
}

//
// Grant management functions
//

module.exports.getGrantsForIdentity = function(publicKey) {
  var grants = [publicKey];
  if (!(data._identities && data._identities[publicKey] && data._identities[publicKey]._grants)) return grants;

  Object.keys(data._identities[publicKey]._grants).forEach(function(grantID) {
    grants.push(grantID);
  });

  return grants;
};

function filterWithRequiredPermissions(objects, grantIDs, requiredPermissions) {
  if (!objects || !objects.length) return objects;
  if (!grantIDs || !grantIDs.length) return [];
  if (!requiredPermissions || !requiredPermissions.length) return objects;


  var withPermission = [];
  objects.forEach(function(object) {
    var objectPermissions = getPermissions(object, grantIDs);
    for (var i in requiredPermissions) {
      if (!objectPermissions[requiredPermissions[i]]) return;
    }
    withPermission.push(object);
  });

  return withPermission;
}

function getPermissions(object, grantIDs) {
  var permissions = {};
  if (!(grantIDs && grantIDs.length >= 1)) return permissions;

  var objectGrants = object && (object._grants || (object.meta && object.meta._grants));
  if (!objectGrants) return permissions;

  grantIDs.forEach(function(grantID) {
    var thesePermissions = objectGrants[grantID];
    if (!thesePermissions) return;
    for (var permission in thesePermissions) {
      permissions[permission] = permissions[permission] ||
        thesePermissions[permission];
    }
  });

  return permissions;
}

//
// Identity management functions
//

module.exports.addGrantToIdentity = function(options, callback) {
  // can only modify self or grants we are a part of
  if (!options.grantIDs[options.publicKey] && !options.grantIDs[options.grantID]) {
    return callback({
      unauthorized: options.publicKey
    });
  }

  addGrantToIdentity(options.publicKey, options.grantID);

  persistence.save(data);

  return callback();
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

  persistence.save(data);

  return callback(null, id);
};

function updateIdentity(identity, options) {
  identity._accountID = options.accountID;
  identity._baseUrl = options.baseUrl;
  identity._appData = identity._appData || {};
  for (var appName in options.appData) {
    var appData = identity._appData[appName] = identity._appData[appName] || {};
    for (var appDataKey in options.appData) {
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


  var identity = ensureIdentity(options.publicKey);
  for (var key in temporaryIdentity) {
    identity[key] = temporaryIdentity[key];
  }

  console.error('creating or updating identity with options:', options);

  updateIdentity(identity, options);

  delete data._temporaryIDs[options.temporaryIdentity];

  function replaceGrants(_grants) {
    if (!_grants[options.temporaryIdentity]) return;
    _grants[options.publicKey] = _grants[options.temporaryIdentity];
    delete _grants[options.temporaryIdentity];
  }

  for (var appID in data) {
    // XXX: app namespace is polluted with _identities and _temporaryIDs
    if (appID.indexOf('_') === 0) continue;

    var app = data[appID];
    for (var accountID in app.accounts) {
      var account = app.accounts[accountID];
      replaceGrants(account.meta && account.meta._grants);

      var collections = account.collections;
      for (var collectionID in collections) {
        var collection = collections[collectionID];
        replaceGrants(collection.meta && collection.meta._grants);

        var objects = collection.data;
        objects.forEach(function(obj) {
          replaceGrants(obj._grants);
        });
      }
    }
  }

  persistence.save(data);
  return callback();
};

module.exports.getIdentities = function(options, callback) {
  var identities = {};
  if (options.publicKeys) {
    options.publicKeys.forEach(function(publicKey) {
      identities[publicKey] = data._identities[publicKey] || {
        error: 'not found',
        code: 404
      };
    });
  } else {
    for (var id in data._identities) {
      identities[id] = data._identities[id];
    }
  }

  callback(null, identities);
};

module.exports.getTemporaryIdentities = function(options, callback) {
  var identities = {};
  if (options.tokens) {
    options.tokens.forEach(function(token) {
      identities[token] = data._temporaryIDs[token] || {
        error: 'not found',
        code: 404
      };
    });
  } else {
    for (var id in data._temporaryIDs) {
      identities[id] = data._temporaryIDs[id];
    }
  }

  callback(null, identities);
};

//
// Account management functions
//

module.exports.createAccount = function(options, callback) {
  var app = ensureApp(options.appID);
  var accountID = generateID();
  var account = app.accounts[accountID] = {
    meta: {
      _grants: {}
    },
    collections: {}
  };

  ensureIdentity(options.publicKey);

  var grantID = generateID();

  var grantAdded = addGrantToIdentity(options.publicKey, grantID);
  if (!grantAdded) {
    return callback({
      failed: 'grant'
    });
  }

  account.meta._grants[grantID] = {
    createCollections: true,
    createGrants: true
  };

  persistence.save(data);

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

  var asAccountPerms = accountMeta._grants && accountMeta._grants[options.asAccountID];
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

  persistence.save(data);

  setImmediate(callback);
};

//
// Collection management functions
//

//function hasModifyCollectionPermission(appID, accountID, grantID, collectionID) {
//  var attributes = data[appID] && data[appID].accounts &&
//    data[appID].accounts[accountID] && data[appID].accounts[accountID].meta;
//  if (!attributes) return false;
//
//  var collection = getCollection(appID, accountID, collectionID);
//
//  if (!collection || !collection.meta) return;
//
//  return collection.meta._grants && collection.meta._grants[grantID] &&
//    collection.meta._grants[grantID].modifyAttributes;
//}



module.exports.getCollection = function(options, callback) {
  var collection = getCollection(options.appID, options.accountID, options.collectionID);

  if (!collection) {
    return callback({
      notFound: true
    });
  }

  var attributes = collection.meta;

  if (!attributes._pointer) return setImmediate(finish);

  var pointerURL = url.parse(attributes._pointer);
  pointerURL.pathname += '__attributes';

  followPointer(url.format(pointerURL), function(err, followedAttributes) {
    if (err) return finish(err);

    attributes = followedAttributes;
    attributes._token = require('querystring').parse(pointerURL.query).token;
    return setImmediate(finish);
  });

  function finish(err) {
    if (err) return callback(err);

    if (!attributes) {
      return callback({
        notFound: true
      });
    }

    var permissions = getPermissions(attributes, options.grantIDs);
    if (!permissions.readAttributes) {
      return callback({
        unauthorized: true
      });
    }

    callback(null, attributes);
  }
};

module.exports.getCollections = function(options, callback) {
  var collections = getCollections(options.appID, options.accountID);

  if (!collections) {
    return callback({
      notFound: true
    });
  }

  var collectionsWithPermission = [];
  async.forEach(_.values(collections), function(collection, cbCollection) {
    module.exports.getCollection({
      appID: options.appID,
      accountID: options.accountID,
      grantIDs: options.grantIDs,
      collectionID: collection.meta._id
    }, function(err, collection) {
      if (!err && collection) collectionsWithPermission.push(collection);
      cbCollection();
    });
  }, function() {
    if (options.filter) {
      collectionsWithPermission = sift(options.filter, collectionsWithPermission);
    }

    callback(null, collectionsWithPermission);
  });
};

module.exports.createCollection = function(options, callback) {
  var collections = getCollections(options.appID, options.accountID);
  if (!collections) {
    return callback({
      notFound: true
    });
  }

  var permissions = getPermissions(getAccount(options.appID, options.accountID),
                                   options.grantIDs);
  if (!permissions.createCollections) {
    return callback({
      unauthorized: true
    });
  }

  var collection;
  var collectionID;
  // we might have a collision, so loop until we get an unsed ID, but limit the
  // number of times we try
  for (var i = 0; i < 10; i++) {
    collectionID = generateID();
    if (collections[collectionID]) continue;

    collection = ensureCollection(options.appID, options.accountID, collectionID);
    break;
  }

  // if we got all id collisions something is really wrong, buy a lotto ticket
  if (!collection) {
    return callback({
      failed: true
    });
  }

  options.attributes._createdAt = options.attributes._updatedAt =
    new Date().toISOString();
  options.attributes._host = process.env.HOST;
  options.attributes._accountID = options.accountID;
  var operation = {$set: options.attributes};

  fiddle(operation, null, collection.meta);
  collection.meta._id = collectionID;

  persistence.save(data);

  callback(null, collection.meta);
};

module.exports.upsertCollection = function(options, callback) {
  if (!options.attributes) {
    return callback({
      badInput: 'attributes'
    });
  }

  var collections = getCollections(options.appID, options.accountID);
  if (!collections) {
    return callback({
      notFound: true
    });
  }

  var collection = getCollection(options.appID, options.accountID, options.collectionID);

  if (!collection) {
    var appPermissions = getPermissions(getAccount(options.appID, options.accountID), options.grantIDs);
    if (!appPermissions.createCollections) {
      return callback({
        unauthorized: 'create',
      });
    }

    collection = ensureCollection(options.appID, options.accountID, options.collectionID);
  } else {
    var collectionPermissions = getPermissions(collection, options.grantIDs);
    if (!collectionPermissions.modifyAttributes) {
      return callback({
        unauthorized: 'modify'
      });
    }
  }


  if (!collection) {
    return callback({
      failed: true
    });
  }

  // can't set these from the client
  if (options.attributes && options.attributes._createdAt) delete options.attributes._createdAt;
  options.attributes._id = options.collectionID;
  options.attributes._host = process.env.HOST;
  options.attributes._accountID = options.accountID;

  options.attributes._updatedAt = new Date().toISOString();
  var operation = {$set: options.attributes};

  fiddle(operation, null, collection.meta);
  collection.meta._id = options.collectionID;

  persistence.save(data);

  callback(null, collection.meta);
};

module.exports.deleteCollection = function(options, callback) {
  var collections = getCollections(options.appID, options.accountID);
  if (!collections) {
    return callback({
      notFound: true
    });
  }

  var collection = getCollection(options.appID, options.accountID, options.collectionID);

  if (!collection) {
    return callback({
      notFound: true
    });
  }

  var permissions = getPermissions(collection, options.grantIDs);
  if (!permissions.modifyAttributes) {
    return callback({
      unauthorized: true
    });
  }

  delete collections[options.collectionID];

  persistence.save(data);

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

  persistence.save(data);
  callback(null, collectionMeta);
};*/


//
// Object management functions
//

module.exports.get = function(options, callback) {
  var collection = getCollection(options.appID, options.accountID, options.collectionID);
  if (!collection) return callback();
  //var collectionMeta = collection.meta;
  collection = collection.data;
  if (options.filter) collection = sift(options.filter, collection);

  //var collectionPermissions = getPermissions(collectionMeta, options.grantIDs);
  // objects must be permissioned for this grantID
  collection = filterWithRequiredPermissions(collection, options.grantIDs, ['read']);

  callback(null, collection);
};

module.exports.insert = function(options, callback) {
  var collection = getCollection(options.appID, options.accountID, options.collectionID);

  var permissions = getPermissions(collection, options.grantIDs);
  if (!permissions.createObjects) {
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
  persistence.save(data);
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

  if (!getPermissions(item, options.grantIDs).write) {
    return callback({
      unauthorized: true
    });
  }

  options.object._updatedAt = new Date().toISOString();
  var operation = {$set: _.omit(options.object, ['_createdAt', '_id'])};

  // exists and grant is authorized
  fiddle(operation, null, item);

  persistence.save(data);
  callback(null, item);
};

module.exports.updateMulti = function(options, callback) {
  async.forEach(options.objects, function(object, cbObject) {
    module.exports.update({
      appID: options.appID,
      accountID: options.accountID,
      collectionID: options.collectionID,
      grantIDs: options.grantIDs,
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

  if (!getPermissions(item, options.grantIDs).write) {
    return callback({
      unauthorized: true
    });
  }

  var index = collection.indexOf(item);

  collection.splice(index, 1);
  persistence.save(data);
  callback();
};


module.exports.init = function(callback) {
  persistence.load(function(err, loadedData) {
    if (err) {
      console.error('error loading data!', err);
      return callback(err);
    }

    data = loadedData;
    console.error('loaded data', data);
    callback();
  });
};
