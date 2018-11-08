const axios = require('axios');
const express= require('express');
const http = require('http');
const morgan = require('morgan');

const xray = require('aws-xray-sdk-core');
const xrayExpress = require('aws-xray-sdk-express');
xray.middleware.disableCentralizedSampling();

const captureAxios = require('./xray-axios');

const port = process.env.PORT || 3000;
const app = express();
const server = http.createServer(app);

let votesAPI = axios.create({
    baseURL: process.env.VOTES_URI || 'http://votes:3000/'
});

let reportsAPI = axios.create({
    baseURL: process.env.REPORTS_URI || 'http://reports:3000/'
});

captureAxios(votesAPI);
captureAxios(reportsAPI);

// install route logging middleware
app.use(morgan('dev'));

// install json body parsing middleware
app.use(express.json());

// install x-ray tracing
app.use(xrayExpress.openSegment('defaultName'));

// root route handler
app.get('/', (req, res) => {
  return res.send({ success: true, result: 'hello'});
});

// vote route handler
app.post('/vote', async (req, res) => {
  try {
    console.log('POST /vote: %j', req.body);
    let v = { vote: req.body.vote };
    let result = await votesAPI.post('/vote', v);
    // just pass result data through for now
    console.log('posted vote: %j', result.data);
    res.send(result.data);
  } catch (err) {
    console.log('ERROR: POST /vote: %s', err.message || err.response || err);
    res.status(500).send({ success: false, reason: 'internal error' });
  }
});

// results route handler
app.get('/results', async (req, res) => {
  try {
    console.log('GET /results');
    let result = await reportsAPI.get('/results');
    console.log('resp: %j', result.data);
    // just passing response through for now
    res.send(result.data);
  } catch (err) {
    console.log('ERROR: POST /results: %s', err.message || err.response || err);
    res.status(500).send({ success: false, reason: 'internal error' });
  }
});

app.use(xrayExpress.closeSegment());

// initialize and start running
(async () => {
  try {
    await new Promise(resolve => {
      server.listen(port, () => {
        console.log(`listening on port ${port}`);
        resolve();
      });
    });

  } catch (err) {
    console.log(err);
    process.exit(1);
  }
})();

