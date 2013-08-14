Mincer     = require 'mincer'
Path       = require 'path'
HamlEngine = require('../mincer/engines/haml_engine')

module.exports = class Assetter

  constructor: (@grunt, @paths, @destination, config, environment='development') ->
    Mincer.logger.use log: (level, message) =>
      @grunt.log.writeln message

    Mincer.registerEngine '.haml', HamlEngine

    HamlEngine.configure config: config, environment: environment

    Mincer.CoffeeEngine.configure bare: false

    Mincer.StylusEngine.configure (stylus) =>
      stylus.define '$environment', environment
      stylus.define '$config', config
      stylus.use require('nib')()

    @environment = new Mincer.Environment(process.cwd())
    @environment.appendPath 'bower_components'
    paths.each (p) => @environment.appendPath p

  compile: (roots, skips, callbacks) ->
    @paths.each (p) =>
      for file in @grunt.file.expand({cwd: p}, '**/*') when @grunt.file.isFile(p, file)
        meta       = @environment.attributesFor(Path.resolve Path.join(p, file))
        compilable = ['application/javascript', 'text/css'].any meta.contentType
        forced     = @grunt.file.match(roots, file).length > 0
        skip       = @grunt.file.match(skips, file).length > 0

        if !skip && (!compilable || forced)
          asset = @environment.findAsset file
          destination = Path.join(@destination, meta.logicalPath)

          callbacks.error? "Cannot find #{file}" unless asset
          @grunt.file.write destination, asset.toString()
          callbacks.compiled? asset, destination

  server: ->
    new Mincer.Server(@environment)
