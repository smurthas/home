var assert = require('assert');

var backend = require('../lib/backend.js');
var data = {};
var persistence = {
  save: function(_data) {
    data = _data;
  },
  load: function(callback) {
    callback(null, data);
  }
};

var APP = 'blargh';
var PK = 'publicKey';

var account;

function createAccount(callback) {
  var options = {
    appID: APP,
    publicKey: PK
  };
  backend.createAccount(options, function(err, resp) {
    assert.ifError(err);
    assert(resp);
    assert(resp._id);
    backend.getAccounts(options, function(err, accounts) {
      assert.ifError(err);
      assert.equal(accounts.length, 1);
      callback(resp);
    });
  });
}

function createCollection (callback) {
  createAccount(function(resp) {
    account = resp._id;
    var grants = {};
    grants[PK] = {
      readAttributes: true,
      createObjects: true,
      modifyAttributes: true
    };

    backend.createCollection({
      appID: APP,
      accountID: account,
      grantIDs: [PK],
      attributes: {
        testName: 'blargh',
        _grants: grants
      }
    }, function(err, coll) {
      assert.ifError(err);
      assert(coll);
      assert.equal(coll.testName, 'blargh');

      backend.getCollection({
        appID: APP,
        accountID: account,
        collectionID: coll._id,
        grantIDs: [PK]
      }, function(err, collection) {
        assert.ifError(err);
        assert(collection);
        assert(collection._id);
        assert.equal(collection._id, coll._id);
        assert.equal(collection.testName, 'blargh');
        callback(collection);
      });
    });
  });
}

describe('backend', function() {
  beforeEach(function(done) {
    data = {};
    backend.init({persistence:persistence}, function() {
      done();
    });
  });

  describe('create account', function() {
    it('should create an account', function(done) {
      createAccount(function(acct) {
        assert(acct);
        done();
      });
    });
  });

  describe('create collection', function() {
    it('should create a collection', function(done) {
      createCollection(function(coll) {
        assert(coll);
        done();
      });
    });
  });

  describe('create object', function() {
    it('should create an object with a random id', function(done) {
      createCollection(function(collection) {
        var options = {
          appID: APP,
          accountID: account,
          collectionID: collection._id,
          grantIDs: [PK],
          grantID: PK,
        };
        assert(collection);
        var grants = {};
        grants[PK] = {
          read: true,
          write: true
        };

        options.object = {
          testName: 'blooop',
          _grants: grants
        };
        backend.insert(options, function(err, object) {
          assert.ifError(err);
          assert(object);
          assert(object._id);

          options.filter = {
            _id: object._id
          };
          backend.get(options, function(err, objects) {
            assert.ifError(err);
            assert.equal(objects.length, 1);
            assert.equal(objects[0]._id, object._id);
            done();
          });
        });
      });
    });
  });
});
