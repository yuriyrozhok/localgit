angular.module('aggr', [])
    .controller('AggregateCtrl', AggregateCtrl);
    
function getTotal(t, n) {
    //return t.number + n.number;
    return t + n;
    //return 12;
}
function AggregateCtrl($scope) {
    $scope.addNumber = function () {
        //$scope.numbers.push(num);
        //$scope.count = $scope.numbers.length;
        //$scope.num += 1;
        
        //$scope.numbers.push({ number: $scope.num });
        $scope.numbers.push($scope.num);
    }
    $scope.getCount = function () {
        return $scope.numbers.length;
    }
    $scope.getSum = function () {
        //return getTotal(0,0);
        return $scope.numbers.reduce(getTotal, 0);
    }
    $scope.init = function () {
        $scope.num = 0;
        $scope.count = 0;
        $scope.numbers = [];
    }
    $scope.init();
}