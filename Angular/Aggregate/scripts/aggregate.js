angular.module('aggr', [])
    .controller('AggregateCtrl', AggregateCtrl);
    
function getTotal(t, n) {
    return t + n;
}
function AggregateCtrl($scope) {
    $scope.addNumber = function () {
        $scope.numbers.push($scope.num);
    }
    $scope.getCount = function () {
        return $scope.numbers.length;
    }
    $scope.getSum = function () {
        return $scope.numbers.reduce(getTotal, 0);
    }
    $scope.init = function () {
        $scope.num = 0;
        $scope.count = 0;
        $scope.numbers = [];
    }
    $scope.init();
}