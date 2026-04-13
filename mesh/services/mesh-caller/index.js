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

import axios from "axios";
import express from "express";
import { Agent } from "http";

const app = express();
const port = process.env.PORT || 8080;

const randomServiceUrl = process.env.RANDOM_SERVICE_URL;

if (!randomServiceUrl) {
  console.error("RANDOM_SERVICE_URL not set");
  process.exit(1);
}

const REQUEST_TIMEOUT = 5000;

// Global Agent for connection reuse (Crucial for mTLS performance)
const httpAgent = new Agent({
  keepAlive: true,
  maxSockets: 100,
  timeout: REQUEST_TIMEOUT,
});

const api = axios.create({
  baseURL: randomServiceUrl,
  httpAgent: httpAgent,
  timeout: REQUEST_TIMEOUT,
});

app.get("/", async (req, res) => {
  let msg = "Welcome to the MESH caller service!\n\n";

  try {
    msg += `Calling random service: ${api.defaults.baseURL}\n`;
    const response = await api.get("/");
    msg += `Your lucky number is ${response.data}\n\n`;
  } catch (err) {
    console.error(err);
    msg += `Error calling random service: ${err.message}\n\n`;
  }

  msg += "--\n";

  res.set("Content-Type", "text/plain");
  res.send(msg);
});

app.listen(port, () => {
  console.log(`Caller service listening on port ${port}`);
});
