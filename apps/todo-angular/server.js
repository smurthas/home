var crypto = require('crypto');
var fs = require('fs');
var url = require('url');

var pem = require('pem');
var express = require('express');
var app = express();


var pemString = fs.readFileSync('privkey.pem').toString('ascii');
var publicKey;

app.get('/prove', function(req, res) {
  var nonce = req.query.nonce;
  if (!nonce) {
    return res.status(400).end();
  }

  //nonce = nonce + Date.now();

  var sign = crypto.createSign('RSA-SHA256');
  sign.update(nonce);
  var signature = sign.sign(pemString, 'hex');

  var rdURI = url.parse(req.query.redirect_uri, true);
  //rdURI.querystring = rdURI.querystring || {};
  rdURI.query.signature = signature;
  rdURI.query.nonce = nonce;
  rdURI.query.public_key = publicKey;

  res.redirect(url.format(rdURI));
});

app.use(express.static(__dirname));


pem.getPublicKey(pemString, function(err, _publicKey) {
  publicKey = _publicKey.publicKey;
  app.listen(process.env.PORT || 3000);
});
