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

HTTPServer = require './http-server'

web = require '../lib/web'

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'

vows
  .describe('GET over HTTPS')
  .addBatch
    'When we set up an https server':
      topic: ->
        callback = @callback
        df = (rel) ->
          path.join(__dirname, 'data', rel)

        options =
          key: fs.readFileSync(df('localhost.key'))
          cert: fs.readFileSync(df('localhost.crt'))
        app = new HTTPServer(options)
        app.start 2342, (err) ->
          if err
            callback err
          else
            callback null, app
        undefined
      'it works': (err, app) ->
        assert.ifError err
        assert.isObject app
        return
      'teardown': (app) ->
        callback = @callback
        if app and app.stop
          app.stop (err) ->
            callback null
        else
          callback null
        undefined
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
        'and we make a get request':
          topic: ->
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
