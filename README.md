fuzzy.io-web
============

A Web client library that does about what you'd expect it to. It supports
persistent connections.

License
-------

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Example
-------

```javascript

var web = require('fuzzy.io-web');

myClient = new web.WebClient({timeout: 5000});

myClient.get("http://example.com/resource", function(err, response, body) {
  if (err instanceof web.ClientError) {
    // Fix it.
  } else if (err instanceof web.ServerError) {
    // retry request?
  } else if (err) {
    // Timeouts, lookup, other things like that
    console.error(err);
  } else {
    // Succcess!
    console.log(body);
  }
});
```

WebClient
---------

This is the main class for running a Web client. It has the following methods.

* `constructor(props)`: Constructor takes named initialization properties as an
  argument. Currently the only property is `timeout`, which is how long to leave
  persistent connections open before closing them. If it's `Infinity`, never
  close it. If it's 0, close immediately (no persistent connections). If props
  is an integer instead of an object, use that as the timeout. `timeout` is zero
  by default.

* `request(method, url, headers, body, callback)`. Make an HTTP request with
  method `method`. `url` and `headers` are as expected. `body` is the body of
  the request, as a string, if any. `callback` is a function which receives
  `err`, `response`, and `body`. `response` is an http.IncomingMessage; body is
  the body of the response. `err` is an error; either a ClientError,
  ServerError, or maybe an error at a lower level of the stack (network, e.g.).

  There are convenience methods for HTTP methods, also.

* `get(url, headers, callback)`. Convenience for 'GET'.

* `post(url, headers, body, callback)`. Convenience for 'POST'.

* `head(url, headers, callback)`. Convenience for 'HEAD'.

* `put(url, headers, body, callback)`. Convenience for 'PUT'.

* `patch(url, headers, body, callback)`. Conenience for 'PATCH'.

* `delete(url, headers, callback)`. Convenience for 'DELETE'.

* `stop()` Shut down the client, and disconnect any existing persistent
  connections. You should do this if you have non-zero timeout and your program
  is terminating, since otherwise the connections will be held open for the
  timeout period.

ClientError
-----------

This is a class for when an HTTP response comes back with a 4xx status code. It
has the following properties:

* url
* verb
* statusCode
* headers
* body

ServerError
-----------

This is a class for when an HTTP response comes back with a 5xx status code. It
has the following properties:

* url
* verb
* statusCode
* headers
* body
