var express = require('express');

var backend = require('./lib/backend.js');
var tokens = require('./lib/tokens.js');

var app = express();

app.use(function(req, res, next) {
  console.log(req.method, req.path);
  next();
});

app.use(require('cors')());

app.use(function(req, res, next) {
  req.rawBody = '';
  req.on('data', function(chunk) {
    req.rawBody += chunk;
  });
  next();
});

app.use(require('body-parser').json());


// Helpers


function handleError(err, res) {
  console.error('HANDLE ERROR', err);
  if (err) {
    if (err.notFound) {
      return res.status(404).json({
        type: err.notFound
      });
    }
    if (err.unauthorized) {
      return res.status(401).json({
        type: err.unauthorized
      });
    }
  }

  return res.status(500).json({});
}

app.post('/auth/manager_requests', function(req, res) {
  var secondFactorToken = 12345;
  var token = tokens.generateToken(secondFactorToken);
  res.json({
    request_token: token
  });
});

app.post('/auth/managers', function(req, res) {
  var secondFactorToken = req.body.second_factor_token;
  var requestToken = tokens.verifyToken(req.body.request_token);

  if (!requestToken || !requestToken._id || requestToken._id !== secondFactorToken) {
    return res.status(401).end();
  }

  var password = req.body.password;
  tokens.verifyPassword(password, function(err, success) {
    if (err) return res.status(400).json({
      error: err
    });
    if (!success) return res.status(401).end();

    // return a usable token
    res.status(201).json({
      manager_token: tokens.generateManagerToken()
    });
  });
});

// this is a manager creating account tokens
app.post('/auth/tokens', function(req, res) {
  var managerToken = req.body.manager_token;
  var pubKey = req.body.pub_key;

  if (!managerToken || !pubKey) {
    return res.status(400).end();
  }

  if (!tokens.verifyManagerToken(managerToken)) {
    return res.status(401).json({
      message: 'invalid token'
    });
  }

  var token = tokens.generateToken(pubKey);

  res.status(200).json({
    token: token
  });
});



//
// Auth verification functions
//
function validManager(req) {
  var tokenString = req.query.manager_token || req.body.manager_token;
  return tokens.verifyManagerToken(tokenString);
}

function verifyManagerAuth(req, res, next) {
  if (!validManager(req)) return res.status(400).end();
  next();
}

function verifyAuth(req, res, next) {
  if (validManager(req)) {
    req.isManager = true;
    return next();
  }

  var signature = req.header('X-Slab-Signature');
  var publicKey = req.header('X-Slab-PublicKey');
  var reqURL = 'http://' + req.headers.host + req.originalUrl;
  var message = req.method.toUpperCase() + '\n' +  reqURL + '\n' + req.rawBody;
  var verified = tokens.verifySignature(message, signature, publicKey);


  if (verified) {
    req.grantIDs = backend.getGrantsForIdentity(publicKey);
    return next();
  }

  var token = req.query.token;
  if (!token && req.headers.Authorization) {
    try {
      token = req.headers.Authorization.trim().substring(5).trim().split('=')[1];
    } catch(e) {
      return res.status(400).end();
    }
  }

  if (!token || !token.length) {
    return res.status(400).end();
  }

  token = tokens.verifyToken(token);
  if (!token || !token._id)  return res.send(400);

  req.grantID = token._id;

  next();
}

//
// Identity management endpoints
//

// add a grantID to an identity
app.put('/identities/:publicKey/_grantsID/:grantID', verifyAuth, function(req, res) {
  backend.addGrantToIdentity({
    publicKey: req.params.publicKey,
    grantID: req.params.grantID,
    grantIDs: req.grantIDs
  }, function(err) {
    if (err) handleError(err, res);

    return res.json({});
  });
});

// create a temporary identity
app.post('/identities/__temp', verifyAuth, function(req, res) {
  backend.createTemporaryIdentity({
    attributes: req.body,
    grantIDs: req.grantIDs
  }, function(err, temporaryIdentity) {
    if (err) return handleError(err, res);

    return res.status(201).json({
      temporary_id: temporaryIdentity
    });
  });
});

app.get('/identities/__temp/:tokens', verifyAuth, function(req, res) {
  var tokens = req.params.tokens;
  if (!tokens) {
    return handleError(null, res);
  }

  if (tokens.indexOf(',') === -1) tokens = [tokens];
  else tokens = tokens.split(',');

  backend.getTemporaryIdentities({
    tokens: tokens,
    grantIDs: req.grantIDs
  }, function(err, temporaryIdentities) {
    if (err) return handleError(err, res);

    res.status(200).json(temporaryIdentities);
  });
});

