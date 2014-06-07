'use strict';

/* App Module */

var hpdCrimeApp = angular.module('hpdCrimeApp', [
    'ngRoute',
    'ngGrid',
    'ui.bootstrap',
    'angularCharts',
    'hpdCrimeControllers'
]);

hpdCrimeApp.config(['$routeProvider',
    function($routeProvider) {
        $routeProvider.
            when('/main', {
                templateUrl: 'partials/main.html',
                controller: 'mainCtrl'
            }).
            otherwise({
                redirectTo: '/main'
            });
    }]);
