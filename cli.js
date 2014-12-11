#!/usr/bin/env node

var fs = require('fs');
var path = require('path');
var querystring = require('querystring');

var cli = require('cli');
var _ = require('lodash');
var request = require('request');
var async = require('async');

var tokens = require('./lib/tokens');

var options = {
  host: 'http://localhost:2570'
};

function getInput(string, options, callback) {
  if (typeof string === 'string') {
    var json;
    try {
      json = JSON.parse(string);
    } catch(err) {
      return callback(err);
    }
    callback(null, json);
  } else if (options.x) {
    cli.withStdin(function(stdin) {
      if (stdin && stdin.length) {
        var json;
        try {
          json = JSON.parse(stdin);
        } catch(err) {
          return callback(err);
        }

        callback(null, json);
      }
    });
  } else if (options.file) {
    var fileObjects;
    try {
      fileObjects = JSON.parse(fs.readFileSync(options.file).toString('utf8'));
      if (options.debug) console.error('read', fileObjects.length);
    } catch (err) {
      if (options.debug) console.error('err', err);
      return callback(err);
    }

    callback(null, fileObjects);
  } else {
    return callback();
  }
}

var commands = {};

commands.create = {};

commands.create.account = function(args, options) {
  options.path = '/apps/'+options.app;
  options.method = 'post';

  options.json = {
    public_key: options.publicKey
  };

  options.qs = {
    manager_token: options.managerToken
  };
  makeRequest(options, function(err, resp, body) {
    if (err) console.error(err);
    if (options.debug) console.error('statusCode', resp && resp.statusCode);
    console.log(JSON.stringify(body, 2, 2));
  });
};

commands.create.collection = function(args, options) {
  options.path = '/apps/'+options.app+'/'+options.account;
  options.method = 'post';

  getInput(args[0], options, function(err, attributes) {
    if (!attributes) {
      attributes = {
        _grants: {}
      };
      attributes._grants[options.publicKey] = {
        createObjects: true,
        readAttributes: true,
        modifyAttributes: true,
      };
      if (options.debug) console.error('attributes', attributes);
    }

    options.json = {attributes: attributes};
    makeRequest(options, function(err, resp, body) {
      if (err) console.error(err);
      if (options.debug) console.error('statusCode', resp && resp.statusCode);
      console.log(JSON.stringify(body, 2, 2));
    });
  });
};

function createObject(args, callback) {
  args.path = '/apps/'+args.app+'/'+args.account+'/'+args.collection;
  args.method = 'post';

  if (!args.json._grants && args.publicKey) {
    args.json._grants = {};
    args.json._grants[args.publicKey] = {
      read: true,
      write: true
    };
  }

  if (args.json._id) {
    args.path += '/' + args.json._id;
    args.method = 'put';
  }

  makeRequest(args, function(err, resp, body) {
    if (err || !resp && callback) return callback(err);
    if (resp.statusCode !== 200 && resp.statusCode !== 201) return callback(resp.statusCode);

    if (options.debug) console.error('statusCode', resp && resp.statusCode);
    console.log(JSON.stringify(body, 2, 2));

    if (callback) callback();
  });
}

commands.create.object = function(args, options) {
  options.collection = options.collection || args.shift();
  getInput(args.shift(), options, function(err, object) {
    options.json = object;
    createObject(options);
  });
};

commands.create.objects = function(args, options) {
  options.collection = options.collection || args.shift();

  getInput(args.shift(), options, function(err, objects) {
    async.forEachLimit(objects, options.parallel || 3, function(object, cbEach) {
      var theseOptions = _.clone(options);
      theseOptions.json = object;
      createObject(theseOptions, cbEach);
    }, function(err) {
      if (err) console.error(err);
    });
  });
};

commands.get = {};

commands.get.apps = function(args, options) {
  options.path = '/apps';
  options.method = 'get';

  options.json = {
    public_key: options.publicKey
  };

  options.qs = {
    manager_token: options.managerToken
  };
  if (options.debug) console.error('options', options);
  makeRequest(options, function(err, resp, body) {
    if (err) console.error(err);
    if (options.debug) console.error('statusCode', resp && resp.statusCode);
    console.log(JSON.stringify(body, 2, 2));
  });
};

commands.get.accounts = function(args, options) {
  options.path = '/apps/'+options.app;
  options.method = 'get';

  options.json = {
    public_key: options.publicKey
  };

  options.qs = {
    manager_token: options.managerToken
  };
  if (options.debug) console.error('options', options);
  makeRequest(options, function(err, resp, body) {
    if (err) console.error(err);
    if (options.debug) console.error('statusCode', resp && resp.statusCode);
    console.log(JSON.stringify(body, 2, 2));
  });
};

