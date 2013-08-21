Mincer = require 'mincer'
FS     = require 'fs'
Path   = require 'path'

module.exports = class HamlEngine extends Mincer.Template

  @defaultMimeType: 'text/html'

  @configure: (@options) ->

  evaluate: (context) ->
    HAMLC   = require 'haml-coffee'
    options = @constructor.options || {}

    layout = (location, locals={}, content) ->
      if Object.isFunction(locals)
        content = locals
        locals  = {}
      locals.content = content()
      compileOrMince location, locals

    partial = (location, locals={}) ->
      compileOrMince location, locals

    compileOrMince = (location, locals={}) ->
      context.dependOn location

      if Path.extname(location) == '.haml'
        compile FS.readFileSync(context.environment.resolve location), Object.merge(locals, options)
      else
        context.environment.findAsset(location).toString()

    compile = (source, locals={}) ->
      HAMLC.compile(source.toString())(Object.merge locals, partial: partial, layout: layout)

    compile(@data, options)