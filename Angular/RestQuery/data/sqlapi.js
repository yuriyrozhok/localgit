module.exports = {
    checkdb: function (args) {
        console.log('started [checkdb] of module ' + module.filename);
        internalCheckDb(
            function () { console.log('completed [checkdb] of module ' + module.filename) }
        );
    }
    ,
    getData: function (callback) {
        internalGetData(callback);
    }

}
var mssql = require('mssql');

var config = {
    user: 'dyi',
    password: 'dyi',
    server: 'ADL5',
    options: {
        //instanceName: 'SQL14MD',
        database: 'DYI'
    }
}

function internalCheckDb(oncomplete) {
    mssql.connect(config).then(function () {
        new mssql.Request().query('select 0 x')
            .then(function (result) {
                console.log('query done:', result);
                oncomplete();
            }).catch(function (err) {
                console.log('MSSQL ERROR:' + err)
            });
    })
}

function internalGetData(oncomplete) {
    mssql.connect(config).then(function () {
        new mssql.Request().query('select top 3 [Source_Key], [ShipmentEquipment_Key] from [DYI].[dbo].[tF_AllocationEngine]')
            .then(function (result) {
                console.log('result:', result);
                console.log('columns:', result.recordset.columns);
                oncomplete(result.recordset);
            }).catch(function (err) {
                console.log('MSSQL ERROR:' + err)
            });
    })
}
