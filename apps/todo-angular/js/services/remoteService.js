/*global angular */

/**
 * Services that persists and retrieves TODOs from localStorage
 */
angular.module('todomvc')
	.factory('remoteService', function ($http) {
		'use strict';

		var HOST = 'http://localhost:2570';
		var BASE_URL = HOST + '/apps';

		var PUB_KEY = '-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoDKn2wdotXbLheSn09g/\nsjAc0rhYb8+KdQDB+zKp9Cq63qJDfR+r8sBn5QLz98LLEWKi7Q3v61Ih9ySUFlqy\nF/dCbugu+Xc8zIxK/8kWk+U1/umc7M6jKD7kw7qhomj/pieEw4UQ9cH0CdxM3U6w\noRSIU/pBix4K1nu8bgpgYzam1e9QTRu+yPw0a0DIsB8Ma7QDFbtcRBm1yi21yQkA\ne1orm2Az7ETZ1pZrGXrcBqcJ/IM3kWSh+mY1earsE1ihgeWueJqBd77zRYI5+0Uf\nN/DxtZUGOIPpKmY20zBgZM4aQO/Il+ZVIRVMJuB0fpimPawFLx8rPyuLbKjjfxyy\n9QIDAQAB\n-----END PUBLIC KEY-----';


		var MY_URL = 'http://localhost:3000';

		var self = {
			login: function() {
				var redirectURI = encodeURIComponent(MY_URL + '/#token');
				var url = HOST + '/authstart?';
				url += '&prove_uri=' + encodeURIComponent(MY_URL + '/prove');
				url += '&public_key=' + PUB_KEY;
				url += '&redirect_uri=' + redirectURI;
				window.location = url;
			},
			logout: function() {
				self.token = null;
				localStorage.removeItem('token');
			},
			setToken: function(token) {
				if (token === 'null' || token === 'undefined') return;
				if (!token) return;
				self.token = encodeURIComponent(token);
				localStorage.setItem('token', token);
			},
			//getNotLogged: function (callback) {
			get: function (callback) {
				$http({
					method: 'get',
					url: BASE_URL + '/todos?filter={"logged":false}&token=' + self.token
				}).success(function(data) {
					callback(null, data);
				}).error(callback);
			},

			add: function(todo, callback) {
				$http({
					method: 'post',
					url: BASE_URL + '/todos?token=' + self.token,
					data: todo
				}).success(function(data, status) {
					if (status !== 201) {
						return callback('bad status' + status, data);
					}
					callback(null, data._id);
				});
			},

			update: function(todo, callback) {
				$http({
					method: 'put',
					url: BASE_URL + '/todos/' + todo._id + '?token=' + self.token,
					data: todo
				}, callback);
			},

			updateMulti: function(todos, callback) {
				$http({
					method: 'put',
					url: BASE_URL + '/todos/__batch?token=' + self.token,
					data: todos
				}, callback);
			},

			remove: function(todo, callback) {
				$http({
					method: 'delete',
					url: BASE_URL + '/todos/' + todo._id + '?token=' + self.token,
				}, callback);
			}

		};

		self.setToken(localStorage.getItem('token'));

		return self;
	});
