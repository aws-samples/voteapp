process.env.AWS_XRAY_DEBUG_MODE=1;

const axios = require('axios');
const express= require('express');
const http = require('http');
const morgan = require('morgan');

const port = process.env.PORT || 3000;
const app = express();
const server = http.createServer(app);

const xray = require('aws-xray-sdk-core');
const xrayExpress = require('aws-xray-sdk-express');
xray.middleware.disableCentralizedSampling();

let ax = axios.create({
    baseURL: process.env.DATABASE_PROXY_URI || 'http://database-proxy:3000/'
});

// route logging middleware
app.use(morgan('dev'));

// json body parsing middleware
app.use(express.json());

// install x-ray tracing
app.use(xrayExpress.openSegment('votes.app'));

// root route handler
app.get('/', (req, res) => {
  return res.send({ success: true, result: 'hello'});
});

// vote route handler
app.post('/vote', async (req, res) => {
  try {
    console.log('POST /vote: %j', req.body);
    let v = req.body;
    let result = await ax.post('/vote', vote);
    let data = result.data;
    console.log('vote saved:', data);
    res.send({ success: true, result: data });
  } catch (err) {
    console.log('ERROR: POST /vote:', err);
    res.status(500).send({ success: false, reason: err.message })
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
