var assert = require('assert');

var mod = require('../lib/persistence/fs.js');

describe('fs persistence', function() {
  before(function(done) {
    var fs = new (require('fake-fs'))();
    fs.file('test');
    mod.init({
      module: fs,
      flush: 1,
      file: 'test'
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
