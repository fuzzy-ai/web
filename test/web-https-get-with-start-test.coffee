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

fs = require 'fs'
path = require 'path'

vows = require 'vows'
assert = require 'assert'

web = require '../lib/web'
webBatch = require './web-batch'

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'

vows
  .describe('GET over HTTPS with start')
  .addBatch webBatch
    'and we start the web module':
      topic: ->
        try
          web.start {keepAlive: true}
          @callback null
        catch err
          @callback err
        undefined
      'it works': (err) ->
        assert.ifError err
      teardown: ->
        web.stop()
      'and we make a get request':
        topic: (app1, app2) ->
          callback = @callback
          url = 'https://localhost:2342/foo'
          headers = null
          app1.server.on 'request', (req, res) ->
            headers = req.headers

          web.get url, (err, res, body) ->
            if err
              callback err, null, null
            else
              callback null, res, body, headers
          undefined
        'it works': (err, res, body, headers) ->
          assert.ifError err
          assert.isObject res
          assert.isString body
          assert.isObject headers
          assert.notEqual headers.connection, "close"
        'and we check the response':
          topic: (res) ->
            res
          'it has a statusCode': (res) ->
            assert.isNumber res.statusCode
            assert.equal res.statusCode, 200
.export module
