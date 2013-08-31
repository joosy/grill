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
      if typeof locals == "function"
        content = locals
        locals  = {}
      locals.content = content()
      compileOrMince location, locals

    partial = (location, locals={}) ->
      compileOrMince location, locals

    compileOrMince = (location, locals={}) ->
      context.dependOn location

      if Path.extname(location) == '.haml'
        locals[key] = value for key, value of options
        compile FS.readFileSync(context.environment.resolve location), locals
      else
        context.environment.findAsset(location).toString()

    compile = (source, locals={}) ->
      locals.partial = partial
      locals.layout  = layout

      HAMLC.compile(source.toString())(locals)

    compile(@data, options)