const axios = require('axios');
const express= require('express');
const http = require('http');
const morgan = require('morgan');

const port = process.env.PORT || 3000;
const app = express();
const server = http.createServer(app);

let votesURI = process.env.VOTES_URI || 'http://votes:3000/';
let votesAPI = axios.create({
    baseURL: votesURI
});

let reportsURI = process.env.REPORTS_URI || 'http://reports:3000/';
let reportsAPI = axios.create({
    baseURL: reportsURI
});

// install route logging middleware
app.use(morgan('dev'));

// install json body parsing middleware
app.use(express.json());

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
    console.log(`web -> GET ${reportsURI}/results`);
    let result = await reportsAPI.get('/results');
    console.log('resp: %j', result.data);
    // Just passing response through
    // Expect an object with vote count: { success: true, result: { a: X, b: X } }
    res.send(result.data);
  } catch (err) {
    console.log('ERROR: GET /results: %s', err.message || err.response || err);
    res.status(500).send({ success: false, reason: 'internal error' });
  }
});

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

