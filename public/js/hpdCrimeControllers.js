'use strict';

/* Controllers */

var hpdCrimeControllers = angular.module('hpdCrimeControllers', []);

hpdCrimeControllers.controller('mainCtrl', ['$scope', '$routeParams', '$http',
    function($scope, $routeParams, $http) {
    }]);


hpdCrimeControllers.controller('hpdCrimeMasterController', ['$scope', '$location', '$http',
    function($scope,$location,$http) {

        $scope.navigate = function(new_view){
            $location.url('/'+new_view);
        }

        $scope.navigate('login')

    }]);
