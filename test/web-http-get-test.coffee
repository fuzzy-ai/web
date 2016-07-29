# web-test.js
#
# Test the web module
#
# Copyright 2012, E14N https://e14n.com/
# Copyright 2014-2015, Fuzzy.ai https://fuzzy.ai/
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

vows = require 'vows'
assert = require 'assert'
debug = require('debug')('web:web-http-get-test')

web = require '../lib/web'
webBatch = require './web-batch'

process.on 'uncaughtException', (err) ->
  console.dir err.stack.split("\n")
  process.exit -1

vows
  .describe('GET over HTTP')
  .addBatch webBatch
    'and we make a get request':
      topic: ->
        callback = @callback
        debug "Starting GET request"
        url = 'http://localhost:1623/foo'
        debug "Getting #{url}"
        web.get url, (err, res, body) ->
          if err
            debug "Error getting #{url}: #{err}"
            callback err, null, null
          else
            debug "Success getting #{url}"
            callback null, res, body
        undefined
      'it works': (err, res, body) ->
        assert.ifError err
        assert.isObject res
        assert.isString body
      'and we check the response':
        topic: (res) ->
          @callback null, res
          undefined
        'it has a statusCode': (err, res) ->
          assert.isNumber res.statusCode
          assert.equal res.statusCode, 200
    'and we make a get request with a client error':
      topic: ->
        callback = @callback
        url = 'http://localhost:1623/error/404'
        web.get url, (err, res, body) ->
          if err && err.statusCode != 404
            callback err
          else if !err
            callback new Error("Unexpected success")
          else
            callback null, err
        undefined
      'it works': (err, obj) ->
        assert.ifError err
      'its error is correct': (err, obj) ->
        assert.ifError err
        assert.isObject obj
        assert.isString obj.name
        assert.equal obj.name, "ClientError"
        assert.isNumber obj.statusCode
        assert.equal obj.statusCode, 404
        assert.isObject obj.headers
        for name, value of obj.headers
          assert.isString name
          assert.isString value
        assert.isString obj.url
        assert.equal obj.url, 'http://localhost:1623/error/404'
        assert.isString obj.verb
        assert.equal obj.verb, "GET"
        assert.isString obj.body
        assert.isString obj.message
        assert.equal obj.message, "GET on http://localhost:1623/error/404 resulted in 404 Not Found"
    'and we make a get request with a server error':
      topic: ->
        callback = @callback
        url = 'http://localhost:1623/error/503'
        web.get url, (err, res, body) ->
          if err && err.statusCode != 503
            callback err
          else if !err
            callback new Error("Unexpected success")
          else
            callback null, err
        undefined
      'it works': (err, obj) ->
        assert.ifError err
      'its error is correct': (err, obj) ->
        assert.ifError err
        assert.isObject obj
        assert.isString obj.name
        assert.equal obj.name, "ServerError"
        assert.isNumber obj.statusCode
        assert.equal obj.statusCode, 503
        assert.isObject obj.headers
        for name, value of obj.headers
          assert.isString name
          assert.isString value
        assert.isString obj.url
        assert.equal obj.url, 'http://localhost:1623/error/503'
        assert.isString obj.verb
        assert.equal obj.verb, "GET"
        assert.isString obj.body
        assert.isString obj.message
        assert.equal obj.message, "GET on http://localhost:1623/error/503 resulted in 503 Service Unavailable"
  .export module
