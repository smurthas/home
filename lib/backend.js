var url = require('url');
var fs = require('fs');
var path = require('path');

var request = require('request');
var _ = require('lodash');
var sift = require('sift');
var fiddle = require('fiddle');
var async = require('async');
var uuid = require('uuid');

var sorters = {};

const dal = require('./dal/memory');

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

//
// Grant management functions
//

module.exports.getGrantsForIdentity = function(publicKey) {
  return dal.getGrantsForIdentity(publicKey);
};

function permissionsFilterForGrantIDs(grantIDs, permissions) {
  // TODO: what happens if no grant ids or no permissions?
  if (typeof permissions === 'string') {
    permissions = [permissions];
  }
  return {
    $or: grantIDs.map(grantID => {
      let obj = { _grants: {} };
      obj._grants[grantID] = {};
      permissions.forEach(perm => {
        obj._grants[grantID][perm] = true;
      });
      return obj;
    }),
  };

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

  dal.addGrantToIdentity(options.publicKey, options.grantID);

  dal.save();

  return callback();
};

module.exports.createTemporaryIdentity = function(options, callback) {
  dal.createTemporaryIdentity(options, callback);
};

module.exports.createIdentityFromTemporary = function(options, callback) {
  dal.createIdentityFromTemporary(options, callback);
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
  options.account = { _grants: {} };
  options.account._grants[options.publicKey] = {
    createCollections: true,
    createGrants: true,
  };

  dal.createAccount(options, callback);
};

module.exports.getApps = function(options, callback) {
  return callback(null, Object.keys(data));
};

module.exports.getAccounts = function(options, callback) {
  callback(null, dal.getAccounts(options.appID));
};

/*module.exports.createGrantForAccount = function(options, callback) {
  var accounts = dal.getAccounts(options.appID);
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

  dal.save();

  setImmediate(callback);
};*/

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
  var collection = dal.getCollection(options.appID, options.accountID, options.collectionID);

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
  var collections = dal.getCollections(options.appID, options.accountID);

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
  options.filter = permissionsFilterForGrantIDs(options.grantIDs, 'createCollections');
  options.attributes = options.attributes || {};
  options.attributes._createdAt = options.attributes._updatedAt =
    new Date().toISOString();
  options.attributes._host = process.env.HOST;
  options.attributes._accountID = options.accountID;

  dal.createCollection(options, callback);
};

module.exports.upsertCollection = function(options, callback) {
  const createFilter = permissionsFilterForGrantIDs(options.grantIDs, 'createCollections');
  const modifyFilter = permissionsFilterForGrantIDs(options.grantIDs, 'modifyAttributes');
  options.filter = { $or: createFilter.$or.concat(modifyFilter.$or) };
  if (!options.attributes) {
    return callback({
      badInput: 'attributes'
    });
  }

  // can't set these from the client
  if (options.attributes && options.attributes._createdAt) delete options.attributes._createdAt;
  options.attributes._id = options.collectionID;
  options.attributes._host = process.env.HOST;
  options.attributes._accountID = options.accountID;

  options.attributes._updatedAt = new Date().toISOString();

  dal.upsertCollection(options, callback);
};

module.exports.deleteCollection = function(options, callback) {
  options.filter = permissionsFilterForGrantIDs(options.grantIDs, 'modifyAttributes');
  dal.deleteCollection(options, callback);
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

  dal.save();
  callback(null, collectionMeta);
};*/


//
// Object management functions
//

module.exports.get = function(options, callback) {
  let permissionsFilter = {
    $or: options.grantIDs.map((grantID) => {
      let obj = { _grants: {} };
      obj._grants[grantID] = { read: true };
      return obj;
    }),
  };

  if (options.filter) {
    options.filter = {
      $and: [
        permissionsFilter,
        options.filter,
      ]
    };
  } else {
    options.filter = permissionsFilter;
  }

  dal.getObjects(options, callback);
};

module.exports.insert = function(options, callback) {
  var _id = options._id || options.object._id;
  if (_id) {
    module.exports.update(options, function(err, resp) {
      if (err && err.notFound) return finishInsert(_id);
      callback(err, resp);
    });
  } else {
    finishInsert();
  }

  function finishInsert(withID) {
    var collection = dal.getCollection(options.appID, options.accountID, options.collectionID);

    var permissions = getPermissions(collection, options.grantIDs);
    if (!permissions.createObjects) {
      // check if grant has createCollections permission
      var account = dal.getAccount(options.appID, options.accountID);
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
      collection = dal.ensureCollection(options.appID, options.accountID, options.collectionID);
    }

    // ensure this grant has permission to createObjects
    var grantID = options.grantIDs && options.grantIDs[0];
    if (grantID) {
      collection.meta._grants[grantID] = collection.meta._grants[grantID] || {};
      collection.meta._grants[grantID].createObjects = true;
    }

    var object = options.object;
    object._id = withID || generateID();
    var d = new Date().toISOString();
    object._createdAt = d;
    object._updatedAt = d;
    collection.data.push(object);
    dal.save();
    callback(null, object);
  }
};

module.exports.update = function(options, callback) {
  let permissionsFilter = {
    $or: options.grantIDs.map((grantID) => {
      let obj = { _grants: {} };
      obj._grants[grantID] = { write: true };
      return obj;
    }),
  };

  options.filter = permissionsFilter;

  options._id = options._id || options.object._id;
  options.object._updatedAt = new Date().toISOString();
  delete options.object._createdAt;
  delete options.object._id;
  // TODO: drop/enforce grant changing?
  dal.updateObject(options, callback);
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
  var collection = dal.ensureCollection(options.appID, options.accountID, options.collectionID).data;
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
  dal.save();
  callback();
};


module.exports.init = function(options, callback) {
  dal.init(options, callback);
};