commands.get.collection = function(args, options) {
  var id = options.collection || args.shift();

  options.path = '/apps/'+options.app+'/'+options.account+'/'+id+'/__attributes';
  options.method = 'get';

  makeRequest(options, function(err, resp, body) {
    if (err) console.error(err);
    if (options.debug) console.error('statusCode', resp && resp.statusCode);
    console.log(JSON.stringify(body, 2, 2));
  });
};

commands.get.collections = function(args, options) {
  options.path = '/apps/'+options.app+'/'+options.account;
  options.method = 'get';

  options.qs = {};
  if (options.filter) options.qs.filter = options.filter;

  if (options.debug) console.error('options', options);
  makeRequest(options, function(err, resp, body) {
    if (err) console.error(err);
    if (options.debug) console.error('statusCode', resp && resp.statusCode);
    console.log(JSON.stringify(body, 2, 2));
  });

};

commands.get.object = function(args, options) {
  var collection = options.collection || args.shift();
  var object = args.shift();

  options.path = '/apps/'+options.app+'/'+options.account+'/'+collection+'/'+object;
  options.method = 'get';

  makeRequest(options, function(err, resp, body) {
    if (err) console.error(err);
    if (options.debug) console.error('statusCode', resp && resp.statusCode);
    console.log(JSON.stringify(body, 2, 2));
  });

};

commands.get.objects = function(args, options) {
  var collection = options.collection || args[0];

  options.path = '/apps/'+options.app+'/'+options.account+'/'+collection;
  options.method = 'get';

  options.qs = {};
  if (options.filter) options.qs.filter = options.filter;
  if (options.sort) options.qs.sort = options.sort;
  if (options.limit) options.qs.limit = options.limit;

  if (options.debug) console.error('options', options);
  makeRequest(options, function(err, resp, body) {
    if (err) console.error(err);
    if (options.debug) console.error('statusCode', resp && resp.statusCode);
    console.log(JSON.stringify(body, 2, 2));
  });
};


commands.config = {};

commands.config.get = function(args, options) {
  var length = 0;
  for (var k in options) {
    length = Math.max(k.length, length);
  }
  length++;
  for (var key in options) {
    console.log(key + (new Array(length-key.length).join(' ')), ': ', options[key]);
  }
};

commands.config.set = function(args) {
  var filename = path.join(process.cwd(), '.slab');
  var localOptions = loadAndAssign(filename, {});
  console.error('localOptions', localOptions);
  console.error('args', args);
  args.forEach(function(arg) {
    arg = arg.split('=');
    var key = arg.shift();
    var value = arg.join('');
    localOptions[key] = value;
  });

  console.log('would write: \n', JSON.stringify(localOptions, 2, 2));
  fs.writeFileSync(filename, JSON.stringify(localOptions, 2, 2));
};

function makeRequest(options, callback) {
  var url = options.host + options.path;
  if (options.qs && Object.keys(options.qs).length > 0) {
    url += '?' + querystring.stringify(options.qs);
  }
  if (options.debug) console.error('url', url);
  options.uri = url;
  var message =  options.method.toUpperCase()+'\n'+url+'\n';

  if (options.body) {
    message += options.body;
  } else if (options.json) {
    message += JSON.stringify(options.json);
  }

  if (options.debug) console.error('message', message);
  if (options.debug) console.error('options', options);
  var signature = tokens.signObject(message, options.secretKey);
  options.headers = options.headers || {};
  options.headers['X-Slab-Signature'] = signature;
  options.headers['X-Slab-PublicKey'] = options.publicKey;
  options.json = options.json || true;

  if (options.debug) console.error('options.uri', JSON.stringify(options.uri));
  request(options, callback);
}

cli.parse({
  app: ['app', 'app id', 'string'],
  account:  ['account', 'account id', 'string'],
  collection:  ['collection', 'collection id', 'string'],
  x: ['x', 'read from stdin'],
  filter: ['filter', 'filter a query to match criteria', 'string'],
  sort: ['sort', 'sort the results of a query', 'string'],
  limit: ['limit', 'limit the number of result', 'number'],
  file: ['file', 'a file to read from', 'path'],
  host: ['host', 'the host to make the request to', 'string']
});

function loadAndAssign(filepath, prevValues) {
  var read = {};
  try {
    read = JSON.parse(fs.readFileSync(filepath).toString());
    _.assign(prevValues, read);
  } catch(err) {
  }
  return prevValues;
}

cli.main(function(args, cliOptions) {
  loadAndAssign(path.join(process.env.HOME, '.slab'), options);
  loadAndAssign(path.join(process.cwd(), '.slab'), options);

  for (var i in cliOptions) {
    if (cliOptions[i] === null) {
      delete cliOptions[i];
    }
  }

  _.assign(options, cliOptions);

  if (options.debug) console.error('options', options);
  var command = commands[args[0]];
  args.shift();
  if (args.length) command = command[args[0]];

  args.shift();

  command(args, options);

});



