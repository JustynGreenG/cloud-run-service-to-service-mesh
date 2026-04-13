/*
 Copyright 2026 Google LLC

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */


import express from 'express';
const app = express();
const port = process.env.PORT || 8080;
import {GoogleAuth} from 'google-auth-library';
const auth = new GoogleAuth();

app.get('/', async (req, res) => {
    const randomServiceUrl = process.env.RANDOM_SERVICE_URL;
    if (!randomServiceUrl) {
        res.status(500).send('RANDOM_SERVICE_URL not set');
        return;
    }

    const isolatedServiceUrl = process.env.ISOLATED_SERVICE_URL;
    if (!isolatedServiceUrl) {
        res.status(500).send('ISOLATED_SERVICE_URL not set');
        return;
    }

    const client = await auth.getIdTokenClient(randomServiceUrl);

    let msg = 'Welcome to the caller service!\n\n';

    try {
        msg += `Calling random service: ${randomServiceUrl}\n`
        const response = await client.request({url: `${randomServiceUrl}`});
        msg +=`Your lucky number is ${response.data}\n\n`;
    } catch (err) {
        console.error(err);
        msg += `Error calling random service: ${err.message}\n\n`;
    }

    try {
        msg += `Calling isolated service: ${isolatedServiceUrl}\n`
        const response = await client.request({url: `${isolatedServiceUrl}`});
        msg +=`The call to isolated should have failed but I got the message: ${response.data}\n\n`;
    } catch (err) {
        msg += `I failed to access the isolated service and that's good.\n\n`
    }

    msg+= '--\n';

    res.set('Content-Type', 'text/plain');
    res.send(msg);
});

app.listen(port, () => {
  console.log(`Caller service listening on port ${port}`);
});
