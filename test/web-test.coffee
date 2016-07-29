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

fs = require 'fs'
path = require 'path'

vows = require 'vows'
assert = require 'assert'

webBatch = require './web-batch'

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'

vows
  .describe('web module interface')
  .addBatch webBatch
    'When we require the web module':
      topic: ->
        require '../lib/web'
      'it returns an object': (web) ->
        assert.isObject web
      'and we check its methods':
        topic: (web) ->
          web
        'it has a get method': (web) ->
          assert.isFunction web.get
        'it has a head method': (web) ->
          assert.isFunction web.head
        'it has a put method': (web) ->
          assert.isFunction web.put
        'it has a post method': (web) ->
          assert.isFunction web.post
        'it has a del method': (web) ->
          assert.isFunction web.del
        'it has a web method': (web) ->
          assert.isFunction web.web
        'it has a start method': (web) ->
          assert.isFunction web.start
        'it has a stop method': (web) ->
          assert.isFunction web.stop
        'and we start the module':
          topic: (web) ->
            callback = @callback
            try
              web.start()
              callback null, web
            catch err
              callback err, null
            undefined
          'it works': (err, web) ->
            assert.ifError err
          'teardown': (web) ->
            web.stop()
          'and we make a get request':
            topic: (web) ->
              callback = @callback
              url = 'https://localhost:2342/foo'
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
  .export module
