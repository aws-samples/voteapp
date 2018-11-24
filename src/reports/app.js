process.env.AWS_XRAY_DEBUG_MODE=1;

const axios = require('axios');

const Database = require('@subfuzion/database').Database;
const express= require('express');
const http = require('http');
const morgan = require('morgan');

const port = process.env.PORT || 3000;
const app = express();
const server = http.createServer(app);

let ax = axios.create({
    baseURL: process.env.DATABASE_PROXY_URI || 'http://database-proxy:3000/'
});

const xray = require('aws-xray-sdk-core');
const xrayExpress = require('aws-xray-sdk-express');
xray.middleware.disableCentralizedSampling();

// install route logging middleware
app.use(morgan('dev'));

// install json body parsing middleware
app.use(express.json());

// install x-ray tracing
app.use(xrayExpress.openSegment('reports.app'));

// root route handler
app.get('/', (_, res) => {
  return res.send({ success: true, result: 'hello'});
});

// results route handler
app.get('/results', async (_, res) => {
  try {
    console.log('GET /results');

//
// HACK
//
//    let result = await ax.get('/results');
//

    console.log('HACK /results');
    let result = {
      data: {
        success: true,
        result: {
          "a": 3,
          "b": 2
        }
      }
    };

// /HACK

    console.log('resp: %j', result.data);
    // Just passing response through
    // Expect an object with vote count: { success: true, result: { a: X, b: X } }
    res.send(result.data);
  } catch (err) {
    console.log('ERROR: GET /results: %s', err.message || err.response || err);
    res.status(500).send({ success: false, reason: 'internal error' });
  }
});

app.use(xrayExpress.closeSegment());

// initialize and start running
(async () => {
  try {
    server.listen(port, () => console.log(`listening on port ${port}`));
  } catch (err) {
    console.log(err);
    process.exit(1);
  }
})();
