# web.coffee
#
# Wrap http/https requests in a callback interface
#
# Copyright 2012, E14N https://e14n.com/
# Copyright 2014-2015 Fuzzy.io https://fuzzy.io/
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

urlparse = require('url').parse
http = require 'http'
https = require 'https'
dns = require 'dns'
net = require 'net'

debug = require('debug')('fuzzy.io-web')
async = require 'async'
_ = require 'lodash'

class ClientError extends Error
  constructor: (@url, @verb, @statusCode, @headers, @body) ->
    @name = "ClientError"
    text = http.STATUS_CODES[@statusCode]
    @message = "#{@verb} on #{@url} resulted in #{@statusCode} #{text}"

class ServerError extends Error
  constructor: (@url, @verb, @statusCode, @headers, @body) ->
    @name = "ServerError"
    text = http.STATUS_CODES[@statusCode]
    @message = "#{@verb} on #{@url} resulted in #{@statusCode} #{text}"

class WebClient

  constructor: (@timeout = 1000) ->

    @_agent = {}
    @_tid = {}

  start: (options) =>

    a1 = @_getAgent 'http:'
    a2 = @_getAgent 'https:'

  stop: =>

    cleanup = (protocol) =>
      if @_tid[protocol]
        clearTimeout @_tid[protocol]
        @_tid[protocol] = undefined
      if @_agent[protocol]
        @_agent[protocol].destroy()
        @_agent[protocol] = undefined

    cleanup 'http:'
    cleanup 'https:'

  _getAgent: (protocol) =>

    if !@_agent[protocol]

      options =
        keepAlive: true
        maxSockets: Infinity

      if protocol == 'http:'
        agent = new http.Agent options
        agent.createConnection = @_roundRobinConnection
      else if protocol == 'https:'
        agent = new https.Agent options
      else
        throw new Error("Unknown protocol #{protocol}")

      @_agent[protocol] = agent

    @_setTimer protocol
    @_agent[protocol]

  _setTimer: (protocol) =>

    destroyAgent = =>
      if @_agent[protocol]?
        @_agent[protocol].destroy()
        @_agent[protocol] = undefined

    if @_tid[protocol]
      clearTimeout @_tid[protocol]
      @_tid[protocol] = undefined

    @_tid[protocol] = setTimeout destroyAgent, @timeout

  request: (verb, url, headers, reqBody, callback) =>

    # Optional body

    if !callback
      callback = reqBody
      reqBody = null

    # Optional headers

    if !callback
      callback = headers
      headers = {}

    parts = urlparse url

    if parts.protocol == 'http:'
      mod = http
    else if parts.protocol == 'https:'
      mod = https
    else
      callback new Error("Unsupported protocol: #{parts.protocol}")

    options =
      host: parts.hostname
      port: parts.port
      path: parts.path
      method: verb.toUpperCase()
      headers: headers

    options.agent = @_getAgent parts.protocol

    if parts.protocol == "http:"
      options.createConnection = @_roundRobinConnection

    # Add Content-Length if necessary

    if reqBody and !headers["Content-Length"]?
      headers["Content-Length"] = Buffer.byteLength reqBody

    req = mod.request options, (res) ->
      resBody = ''
      res.setEncoding 'utf8'
      res.on 'data', (chunk) ->
        resBody = resBody + chunk
      res.on 'error', (err) ->
        callback err, null, null
      res.on 'end', ->
        code = res.statusCode
        if code >= 400 && code < 500
          callback new ClientError(url, verb, code, res.headers, resBody)
        else if code >= 500 && code < 600
          callback new ServerError(url, verb, code, res.headers, resBody)
        else
          callback null, res, resBody

    req.on 'error', (err) ->
      callback err, null

    if reqBody
      req.write reqBody

    req.end()

  get: (url, headers, callback) =>
    @request "GET", url, headers, callback

  post: (url, headers, body, callback) =>
    @request "POST", url, headers, body, callback

  head: (url, headers, callback) =>
    @request "HEAD", url, headers, callback

  put: (url, headers, body, callback) =>
    @request "PUT", url, headers, body, callback

  patch: (url, headers, body, callback) =>
    @request "PATCH", url, headers, body, callback

  delete: (url, headers, callback) =>
    @request "DELETE", url, headers, callback

  _roundRobinConnection: (options, callback) ->

    debug "In _roundRobinConnection()"

    async.waterfall [
      (callback) ->
        # Get all addresses
        dns.lookup options.host, {all: true}, callback
      (addresses, callback) ->

        debug require('util').inspect(addresses)

        connection = null
        lastError = null

        canConnect = (address, callback) ->

          coptions =
            host: address.address
            port: options.port
            family: address.family

          onConnect = ->
            clearListeners()
            connection = socket
            callback true

          onError = (err) ->
            clearListeners()
            lastError = err
            callback false

          clearListeners = ->
            socket.removeListener 'connect', onConnect
            socket.removeListener 'error', onError

          socket = net.createConnection coptions

          socket.on 'connect', onConnect
          socket.on 'error', onError

        async.detectSeries _.shuffle(addresses), canConnect, (addr) ->
          if addr?
            callback null, connection
          else
            callback lastError
    ], callback

defaultClient = new WebClient()

module.exports =
  web: (args...) -> defaultClient.request args...
  get: (args...) -> defaultClient.get args...
  post: (args...) -> defaultClient.post args...
  head: (args...) -> defaultClient.head args...
  put: (args...) -> defaultClient.put args...
  del: (args...) -> defaultClient.delete args...
  start: (args...) -> defaultClient.start args...
  stop: (args...) -> defaultClient.stop args...
  ClientError: ClientError
  ServerError: ServerError
  WebClient: WebClient
