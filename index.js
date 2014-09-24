var qs = require('querystring');
var url = require('url');

var express = require('express');
var uuid = require('uuid');

var backend = require('./lib/be-single-fs.js');
var tokens = require('./lib/tokens.js');

var app = express();

app.use(require('cors')());
app.use(require('body-parser').json());

var MY_URL = 'http://localhost:2570';

app.use('/', function(req, res, next) {
  res.jsonError = function(status, message, details) {
    res.json(status, {
      message: message,
      details: details
    });
  };

  next();
});



function verifyAuth(req, res, next) {
  var token = req.query.token;
  if (!token && req.headers.Authorization) {
    try {
      token = req.headers.Authorization.trim().substring(5).trim().split('=')[1];
    } catch(e) {
      return res.status(400).end();
    }
  }

  if (!token && token.length) {
    return res.status(400).end();
  }

  token = tokens.verifyToken(token);
  if (!token || !token._id)  return res.send(401);

  req.grantID = token._id;

  next();
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


app.get('/authstart', function(req, res) {
  var redirectURI = req.query.redirect_uri;
  var proveURI = req.query.prove_uri;

  var rdURI = url.parse(redirectURI);
  var pURI = url.parse(proveURI, true);

  if (rdURI.host !== pURI.host) {
    return res.jsonErr(500, 'non-matching redirect URI and prove URI hosts', 'blargh');
  }

  var nonce = tokens.generateToken(redirectURI);

  pURI.query.nonce = nonce;
  pURI.query.redirect_uri = MY_URL + '/authproved';
  res.redirect(url.format(pURI));
});

app.get('/authproved', function(req, res) {
  var nonce = req.query.nonce;
  var sig = req.query.signature;
  var pubkey = req.query.public_key;

  var redirectURI = tokens.verifySignature(nonce, sig, pubkey);
  if (!redirectURI) {
    return res.jsonErr(500, 'bad sig', {
      nonce: nonce,
      signature: sig,
      public_key: pubkey,
      redirect_uri: redirectURI
    });
  }

  var temporaryToken = tokens.generateTemporaryToken(redirectURI, pubkey);

  var confirmURL = MY_URL + '/authcomplete?temp_token=' + temporaryToken;
  return res.send('<html><body><a href="' + confirmURL + '">Authorize ' + pubkey + '</a></body></html>');

});

app.get('/authcomplete', function(req, res) {
  var verification = tokens.verifyTemporaryToken(req.query.temp_token);
  if (!verification || !verification.pubkey || !verification.redirectURI) {
    res.jsonErr(500, 'bad temp token', verification);
  }

  var token = tokens.generateToken(verification.pubkey);

  verification.redirectURI += '?' + qs.stringify({token:token});
  res.redirect(verification.redirectURI);
});

// Create a new account for an app
app.post('/apps/:appID', function(req, res) {
  var managerToken = tokens.verifyManagerToken(req.query.manager_token || req.body.manager_token);
  if (!managerToken) return res.status(401).end();

  var grantID = uuid.v4();
  var token = tokens.generateToken(grantID);

  backend.createAccount({
    appID: req.params.appID,
    accountName: req.body.accountName,
    grantID: grantID
  }, function(err, account) {
    if (err) return res.status(500).end();

    res.status(201).json({
      account: account._id,
      token: token
    });
  });
});

// Create a new grant for an account
app.post('/apps/:appID/:accountID/__grants', function(req, res) {
  var managerToken = tokens.verifyManagerToken(req.query.manager_token || req.body.manager_token);
  if (!managerToken) return res.status(401).end();

  var grantID = uuid.v4();
  var token = tokens.generateToken(grantID);

  backend.createGrantForAccount({
    appID: req.params.appID,
    accountID: req.params.accountID,
    grantID: grantID
  }, function(err) {
    if (err) return res.status(500).json({msg:err});

    res.status(201).json({
      token: token
    });
  });
});

// Get list of accounts for an app
app.get('/apps/:appID', function(req, res) {
  var managerToken = tokens.verifyManagerToken(req.query.manager_token || req.body.manager_token);
  if (!managerToken) return res.status(401).end();

  backend.getAccounts({
    appID: req.params.appID
  }, function(err, accounts) {
    if (err) return res.status(500).end();
    res.status(200).json(accounts);
  });
});

app.use('/apps', verifyAuth);

// CRUDy endpoints

// read many
app.get('/apps/:appID/:accountID/:collectionID', function(req, res) {
  console.error('Read Many:', req.query.filter);
  backend.get({
    appID: req.params.appID,
    accountID: req.params.accountID,
    collectionID: req.params.collectionID,
    filter: req.query.filter && JSON.parse(req.query.filter)
  }, function(err, data) {
    if (err) return res.jsonError(500, 'didnt work', 'not sure why');
    console.error('Read Many resp:', data);
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
    object: req.body
  }, function(err, response) {
    if (err) return res.jsonError(500, 'didnt work', 'not sure why');
    res.status(201).json(response);
  });
});


// update the collection's meta data (ACL, etc?)
app.put('/apps/:appID/:accountID/:collectionIDJ', function(req, res) {
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
});


// update one
app.put('/apps/:appID/:accountID/:collectionID/:objectID', function(req, res) {
  console.error('Update One:', req.body);
  backend.update({
    appID: req.params.appID,
    accountID: req.params.accountID,
    collectionID: req.params.collectionID,
    _id: req.params.objectID,
    object: req.body
  }, function(err, response) {
    if (err) return res.jsonError(500, 'didnt work', 'not sure why');
    res.json(response);
  });
});

// update many
app.put('/apps/:appID/:accountID/:collectionID/__batch', function(req, res) {
  console.error('Update Many:', req.body);
  backend.updateMulti({
    appID: req.params.appID,
    accountID: req.params.accountID,
    collectionID: req.params.collectionID,
    objects: req.body
  }, function(err, response) {
    if (err) return res.jsonError(500, 'didnt work', 'not sure why');
    res.json(response);
  });
});


// delete one
app.delete('/apps/:appID/:accountID/:collectionID/:objectID', function(req, res) {
  console.error('Delete One:', req.params._id);
  backend.delete({
    appID: req.params.appID,
    accountID: req.params.accountID,
    collectionID: req.params.collectionID,
    _id: req.params.objectID,
  }, function(err) {
    if (err) return res.jsonError(500, 'didnt work', 'not sure why');
    res.status(204).end();
  });
});


var PORT = process.env.PORT || 2570;
app.listen(PORT, function(err) {
  if (err) {
    console.error(err);
    process.exit(1);
  }
  console.log('listening on', PORT);
});
