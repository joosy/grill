Mincer = require 'mincer'
FS = require 'fs'
options = {}


module.exports = class HamlEngine extends Mincer.Template

  @defaultMimeType: 'text/html'

  @configure: (@options) ->

  evaluate: (context) ->
    HAMLC = require 'haml-coffee'
    options = @constructor.options || {}

    partial = (location, locals={}) ->
      compile(FS.readFileSync(context.environment.resolve location), locals)

    compile = (source, locals) ->
      HAMLC.compile(source.toString())(Object.merge locals, partial: partial)

    compile(@data, options)
