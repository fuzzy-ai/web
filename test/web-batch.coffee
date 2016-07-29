# web-batch.coffee
#
# Quickly set up test batches for the web module
#
# Copyright 2016, Fuzzy.ai https://fuzzy.ai/
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

      httpsApp = new HTTPServer 2342,
        key: fs.readFileSync(df('localhost.key'))
        cert: fs.readFileSync(df('localhost.crt'))

      httpApp = new HTTPServer 1623

      async.parallel [
        (callback) ->
          httpsApp.start callback
        (callback) ->
          httpApp.start callback
      ], (err) =>
        if err
          @callback err
        else
          @callback null, httpsApp, httpApp

      undefined

    'it works': (err, httpsApp, httpApp) ->
      assert.ifError err
      assert.isObject httpsApp
      assert.isObject httpApp
    teardown: (httpsApp, httpApp) ->
      callback = @callback
      async.parallel [
        (callback) ->
          httpsApp.stop callback
        (callback) ->
          httpApp.stop callback
      ], (err) ->
        callback null

  _.assign batch[top], rest

  batch

module.exports = webBatch
