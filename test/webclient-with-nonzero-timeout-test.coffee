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
          new WebClient timeout: 60000
        'it works': (client) ->
          assert.isObject client
        'and we get a resource':
          topic: (client, WebClient, httpsApp, httpApp) ->
            url = 'http://localhost:1623/foo'
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
          'and we stop the client':
            topic: (res, body, headers, client) ->
              try
                client.stop()
                @callback null
              catch err
                @callback err
              undefined
            'it works': (err) ->
              assert.ifError err

  .export module
