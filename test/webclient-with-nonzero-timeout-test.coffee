# webclient-with-nonzero-timeout-test.coffee
#
# Test the WebClient interface with a nonzero timeout
#
# Copyright 2016 Fuzzy.ai https://fuzzy.ai/
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

vows = require 'vows'
assert = require 'assert'

webBatch = require './web-batch'

vows.describe 'WebClient with nonzero timeout test'
  .addBatch webBatch
    'and we get the WebClient class':
      topic: ->
        require('../lib/web').WebClient
      'it exists': (WebClient) ->
        assert.isFunction WebClient
      'and we create an instance':
        topic: (WebClient) ->
          new WebClient timeout: 3000
        'it works': (client) ->
          assert.isObject client
        'teardown': (client) ->
          client.stop()
        'and we get a resource that takes less than the timeout':
          topic: (client, WebClient, httpsApp, httpApp) ->
            url = 'http://localhost:1623/wait/2'
            headers = null
            httpApp.server.on 'request', (req, body) ->
              headers = req.headers
            client.get url, (err, res, body) =>
              if err
                @callback err, null, null, null
              else
                @callback null, res, body, headers
            undefined
          'it works': (err, res, body, headers) ->
            assert.ifError err
            assert.isObject res
            assert.isString body
            assert.isObject headers
            assert.isString headers.connection
            assert.notEqual headers.connection, "close"
        'and we get a resource that takes longer than the timeout':
          topic: (client, WebClient, httpsApp, httpApp) ->
            url = 'http://localhost:1623/wait/5'
            headers = null
            httpApp.server.on 'request', (req, body) ->
              headers = req.headers
            start = new Date()
            client.get url, (err, res, body) =>
              end = new Date()
              if err
                @callback null, end - start
              else
                @callback new Error("Unexpected success")
            undefined
          'it fails correctly': (err, duration) ->
            assert.ifError err
            assert.lesser duration, 4000

  .export module