// create a new identity from a temporary identity
app.put('/identities/:publicKey', verifyAuth, function(req, res) {
  console.error('Convert Temporary ID:', req.body);
  backend.createIdentityFromTemporary({
    temporaryIdentity: req.body.temporary_id,
    accountID: req.body.account_id,
    baseUrl: req.body.base_url,
    appData: req.body.app_data,
    publicKey: req.params.publicKey
  }, function(err) {
    if (err) return handleError(err, res);

    res.status(200).json({});
  });
});

// get all identities
app.get('/identities', verifyAuth, function(req, res) {
  backend.getIdentities({
    grantIDs: req.grantIDs
  }, function(err, identities) {
    if (err) return handleError(err, res);

    res.status(200).json(identities);
  });

});

// get identities by public key
app.get('/identities/:publicKeys', verifyAuth, function(req, res) {
  var publicKeys = req.params.publicKeys;
  if (!publicKeys) {
    return handleError(null, res);
  }

  if (publicKeys.indexOf(',') === -1) publicKeys = [publicKeys];
  else publicKeys = publicKeys.split(',');

  backend.getIdentities({
    publicKeys: publicKeys,
    grantIDs: req.grantIDs
  }, function(err, identities) {
    if (err) return handleError(err, res);

    res.status(200).json(identities);
  });
});


// App and account management endpoints

// Create a new account for an app
app.post('/apps/:appID', verifyManagerAuth, function(req, res) {
  backend.createAccount({
    appID: req.params.appID,
    publicKey: req.body.public_key,
    //accountName: req.body.accountName,
  }, function(err, account) {
    if (err) return handleError(err, res);

    console.error('account', account);
    res.status(201).json({
      account_id: account._id
    });
  });
});

// Create a new grant for an account
app.post('/apps/:appID/:accountID/__temp_grants', verifyAuth, function(req, res) {
  backend.createGrantForAccount({
    appID: req.params.appID,
    isManager: req.isManager,
    grantIDs: req.grantIDs,
    forAccountID: req.params.accountID
  }, function(err) {
    if (err) return res.status(500).json({msg:err});

    var token = tokens.generateToken(req.body.to_account_id);

    res.status(201).json({
      token: token
    });
  });
});

// Get list of apps
app.get('/apps', verifyManagerAuth, function(req, res) {
  backend.getApps({}, function(err, apps) {
    if (err) return handleError(err, res);
    res.status(200).json(apps);
  });
});

// Get list of accounts for an app
app.get('/apps/:appID', verifyManagerAuth, function(req, res) {
  backend.getAccounts({
    appID: req.params.appID
  }, function(err, accounts) {
    if (err) return res.status(500).end();
    res.status(200).json(accounts);
  });
});

app.use('/apps', verifyAuth);


// Collection management endpoints

// get one collection's attributes
app.get('/apps/:appID/:accountID/:collectionID/__attributes', function(req, res) {
  console.error('Get Collection:', req.params);
  backend.getCollection({
    appID: req.params.appID,
    accountID: req.params.accountID,
    collectionID: req.params.collectionID,
    grantIDs: req.grantIDs
  }, function(err, collection) {
    if (err) {
      if (err.notFound) {
        return res.status(404).json({
          message: 'account or app not found'
        });
      } else if (err.unauthorized) {
        return res.status(401).json({
          message: 'not authorized to access that account or app.'
        });
      } else {
        return res.status(500);
      }
    }

    res.status(200).json(collection);
  });
});


// get collections' attributes
app.get('/apps/:appID/:accountID', function(req, res) {
  console.error('Get Collections:', req.query);
  backend.getCollections({
    appID: req.params.appID,
    accountID: req.params.accountID,
    grantIDs: req.grantIDs,
    filter: req.query.filter && JSON.parse(req.query.filter)
  }, function(err, collections) {
    if (err) {
      if (err.notFound) {
        return res.status(404).json({
          message: 'account or app not found'
        });
      } else if (err.unauthorized) {
        return res.status(401).json({
          message: 'not authorized to access that account or app.'
        });
      } else {
        return res.status(500);
      }
    }

    res.status(200).json(collections);
  });
});

// create a collection with an auto-generated ID.
// this is optional, as an object can just be inserted by a app-root account and
// it will lazily be created with 'createObject' permissions for that account
app.post('/apps/:appID/:accountID', function(req, res) {
  console.error('Create Collection:', req.body);
  backend.createCollection({
    appID: req.params.appID,
    accountID: req.params.accountID,
    grantIDs: req.grantIDs,
    attributes: req.body.attributes
  }, function(err, collectionAttributes) {
    if (err) return handleError(err, res);
    res.status(201).json(collectionAttributes);
  });
});

