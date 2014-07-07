helper    = require '../../spec_helper'
Assetter  = require '../../../lib/grill/assetter'
grunt     = require 'grunt'
Sinon     = require 'sinon'

describe 'Grill.Assetter', ->

  before ->
    @destination = 'assetter/public'

  afterEach ->
    grunt.file.delete(@destination) if grunt.file.exists(@destination)

  beforeEach ->
    paths = grunt.file.expand('assetter/app/*').concat(grunt.file.expand 'assetter/vendor/*')

    @assetter = new Assetter grunt, paths, @destination, 'config', undefined, 'environment'
    @mincer   = @assetter.environment

  it 'serves', ->
    @mincer.findAsset('application.js').source.should.equal '(function() {\n  (function() {});\n\n}).call(this);'
    @mincer.findAsset('application.css').source.should.equal 'body {\n  background: linear-gradient(top, #fff, #000);\n}\n'
    @mincer.findAsset('image.png').buffer.length.should.equal 81178
    @mincer.findAsset('index.html').source.should.equal "<div class='config'>config</div>\n<div class='environment'>environment</div>\n<div class='partial'><div class='config'>config</div>\n<div class='environment'>environment</div></div>"

  it 'compiles', ->
    @assetter.compile 'application.*', 'partial.haml', 
      compiled: compiled = Sinon.spy()

    compiled.callCount.should.equal 4

    grunt.file.expand({cwd: 'assetter/public'}, '*').should.have.members [
      'application.css', 'application.js', 'image.png', 'index.html'
    ]

    grunt.file.read('assetter/public/application.js').should.equal '(function() {\n  (function() {});\n\n}).call(this);'
    grunt.file.read('assetter/public/application.css').should.equal 'body {\n  background: linear-gradient(top, #fff, #000);\n}\n'
    grunt.file.read('assetter/public/image.png').length.should.equal 78314
    grunt.file.read('assetter/public/index.html').should.equal "<div class='config'>config</div>\n<div class='environment'>environment</div>\n<div class='partial'><div class='config'>config</div>\n<div class='environment'>environment</div></div>"
