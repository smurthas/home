var crypto = require('crypto');

var bs58 = require('bs58');

var CIPHER_PASS = process.env.CIPHER_PASS;
var SALT = process.env.SALT;
var HASH_TIMES = parseInt(process.env.HASH_TIMES, 10) || 1000;
var HASH_LENGTH = parseInt(process.env.HASH_LENGTH, 10) || 16;

var SALTED_PASS_HASH = crypto.pbkdf2Sync(
  process.env.PASSWORD,
  SALT,
  HASH_TIMES,
  HASH_LENGTH
).toString('hex');
delete process.env.PASSWORD;
var MANAGER_TOKEN_SECRET = crypto.pbkdf2Sync(
  SALTED_PASS_HASH,
  SALT,
  HASH_TIMES,
  HASH_LENGTH
).toString('hex');

console.error('SALTED_PASS_HASH', SALTED_PASS_HASH);
console.error('MANAGER_TOKEN_SECRET', MANAGER_TOKEN_SECRET);

module.exports.verifySignature = function(nonce, sig, pubkey) {
  var parsedNonce = module.exports.verifyToken(nonce);
  if (!parsedNonce || !parsedNonce.key) return false;
  var verifier = crypto.createVerify('RSA-SHA256');
  verifier.update(nonce);
  if (!verifier.verify(pubkey, sig, 'hex')) return false;
  return parsedNonce.key;
};


module.exports.generateToken = function(_id) {
  var cipher = crypto.createCipher('aes256', CIPHER_PASS);
  var tokenObject = {
    //rb: crypto.randomBytes(4).toString('base64'),
    d: Date.now(),
    _id: _id
  };

  var str = JSON.stringify(tokenObject);

  var tmp = cipher.update(str, 'ascii', 'hex');
  tmp += cipher.final('hex');
  return bs58.encode(new Buffer(tmp, 'hex'));
};

module.exports.verifyToken = function(token) {
  var decipher = crypto.createDecipher('aes256', CIPHER_PASS);
  try {
    token = bs58.decode(token).toString('hex');
    var tokenObject = decipher.update(token, 'hex', 'utf8');
    tokenObject += decipher.final('utf8');
    return JSON.parse(tokenObject);
  } catch(e) {
    console.error('verify token err', e);
    return false;
  }
};

var temporaryTokens = {};
module.exports.generateTemporaryToken = function(redirectURI, pubkey) {
  //XXX: attacker could hit this point a billion trillion times to increase the
  //chance of guessing a token. Or could bloat memory.

  var token = module.exports.generateToken(pubkey);
  temporaryTokens[token] = {
    redirectURI: redirectURI,
    pubkey: pubkey
  };
  return token;
};

module.exports.verifyTemporaryToken = function(token) {
  var verification = temporaryTokens[token];
  delete temporaryTokens[token];
  return verification;
};

module.exports.verifyPassword = function(password, callback) {
  if (!password) return callback('need a password');
  crypto.pbkdf2(password, SALT, HASH_TIMES, HASH_LENGTH, function(err, key) {
    if (err) return callback(err);
    if (!key) return callback(null, false);
    return callback(null, key.toString('hex') === SALTED_PASS_HASH);
  });
};


module.exports.generateManagerToken = function() {
  return module.exports.generateToken(MANAGER_TOKEN_SECRET);
};

module.exports.verifyManagerToken = function(managerToken) {
  var token = module.exports.verifyToken(managerToken);
  if (!token || !token._id) return false;
  if (token._id !== MANAGER_TOKEN_SECRET) return false;
  delete token._id;
  return token;
};


// XXX: careful!!!
//console.error('DEBUG: a managerToken:', module.exports.generateManagerToken());
