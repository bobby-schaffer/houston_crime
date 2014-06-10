'use strict';

/* Controllers */

var hpdCrimeControllers = angular.module('hpdCrimeControllers', []);

hpdCrimeControllers.controller('mainCtrl', ['$scope', '$routeParams', '$http',
    function($scope, $routeParams, $http) {
        $scope.chartType = 'line';
        $scope.config = {
            title: 'Crime History',
            tooltips: true,
            labels: false,
            mouseover: function() {},
            mouseout: function() {},
            click: function() {},
            legend: {
                display: true,
                //could be 'left, right'
                position: 'right'
            },
            innerRadius: 0, // applicable on pieCharts, can be a percentage like '50%'
            xAxisMaxTicks: 5,
            lineLegend: 'lineEnd' // can be also 'traditional'
        };

        $http.get('/stats/historic/crimes/15E20').success(function (data) {
            $scope.data = data;
        })

    }]);


hpdCrimeControllers.controller('hpdCrimeMasterController', ['$scope', '$location', '$http',
    function($scope,$location,$http) {

        $scope.navigate = function(new_view){
            $location.url('/'+new_view);
        }

        $scope.navigate('login')

    }]);
