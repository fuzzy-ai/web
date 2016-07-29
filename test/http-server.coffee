# HTTPServer.coffee -- mock interface for testing the fuzzy.ai web interface
#
# Copyright 2014 fuzzy.ai https://fuzzy.ai/
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

JSON_TYPE = 'application/json; charset=utf8'

class HTTPServer

  constructor: (@port = 80, @options) ->

    if @options
      @server = https.createServer @options, @_handler
    else
      @server = http.createServer @_handler

  start: (callback) ->

    onError = (err) ->
      clearListeners()
      callback err

    onListening = ->
      clearListeners()
      callback null

    clearListeners = =>
      @server.removeListener 'error', onError
      @server.removeListener 'listening', onListening

    @server.on 'error', onError

    @server.on 'listening', onListening

    @server.listen @port

  stop: (callback) ->

    onError = (err) ->
      callback err

    onClose = ->
      callback null

    clearListeners = =>
      @server.removeListener 'error', onError
      @server.removeListener 'close', onClose

    @server.on 'error', (err) ->
      clearListeners()
      callback err

    @server.on 'close', =>
      clearListeners()
      @started = false
      callback null

    @server.close()

  toString: ->
    "[HTTPServer (port=#{@port})]"

  _handler: (request, response) ->
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
    request.on "end", ->
      request.body = body
      rel = request.url.slice(1)
      if rel.match /error\/\d+/
        statusCode = parseInt(rel.slice(6), 10)
        respond statusCode, {status: http.STATUS_CODES[statusCode]}
      respond 200, {status: "OK"}

module.exports = HTTPServer
