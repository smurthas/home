var denest = require('denest');

var dist = require('./dist').distToSegment;

var LON = 0, LAT = 1;

function minDist(p, coordinates) {
  var min = 361;

  for (var i = 0; i < coordinates.length - 1; i++) {
    var d = dist(p, {
      x: coordinates[i][LON],
      y: coordinates[i][LAT]
    }, {
      x: coordinates[i+1][LON],
      y: coordinates[i+1][LAT]
    });

    min = Math.min(min, d);
  }

  return min;
}

module.exports = function(operator) {
  var p = {
    x: operator.ll[LON],
    y: operator.ll[LAT]
  };
  var field = operator.field;
  var distances = {};

  return function(a, b) {
    var aDist = distances[a._id];
    if (typeof aDist !== 'number') {
      aDist = distances[a._id] = minDist(p, denest(a, field));
    }

    var bDist = distances[b._id];
    if (typeof bDist !== 'number') {
      bDist = distances[b._id] = minDist(p, denest(b, field));
    }

    return aDist - bDist;
  };
};
