# WebSocket

WebSocket is a simple modular `HTTP Socket` that supports SSL and cookies.

It allows full manipulation of the `HTTP header`, but specifically the:
  * `user_agent`
  * `postdata`
  * `cookie`

It supports `chunked` and `gzip` encoding.

It is not meant to be a complex solution, but rather an extendable building block.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'web_socket'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install web_socket

## Usage

### Basic Usage

Create an instance:

```ruby
s = WebSocket.new
```

The main command is `fetch`, which operates like:

```ruby
s.fetch(host, port, method, uri, postdata)
```

Here are examples of `GET` and `POST` requests over `HTTP` and `HTTPS`:

```ruby
s.fetch('www.google.com', 80, 'GET', '/')
s.fetch('www.google.com', 443, 'GET', '/')
s.fetch('www.bing.com', 443, 'POST', '/search', 'q=search_query')
```

Access the `response` data via:

```ruby
s.response[:header]
s.response[:body]
```

Likewise, the `request` and `cookie` are accessed via:

```ruby
s.request
s.cookie
```

### Advanced Usage

When creating an instance of class `WebSocket`, custom options can be passed to:
  * bind to a local ip address
  * disable cookies
  * specify a custom timeout
  * specify a custom user agent

Consider the following:

```ruby
s = WebSocket.new({
  ip: '192.168.1.100',
  cookies: false,
  timeout: 5,
  ua: 'Mozilla/4.0 (Windows; MSIE 6.0; Windows NT 5.0)'
})
```

This example binds to local ip, adjusts timeout, disables cookies, and pretends to be IE 6!

## Development

After checking out the repo, run `bin/setup` to install dependencies.

Then, run `bundle exec rake spec` to run the tests.

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