// create or update a collection with a specified ID.
// this is optional, as an object can just be inserted by a app-root account and
// it will lazily be created with 'createObject' permissions for that account
app.put('/apps/:appID/:accountID/:collectionID', function(req, res) {
  console.error('Upsert Collection:', req.body);
  backend.upsertCollection({
    appID: req.params.appID,
    accountID: req.params.accountID,
    collectionID: req.params.collectionID,
    grantIDs: req.grantIDs,
    attributes: req.body
  }, function(err, response) {
    if (err) {
      console.error('upsert coll err', err);
    }
    if (err) return res.status(500).json({err: err});
    res.status(201).json(response);
  });
});


// delete a collection
app.delete('/apps/:appID/:accountID/:collectionID', function(req, res) {
  backend.deleteCollection({
    appID: req.params.appID,
    accountID: req.params.accountID,
    collectionID: req.params.collectionID,
    grantIDs: req.grantIDs
  }, function(err) {
    if (err) return handleError(err, res);
    res.status(200).json({});
  });
});

// update the collection's meta data (ACL, etc?)
/*app.put('/apps/:appID/:accountID/:collectionID', function(req, res) {
  console.error('Create One:', req.body);
  backend.insert({
    appID: req.params.appID,
    accountID: req.params.accountID,
    collectionID: req.params.collectionID,
    object: req.body
  }, function(err, response) {
    if (err) return res.jsonError(500, 'didnt work', 'not sure why');
    res.status(201).json(response);
  });
});*/



// Object management endpoints

// read many
app.get('/apps/:appID/:accountID/:collectionID', function(req, res) {
  console.error('Read Many:', req.query.filter);
  backend.get({
    appID: req.params.appID,
    accountID: req.params.accountID,
    collectionID: req.params.collectionID,
    grantIDs: req.grantIDs,
    filter: req.query.filter && JSON.parse(req.query.filter)
  }, function(err, data) {
    if (err) return handleError(err, res);
    console.error('Read Many resp:', data.length);
    if (!data) return res.status(200).json([]);
    res.json(data);
  });
});


// create one
app.post('/apps/:appID/:accountID/:collectionID', function(req, res) {
  console.error('Create One:', req.body);
  backend.insert({
    appID: req.params.appID,
    accountID: req.params.accountID,
    collectionID: req.params.collectionID,
    grantIDs: req.grantIDs,
    object: req.body
  }, function(err, response) {
    if (err) return handleError(err, res);
    res.status(201).json(response);
  });
});


// update many
app.put('/apps/:appID/:accountID/:collectionID/__batch', function(req, res) {
  console.error('Update Many:', req.body);
  backend.updateMulti({
    appID: req.params.appID,
    accountID: req.params.accountID,
    collectionID: req.params.collectionID,
    grantIDs: req.grantIDs,
    objects: req.body
  }, function(err, response) {
    if (err) {
      console.error('err', err);
    }
    if (err) return res.status(500).json({
      err: err
    });
    res.json(response);
  });
});


// upsert one
app.put('/apps/:appID/:accountID/:collectionID/:objectID', function(req, res) {
  console.error('Upsert One:', req.body);
  backend.insert({
    appID: req.params.appID,
    accountID: req.params.accountID,
    collectionID: req.params.collectionID,
    grantIDs: req.grantIDs,
    _id: req.params.objectID,
    object: req.body
  }, function(err, response) {
    if (err) {
      if (err.notFound) return res.status(404).end();
      if (err.unauthorized) return res.status(401).end();
      return res.status(500).json({err:err});
    }

    res.json(response);
  });
});


// delete one
app.delete('/apps/:appID/:accountID/:collectionID/:objectID', function(req, res) {
  console.error('Delete One:', req.params.objectID);
  backend.delete({
    appID: req.params.appID,
    accountID: req.params.accountID,
    collectionID: req.params.collectionID,
    grantIDs: req.grantIDs,
    _id: req.params.objectID,
  }, function(err) {
    if (err) {
      console.error('err', err);
      return res.status(500).json({err:err});
    }
    res.status(204).end();
  });
});

tokens.initSecrets();

backend.init({}, function(err) {
  if (err) {
    console.error('Error initing backend:', err);
    process.exit(1);
  }

  var PORT = process.env.PORT || 2570;
  app.listen(PORT, function(err) {
    if (err) {
      console.error(err);
      process.exit(1);
    }
    console.log('listening on', PORT);
  });
});
