# web-batch.coffee
#
# Quickly set up test batches for the web module
#
# Copyright 2016, Fuzzy.io https://fuzzy.io/
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
http = require 'http'
https = require 'https'

vows = require 'vows'
assert = require 'assert'
_ = require 'lodash'
async = require 'async'
debug = require('debug')('web:web-batch')

HTTPServer = require './http-server'

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'

webBatch = (rest) ->

  top = 'When we set up test servers'
  batch = {}
  batch[top] =
    topic: ->
      df = (rel) ->
        path.join(__dirname, 'data', rel)

      app1 = new HTTPServer 2342,
        key: fs.readFileSync(df('localhost.key'))
        cert: fs.readFileSync(df('localhost.crt'))

      app2 = new HTTPServer 1623

      async.parallel [
        (callback) ->
          app1.start callback
        (callback) ->
          app2.start callback
      ], (err) =>
        if err
          @callback err
        else
          @callback null, app1, app2

      undefined

    'it works': (err, app1, app2) ->
      assert.ifError err
      assert.isObject app1
      assert.isObject app2
    teardown: (app1, app2) ->
      callback = @callback
      async.parallel [
        (callback) ->
          app1.stop callback
        (callback) ->
          app2.stop callback
      ], (err) ->
        callback null

  _.assign batch[top], rest

  batch

module.exports = webBatch
