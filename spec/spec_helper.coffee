chai  = require 'chai'
grunt = require 'grunt'
Path  = require 'path'

chai.should()

beforeEach ->
  grunt.file.setBase(Path.join __dirname, 'support')