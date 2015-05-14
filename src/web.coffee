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
http = require('http')
https = require('https')

agent = {}

class ClientError extends Error
  constructor: (@url, @verb, @statusCode, @headers, @body) ->
    @message = "#{@verb} on #{@url} resulted in #{@statusCode} #{http.STATUS_CODES[@statusCode]} client error"

class ServerError extends Error
  constructor: (@url, @verb, @statusCode, @headers, @body) ->
    @message = "#{@verb} on #{@url} resulted in #{@statusCode} #{http.STATUS_CODES[@statusCode]} server error"

web = (verb, url, headers, reqBody, callback) ->

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

    if agent[parts.protocol]
      options.agent = agent[parts.protocol]
    else
      options.agent = false

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
        if res.statusCode >= 400 && res.statusCode < 500
          callback new ClientError(url, verb, res.statusCode, res.headers, resBody)
        else if res.statusCode >= 500 && res.statusCode < 600
          callback new ServerError(url, verb, res.statusCode, res.headers, resBody)
        else
          callback null, res, resBody

    req.on 'error', (err) ->
      callback err, null

    if reqBody
      req.write reqBody

    req.end()

get = (url, headers, callback) ->
  web "GET", url, headers, callback

post = (url, headers, body, callback) ->
  web "POST", url, headers, body, callback

head = (url, headers, callback) ->
  web "HEAD", url, headers, callback

put = (url, headers, body, callback) ->
  web "PUT", url, headers, body, callback

del = (url, headers, callback) ->
  web "DELETE", url, headers, callback

start = (options) ->
  if !agent['http:']
    agent['http:'] = new http.Agent options
  if !agent['https:']
    agent['https:'] = new https.Agent options
  agent['http:'].maxSockets = Infinity
  agent['https:'].maxSockets = Infinity

stop = () ->
  for protocol in ['http:', 'https:']
    if agent[protocol]
      if agent[protocol].destroy
        agent[protocol].destroy()
      delete agent[protocol]

module.exports =
  web: web
  get: get
  post: post
  head: head
  put: put
  del: del
  start: start
  stop: stop
  ClientError: ClientError
  ServerError: ServerError
