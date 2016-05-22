# web-test.js
#
# Test the web module
#
# Copyright 2012, E14N https://e14n.com/
# Copyright 2014-2015, Fuzzy.io https://fuzzy.io/
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

web = require '../lib/web'
webBatch = require './web-batch'

process.on 'uncaughtException', (err) ->
  console.dir err.stack.split("\n")
  process.exit -1

vows
  .describe('GET over HTTP with start')
  .addBatch webBatch
    'and we start the web module':
      topic: ->
        try
          web.start()
          @callback null
        catch err
          @callback err
        undefined
      'it works': (err) ->
        assert.ifError err
      'teardown': ->
        web.stop()
      'and we make a get request':
        topic: ->
          callback = @callback
          url = 'http://localhost:1623/foo'
          web.get url, (err, res, body) ->
            if err
              callback err, null, null
            else
              callback null, res, body
          undefined
        'it works': (err, res, body) ->
          assert.ifError err
          assert.isObject res
          assert.isString body
        'and we check the response':
          topic: (res) ->
            res
          'it has a statusCode': (res) ->
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
              callback null
          undefined
        'it works': (err) ->
          assert.ifError err
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
              callback null
          undefined
        'it works': (err) ->
          assert.ifError err
  .export module
