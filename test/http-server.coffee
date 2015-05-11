# httpserver.coffee -- mock interface for testing the fuzzy.io web interface
#
# Copyright 2014 fuzzy.io https://fuzzy.io/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

http = require 'http'
https = require 'https'
events = require 'events'

JSON_TYPE = 'application/json; charset=utf8'

class HTTPServer extends events.EventEmitter
  constructor: (options) ->

    self = @
    server = null
    mod = null

    handler = (request, response) ->
      body = ""
      respond = (code, body) ->
        response.statusCode = code
        if !response.headersSent
          response.setHeader "Content-Type", JSON_TYPE
        response.end(JSON.stringify(body))
      request.on "data", (chunk) ->
        body += chunk
      request.on "error", (err) ->
        respond 500, {status: "error", message: err.message}
      request.on "end", () ->
        request.body = body
        self.emit "request", request
        respond 200, {status: "OK"}

    @start = (port, callback) ->
      server.once 'error', (err) ->
        callback err
      server.once 'listening', () ->
        callback null
      server.listen port

    @stop = (callback) ->
      server.once 'close', () ->
        callback null
      server.once 'error', (err) ->
        callback err
      server.close()

    if options
      server = https.createServer options, handler
    else
      server = http.createServer handler

module.exports = HTTPServer