/*
IMPORTANT
Express and other packages must be available locall when application requires them.
However not necessary installed locally, there could be created local link to it:

npm link express

The packages should be installed globally in this case:
npm install express -g

Check the version:

npm list express -g

to start server:
node server

this routes to home page: http://localhost:8080
this routes to api/data: http://localhost:8080/api/data

api returns SQL results in JSON
*/

var express = require('express');
var bodyParser = require('body-parser');

var app = express();

app.use(express.static(__dirname + '/public'));

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

//app.use('/', require('./routes/home'));
app.use('/api', require('./routes/api'));

/* app-level routing
app.get('/', function (req, res, next) {
    res.send('home page')
  })
*/
var port = process.env.OPENSHIFT_NODEJS_PORT || 8080
, ip = process.env.OPENSHIFT_NODEJS_IP || "127.0.0.1";
app.listen(port, ip, function() {
  console.log('Express server listening on %d', port);
});
