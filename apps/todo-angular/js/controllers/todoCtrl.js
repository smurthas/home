/*global angular */

/**
 * The main controller for the app. The controller:
 * - retrieves and persists the model via the todoStorage service
 * - exposes the model to the template and provides event handlers
 */
/*jshint maxparams: 6 */
angular.module('todomvc')
	.controller('TodoCtrl', function TodoCtrl(
		$scope,
		$routeParams,
		$location,
		$filter,
		$http,
		remoteService) {
		'use strict';

		var todoStorage = remoteService;
		if ($location.$$path === '/token') {
			todoStorage.setToken($routeParams.token);
		}


		$scope.loggedIn = !!todoStorage.token;

		var todos;
		todoStorage.get(function(err, fetchedTodos) {
			todos = $scope.todos = fetchedTodos || [];

			todos.sort(function(a, b) {
				return a.sortIndex - b.sortIndex;
			});
			console.error('todos', todos);

			$scope.newTodo = '';
			$scope.editedTodo = null;

			$scope.sortableOptions = {
				update: function(e, ui) {
					console.error('ui', ui.item.sortable);
				}
			};
			$scope.$watch('todos', function (newValue) {//, oldValue) {
				//console.error('newValue', JSON.stringify(newValue, 2,2 ));
				//console.error('oldValue', oldValue);
				if (!newValue) return;
				$scope.remainingCount = $filter('filter')(todos, { completed: false }).length;
				$scope.completedCount = todos.length - $scope.remainingCount;
				$scope.allChecked = !$scope.remainingCount;

				var updated = [];
				for (var i = 0; i < newValue.length; i++) {
					var todo = newValue[i];
					//var index = newValue.indexOf(todo);
					//console.error('i:', i, 'index:', index, 'title:', todo.title);
					//console.error('todo.sortIndex', todo.sortIndex);
					if (todo.sortIndex !== i) {
						todo.sortIndex = i;
						updated.push(todo);
					}
				}
				//todos.forEach(function(todo, i) {
				//});

				console.error('updated', updated);
				if (updated.length) {
					todoStorage.updateMulti(updated, function(err) {
						throw err;
						// TODO: log/handle errors?
					});
				}
			}, true);
		});

		// Monitor the current route for changes and adjust the filter accordingly.
		$scope.$on('$routeChangeSuccess', function () {
			if ($location.$$path === '/token') {
				todoStorage.setToken($routeParams.token);
				$scope.loggedIn = !!todoStorage.token;
			}
			var status = $scope.status = $routeParams.status || '';

			$scope.statusFilter = (status === 'active') ?
				{ completed: false } : (status === 'completed') ?
				{ completed: true } : null;
		});

		$scope.login = function() {
			todoStorage.login();
		};

		$scope.logout = function() {
			todoStorage.logout();
			$scope.loggedIn = !!todoStorage.token;
		};


		function updateMetadata(todo, callback) {
			if (true) {
				todo.year = 1985;
				todo.poster = 'http://localhost:3000/img';
				return callback();
			}
			$http({
				method: 'GET',
				url: 'http://www.omdbapi.com/?t=' + todo.title
			}).success(function(data) {
				console.error('data', data);

				if (data.Title.toLowerCase() === todo.title.toLowerCase().trim()) {
					todo.title = data.Title;
				}
				todo.year = data.Year;
				todo.length = data.Runtime;
				todo.director = data.Director;
				todo.genre = data.Genre;
				todo.poster = data.Poster.replace(/SX300/, 'SX214');
				callback();

			}).error(callback);
		}

		$scope.addTodo = function () {
			var newTodo = $scope.newTodo;
			if (!newTodo.length) {
				return;
			}
			var todo = {
				title: newTodo,
				completed: false,
				logged: false
			};

			$scope.newTodo = '';
			updateMetadata(todo, function(err) {
				if (!err) {
					$scope.newTodo = '';
					todoStorage.add(todo, function(err, _id) {
						todo._id = _id;
						console.error('pushing todo', todo);
						todos.push(todo);
					});
				}
			});

		};

		$scope.editTodo = function (todo) {
			$scope.editedTodo = todo;
			// Clone the original todo to restore it on demand.
			$scope.originalTodo = angular.extend({}, todo);
		};

		$scope.doneEditing = function (todo) {
			$scope.editedTodo = null;
			todo.title = todo.title.trim();

			if (!todo.title) {
				$scope.removeTodo(todo);
			} else {
				todoStorage.update(todo, function() {
					//
				});
			}
		};

		$scope.revertEditing = function (todo) {
			todos[todos.indexOf(todo)] = $scope.originalTodo;
			$scope.doneEditing($scope.originalTodo);
		};

		$scope.removeTodo = function (todo) {
			console.error('todo', todo);
			todos.splice(todos.indexOf(todo), 1);
			todoStorage.remove(todo, function() {
				console.error('todo', todo);
				console.error('todos', todos);
			});
		};

		$scope.clearCompletedTodos = function () {
			var logged = [];

			todos.forEach(function(todo) {
				if (todo.completed) {
					todo.logged = true;
				}
				logged.push(todo);
			});

			$scope.todos = todos = todos.filter(function (val) {
				return !val.logged;
			});

			todoStorage.updateMulti(logged, function() {

			});
		};

		$scope.markAll = function (completed) {
			completed = !completed;
			console.error('completed', completed);
			var changed = [];
			todos.forEach(function (todo) {
				if (todo.completed !== completed) {
					console.error('pushing');
					changed.push(todo);
				}
				todo.completed = completed;
			});

			todoStorage.updateMulti(changed, function() {
				console.log('done');
			});
		};

		$scope.markOne = function(todo) {
			todo.completed = !todo.completed;
			console.error('todo', todo);
			todoStorage.update(todo, function() {
				console.error('updated');
			});
		};

	});
