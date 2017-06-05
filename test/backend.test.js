var assert = require('assert');

var backend = require('../lib/backend.js');
var data = {};
var persistence = {
  init: function(options, callback) {
    callback();
  },
  save: function(_data) {
    data = _data;
  },
  load: function(callback) {
    callback(null, data);
  }
};

var APP = 'blargh';
var PK = 'myPublicKey';

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

function createObject(callback) {
  createCollection(function(collection) {
    assert(collection);

    const options = {
      appID: APP,
      accountID: account,
      collectionID: collection._id,
      grantIDs: [PK],
      grantID: PK
    };
    const grants = {};
    grants[PK] = {
      read: true,
      write: true
    };
    const _id = 'marshmallow';
    options.object = {
      _id: _id,
      testName: 'blooop',
      _grants: grants
    };
    backend.insert(options, function(err, object) {
      assert.ifError(err);
      assert(object);
      assert(object._id);
      assert.equal(object._id, _id);
      callback(Object.assign({}, object), collection, options);
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
        var grants = {};
        grants[PK] = {
          readAttributes: true,
          createObjects: true,
          modifyAttributes: true
        };

        backend.getCollections({
          appID: APP,
          accountID: coll._accountID,
          grantIDs: [PK],
        }, function(err, colls) {
          assert.ifError(err);
          assert(colls);
          assert.equal(colls.length, 1);
          assert.equal(colls[0].testName, 'blargh');
          done();
        });
      });
    });
  });

  describe('delete collection', function() {
    it('should delete a collection', function(done) {
      createCollection(function(coll) {
        assert(coll);
        let options = {
          appID: APP,
          accountID: account,
          collectionID: coll._id,
          grantIDs: [PK],
        };
        backend.deleteCollection(options, (err) => {
          assert.ifError(err);
          backend.getCollection(options, function(err, collection) {
            assert(err.notFound);
            done();
          });
        });
      });
    });
  });

  describe('upsert collection', function() {
    it('should upsert a collection that already exists', function(done) {
      createCollection(function(coll) {
        assert(coll);
        let grants = {};
        grants[PK] = {
          readAttributes: true,
          createObjects: true,
          modifyAttributes: true
        };
        let options = {
          appID: APP,
          accountID: account,
          collectionID: coll._id,
          grantIDs: [PK],
          attributes: {
            testName: 'blargh',
            _grants: grants
          }
        };
        backend.upsertCollection(options, (err) => {
          assert.ifError(err);
          backend.getCollection(options, function(err, collection) {
            assert.ifError(err);
            assert(collection);
            assert(collection._id);
            assert.equal(collection._id, coll._id);
            assert.equal(collection.testName, 'blargh');
            done();
          });
        });
      });
    });

    it('should upsert a collection that does not exist', function(done) {
      createAccount(function(resp) {
        account = resp._id;
        const _id = 'blargh456';
        let grants = {};
        grants[PK] = {
          readAttributes: true,
          createObjects: true,
          modifyAttributes: true
        };
        let options = {
          appID: APP,
          accountID: account,
          collectionID: _id,
          grantIDs: [PK],
          attributes: {
            testName: 'blargh',
            _grants: grants
          }
        };
        backend.upsertCollection(options, (err, upsertedColl) => {
          assert.ifError(err);
          assert(upsertedColl);
          assert(upsertedColl._id);
          assert.equal(upsertedColl._id, _id);
          assert.equal(upsertedColl.testName, 'blargh');
          backend.getCollection(options, function(err, collection) {
            assert.ifError(err);
            assert(collection);
            assert(collection._id);
            assert.equal(collection._id, _id);
            assert.equal(collection.testName, 'blargh');
            done();
          });
        });
      });
    });
  });

  describe('objects', function() {

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

    it('should update an object', function(done) {
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

            options.object = {
              update: 'wahoo'
            };
            options._id = object._id;
            backend.update(options, function(err, updatedObject) {
              assert.ifError(err);
              assert(updatedObject);
              assert.equal(updatedObject.update, 'wahoo');
              done();
            });
          });
        });
      });
    });

    it('should create an object with a specified id', function(done) {
      createCollection(function(collection) {
        var options = {
          appID: APP,
          accountID: account,
          collectionID: collection._id,
          grantIDs: [PK],
          grantID: PK
        };
        assert(collection);
        var grants = {};
        grants[PK] = {
          read: true,
          write: true
        };
        var _id = 'marshmallow';
        options.object = {
          _id: _id,
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
            assert.equal(objects[0]._id, _id);
            done();
          });
        });
      });
    });

    it('should delete an object', function(done) {
      createCollection(function(collection) {
        var options = {
          appID: APP,
          accountID: account,
          collectionID: collection._id,
          grantIDs: [PK],
          grantID: PK
        };
        assert(collection);
        var grants = {};
        grants[PK] = {
          read: true,
          write: true
        };
        var _id = 'marshmallow';
        options.object = {
          _id: _id,
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
            assert.equal(objects[0]._id, _id);
            options._id = _id;
            delete options.object;
            backend.delete(options, function(err) {
              assert.ifError(err);
              backend.get(options, function(err, objects) {
                assert.ifError(err);
                assert.equal(objects.length, 0);
                done();
              });
            });
          });
        });
      });
    });

  });

  describe('grants', function() {
    it('should be able to grant a temporary ID access to an object', function(done) {
      createObject(function(object, collection, options) {
        backend.createTemporaryIdentity({
          attributes: {
            email: 'blargh@blargh.com'
          }
        }, function(err, id) {
          assert.ifError(err);
          object._grants[id] = { read: true, write: true };

          options.object = Object.assign({}, object);
          backend.update(options, function(err, updatedObject) {
            assert.ifError(err);
            assert(updatedObject);
            const convertOptions = {
              temporaryIdentity: id,
              publicKey: 'blargh',
            };

            backend.createIdentityFromTemporary(convertOptions, function(err) {
              assert.ifError(err);
              const grantIDs = backend.getGrantsForIdentity('blargh');
              const getOptions = {
                appID: APP,
                accountID: account,
                collectionID: collection._id,
                filter: {
                  _id: object._id,
                },
                grantIDs: backend.getGrantsForIdentity('blargh'),
              };

              backend.get(getOptions, function(err, gotObjects) {
                assert.ifError(err);
                assert.equal(gotObjects.length, 1);
                assert.equal(gotObjects[0]._id, object._id);
                done();
              });
            });
          });
        });
      });
    });
  });

});

