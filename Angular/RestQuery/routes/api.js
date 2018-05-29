var express = require('express');
var router = express.Router();
var sqlapi = require('../data/sqlapi');

router.get('/data', function (req, res, next) {
    console.log('data router started');

    //sqlapi.checkdb();
    sqlapi.getData(
        function (data) {
            res.send(data);
        }
    );
    //res.send('data api call');

});

module.exports = router;