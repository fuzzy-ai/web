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
assert = require 'assert'
util = require 'util'

debug = require('debug')('web')
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

DEFAULT_TIMEOUT = 0

class WebClient

  constructor: (args...) ->

    debug "WebClient::constructor(#{util.inspect(args)})"

    if args.length > 0
      if _.isObject args[0]
        props = args[0]
        debug "props = #{util.inspect(props)}"
        if props.timeout?
          @timeout = props.timeout
        else
          @timeout = DEFAULT_TIMEOUT
    else if _.isNumber args[0]
      @timeout = args[0]
    else
      @timeout = DEFAULT_TIMEOUT

    debug "@timeout = #{@timeout}"

    assert @timeout == Infinity or (_.isFinite(@timeout) and @timeout >= 0),
      "Timeout must be either infinity, a positive number, or zero"

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
        maxSockets: Infinity

      # Don't do keepalive if we're going to timeout immediately

      if @timeout > 0
        options.keepAlive = true

      if protocol == 'http:'
        agent = new http.Agent options
        agent.createConnection = @_roundRobinConnection
      else if protocol == 'https:'
        agent = new https.Agent options
      else
        throw new Error("Unknown protocol #{protocol}")

      @_agent[protocol] = agent

    # Maybe timeout

    debug "@timeout = #{@timeout}"

    if _.isFinite(@timeout) and @timeout > 0
      @_setTimer protocol

    @_agent[protocol]

  _setTimer: (protocol) =>

    assert.ok _.isFinite(@timeout), "Timeout must be finite"
    assert.ok @timeout > 0, "Timeout must be > 0"

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
