var assert = require('assert');

var mod = require('../lib/persistence/redis.js');

describe('redis persistence', function() {
  before(function(done) {
    mod.init({
      url: 'redis://blargh.com:2570',
      module: 'fakeredis',
      key: 'test'
    }, done);
  });

  it('should save and load data', function(done) {
    var obj = {
      hello: 'blargh'
    };
    mod.save(obj, function(err) {
      assert.ifError(err);
      mod.load(function(err, loadedObj) {
        assert.ifError(err);
        assert.equal(obj.hello, loadedObj.hello);
        assert.deepEqual(obj, loadedObj);

        done();
      });
    });
  });
});
