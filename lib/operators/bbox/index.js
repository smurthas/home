var LAT = 1, LON = 0;
module.exports = function(operator, coordinates) {
  var minLat = Math.min(operator[0][LAT], operator[1][LAT]);
  var maxLat = Math.max(operator[0][LAT], operator[1][LAT]);
  var minLon = Math.min(operator[0][LON], operator[1][LON]);
  var maxLon = Math.max(operator[0][LON], operator[1][LON]);

  for (var i in coordinates) {
    var point = coordinates[i];
    var withinBounds = point[LAT] >= minLat && point[LAT] <= maxLat &&
                       point[LON] >= minLon && point[LON] <= maxLon;
    if (!withinBounds) return -1;
  }

  return 0;
};
