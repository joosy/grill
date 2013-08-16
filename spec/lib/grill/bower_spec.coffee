helper = require '../../spec_helper'
Bower  = require '../../../lib/grill/bower'
grunt  = require 'grunt'
Sinon  = require 'sinon'

describe 'Grill.Bower', ->

  afterEach ->
    grunt.file.delete('bower_components') if grunt.file.exists('bower_components')

  describe 'empty', ->

    it 'returns', ->
      grunt.file.setBase 'bower/empty'
      Bower.install grunt, spy = Sinon.spy()
      spy.callCount.should.equal 1

  describe 'basic', ->

    it 'installs', (done) ->
      @timeout 30000
      grunt.file.setBase 'bower/basic'

      Bower.install grunt, ->
        grunt.file.exists('bower_components').should.equal true
        grunt.file.exists('bower_components/jquery/jquery.js').should.equal true
        done()

  describe 'conflict', ->

    before ->
      @muted = grunt.log.muted
      grunt.log.muted = true

    after ->
      grunt.log.muted = @muted

    afterEach ->
      Bower.resolve.restore?()
      Bower.commander.restore?()

      data = JSON.parse(grunt.file.read 'bower.json')
      delete data.resolutions
      grunt.file.write 'bower.json', JSON.stringify(data, null, 2)

    it 'notices conflict', (done) ->
      @timeout 30000
      grunt.file.setBase 'bower/conflict'

      Sinon.stub Bower, 'resolve', (grunt, complete, error) ->
        done()

      Bower.install grunt, ->
        # we are not supposed to get to get here
        true.should.equal false

    it 'resolves conflict', (done) ->
      @timeout 30000
      grunt.file.setBase 'bower/conflict'

      Sinon.stub Bower, 'commander', ->
        choose: (resolutions, callback) ->
          callback 1

      Bower.install grunt, ->
        done()