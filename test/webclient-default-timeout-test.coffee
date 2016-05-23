# webclient-default-timeout-test.coffee
#
# Test the WebClient interface
#
# Copyright 2016 Fuzzy.io https://fuzzy.io/
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

vows.describe 'WebClient default timeout'
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
        'it has a timeout of zero': (client) ->
          assert.isNumber client.timeout
          assert.equal client.timeout, 0
  .export module
