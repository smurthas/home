var qs = require('querystring');
var url = require('url');

var express = require('express');

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
  console.error('token', token);
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
  console.error('token unwrapped', token);
  if (!token || !token.key)  return res.send(401);

  req.appKey = token.key;

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

  if (!requestToken || !requestToken.key || requestToken.key !== secondFactorToken) {
    return res.status(401).end();
  }

  var password = req.body.password;
  tokens.verifyPassword(password, function(err, success) {
    console.error('err', err);
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

app.post('/auth/tokens', function(req, res) {
  var managerToken = req.body.manager_token;
  var pubKey = req.body.pub_key;

  console.error('creating token for pubKey', pubKey);

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


app.use('/apps', verifyAuth);


// CRUDy endpoints

// read many
app.get('/apps/:collection', function(req, res) {
  console.error('Read Many:', req.query.filter);
  backend.get({
    appID: req.appKey,
    collection: req.params.collection,
    filter: req.query.filter && JSON.parse(req.query.filter)
  }, function(err, data) {
    if (err) return res.jsonError(500, 'didnt work', 'not sure why');
    console.error('Read Many resp:', data);
    res.json(data);
  });
});


// create one
app.post('/apps/:collection', function(req, res) {
  console.error('Create One:', req.body);
  backend.insert({
    appID: req.appKey,
    collection: req.params.collection,
    object: req.body
  }, function(err, response) {
    if (err) return res.jsonError(500, 'didnt work', 'not sure why');
    res.status(201).json(response);
  });
});


// update one
app.put('/apps/:collection/:_id', function(req, res) {
  console.error('Update One:', req.body);
  backend.update({
    appID: req.appKey,
    collection: req.params.collection,
    _id: req.params._id,
    object: req.body
  }, function(err, response) {
    if (err) return res.jsonError(500, 'didnt work', 'not sure why');
    res.json(response);
  });
});

// update many
app.put('/apps/:collection/__batch', function(req, res) {
  console.error('Update Many:', req.body);
  backend.updateMulti({
    appID: req.appKey,
    collection: req.params.collection,
    objects: req.body
  }, function(err, response) {
    if (err) return res.jsonError(500, 'didnt work', 'not sure why');
    res.json(response);
  });
});


// delete one
app.delete('/apps/:collection/:_id', function(req, res) {
  console.error('Delete One:', req.params._id);
  backend.delete({
    appID: req.appKey,
    collection: req.params.collection,
    _id: req.params._id,
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
