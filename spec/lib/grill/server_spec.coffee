helper    = require '../../spec_helper'
Server    = require '../../../lib/grill/server'
Assetter  = require '../../../lib/grill/assetter'
grunt     = require 'grunt'
Sinon     = require 'sinon'
HTTP      = require 'http'

describe 'Grill.Server', ->

  before ->
    @muted = grunt.log.muted
    grunt.log.muted = true

    @request = (path, callback) ->
      request = HTTP.request {host: 'localhost', port: '6666', path: path}, (result) ->
        result.on 'data', (data) -> callback(data.toString())
      request.end()

  after ->
    grunt.log.muted = @muted

  beforeEach ->
    @server = new Server grunt

  afterEach ->
    @listener.close()

  it "starts", ->
    @listener = @server.start 6666

  it "serves middlewares", (done) ->
    @listener = @server.start 6666, (express) ->
      express.get '/', (req, res) -> res.send 'test'

    @request '/', (response) ->
      response.should == 'test'
      done()

  it "proxies", (done) ->
    @timeout 30000

    @listener = @server.start 6666, (express) =>
      @server.serveProxied express, {'/': 'http://www.example.com'}

    @request '/', (response) ->
      response.should.include '<h1>Example Domain</h1>'
      done()

  it "serves assets", (done) ->
    assetter  = new Assetter grunt, ['server'], ['server'], 'config', 'environment'
    @listener = @server.start 6666, (express) =>
      @server.serveAssets express, assetter

    @request '/application.js', (response) ->
      response.should.equal '(function() {\n  (function() {});\n\n}).call(this);'
      done()

  it "serves public", (done) ->
    @listener = @server.start 6666, (express) =>
      @server.serveStatic express, 'server'

    @request '/application.coffee', (response) ->
      response.should.equal '->'
      done()