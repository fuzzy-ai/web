# webclient-test.js
#
# Test the WebClient interface
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

vows.describe 'WebClient class interface'
  .addBatch webBatch
    'and we get the WebClient class':
      topic: ->
        require('../lib/web').WebClient
      'it exists': (WebClient) ->
        assert.isFunction WebClient
      'and we create an instance':
        topic: (WebClient) ->
          new WebClient()
        'it works': (client) ->
          assert.isObject client
        'it has a request() method': (client) ->
          assert.isFunction client.request
        'it has a get() method': (client) ->
          assert.isFunction client.get
        'it has a head() method': (client) ->
          assert.isFunction client.head
        'it has a post() method': (client) ->
          assert.isFunction client.post
        'it has a put() method': (client) ->
          assert.isFunction client.put
        'it has a delete() method': (client) ->
          assert.isFunction client.delete
        'it has a patch() method': (client) ->
          assert.isFunction client.patch
        'and we get a resource':
          topic: (client) ->
            url = 'http://localhost:1623/foo'
            client.get url, (err, res, body) =>
              if err
                @callback err, null, null
              else
                @callback null, res, body
            undefined
          'it works': (err, res, body) ->
            assert.ifError err
            assert.isObject res
            assert.isString body
  .export module
