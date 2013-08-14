module.exports = class Server

  constructor: (@grunt) ->

  start: (port, setup) ->
    connect = require('connect')()
    setup? connect
    connect.listen port
    @grunt.log.ok "Started on #{port}"

  serveProxied: (connect, routes) ->
    Sugar  = require 'sugar'
    URL    = require 'url'
    proxy  = require 'proxy-middleware'

    if Object.isObject routes
      routes = Object.keys(routes).map (key) -> {src: key, dest: routes[key]}

    for entry in routes
      connect.use entry.src, proxy(URL.parse entry.dest)
      @grunt.log.ok "Proxying #{entry.src} to #{entry.dest}"

  serveAssets: (connect, assetter, path='/') ->
    server = assetter.server()
    URL    = require 'url'
    Path   = require 'path'

    connect.use path, (req, res) ->
      req.url += 'index.html' if req.url.endsWith('/')
      server.handle req, res

    @grunt.log.ok "Serving assets from #{path}"

  serveStatic: (connect, path, compress=false) ->
    unless compress
      connect.use require('connect').static(path)
    else
      Gzippo = require 'gzippo'
      connect.use Gzippo.staticGzip(path)

    @grunt.log.ok "Serving static from /#{path}"