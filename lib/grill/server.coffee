URL = require 'url'

#
# Express-based server for:
#   * Mincer assets coming from {Assetter}
#   * Proxy maps
#   * Static files (with compression support)
#
# Typically serves dynamic assets and proxies (as a workaround for Cross-Origin)
# at development and compressed statically precompiled things at production
#
module.exports = class Server

  constructor: (@grunt) ->

  #
  # Starts server on given port
  #
  # @param [Integer] port         Port to listen on
  # @param [Function] setup       Setup routine (see example)
  #
  # @example
  #   server.start 4000, (express) ->
  #     server.serveProxied express, '/foo': 'http://www.example.com/foo'
  #     server.serveStatic express, '/public', true
  #
  start: (port, setup) ->
    express = require('express')()
    setup? express
    server = express.listen port
    @grunt.log.ok "Started on #{port}"

    server

  #
  # Configure underlying Express instance manually
  #
  # @param [Express] express           Instance of Express
  # @param [Function] configure        Configurator
  #
  #
  serveMiddlewares: (express, configure) ->
    return unless configure
    configure(express)

  #
  # Makes server proxy using given routes map
  #
  # Routes map can be on of:
  #
  #   * {'/foo': 'http://example.com/foo'}
  #   * {src: '/foo', dest: 'http://example.com/foo'}
  #   * [src: '/foo', dest: 'http://example.com/foo'}, ...]
  #
  # @param [Express] express          Instance of Express
  # @param [Object] routes            Single route to map
  # @param [Array] routes             Array of routes to map
  #
  serveProxied: (express, routes) ->
    return unless routes

    proxy = require 'proxy-middleware'

    # Normalize routes to proxy: [{src: ..., dest: ...}]
    if @grunt.util._.isObject routes
      keys = Object.keys(routes)

      # proxy: {src: ..., dest: ...}
      if @grunt.util._(keys).without('src', 'dest').length == 0
        routes = [routes]

      # proxy: {src: 'dest'}
      else
        routes = Object.keys(routes).map (key) -> {src: key, dest: routes[key]}

    for entry in routes
      express.use entry.src, proxy(URL.parse entry.dest)
      @grunt.log.ok "Proxying #{entry.src} to #{entry.dest}"

  # @private
  normalizeUrl: (req) ->
    req.url += 'index.html' if req.url.indexOf('/', req.url.length - 1) != -1
    URL.parse(req.url).pathname.replace(/^\//, '')

  #
  # Makes server dispense dynamically-compiled assets from given {Assetter}
  #
  # If `greedy` is given path will be resolved by the following algo:
  #
  #    1. If there is an existing asset reflecting the given URL – serve it
  #    2. If there is an entry in `greedy` equal to the beginning of the URL – rewrite the URL to that entry
  #         e.g. `/foo/bar` URL could become `/foo` when `greedy` is `['/foo', '/bar']`.
  #    3. Serve with the resulting URL
  #
  # @param [Express] express          Instance of Express
  # @param [Assetter] assetter        Instance of {Assetter}
  # @param [Array] greedy             Set of greedy paths to ease HTML5 pushState
  # @param [String] path              Base URL to attach to
  #
  serveAssets: (express, assetter, greedy=[], path='/') ->
    server = assetter.server()
    Path   = require 'path'
    greedy = [greedy] unless @grunt.util._.isArray(greedy)

    express.use path, (req, res, next) =>
      pathname = @normalizeUrl(req)

      try 
        assetter.environment.resolve(pathname)
      catch error
        for attempt in greedy
          # Greedy urls should always start with slash
          attempt = '/'+attempt unless attempt.startsWith('/')

          if req.url.startsWith attempt
            req.url = attempt
            @normalizeUrl(req)
            break

      server.handle req, res

    @grunt.log.ok "Serving assets from #{path}"

  #
  # Serves static files from given path
  #
  # @param [Express] express          Instance of Express
  # @param [String] path              Local path to serve from
  # @param [Boolean] compress         Whether dynamic GZip should be used
  #
  serveStatic: (express, path, compress=false) ->
    unless compress
      express.use require('express').static(path)
    else
      Gzippo = require 'gzippo'
      express.use Gzippo.staticGzip(path)

    @grunt.log.ok "Serving static from /#{path}"