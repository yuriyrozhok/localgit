angular.module('app', [])
    .controller('GuessTheNumberController', GuessTheNumberController);

function GuessTheNumberController($scope) {
    $scope.verifyGuess = function () {
        $scope.deviation = $scope.original - $scope.guess;
        $scope.noOfTries = $scope.noOfTries + 1;
    }
    $scope.initializeGame = function () {
        $scope.noOfTries = 0;
        $scope.maxval = 100;
        $scope.original = Math.floor((Math.random() * $scope.maxval) + 1);
        $scope.guess = null;
        $scope.deviation = null;
    }
    $scope.initializeGame();
}
