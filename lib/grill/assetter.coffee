Sugar      = require 'sugar'
Mincer     = require 'mincer'
Path       = require 'path'
FS         = require 'fs'
HamlEngine = require '../mincer/engines/haml_engine'

#
# Wrapper around Mincer that makes proper setup and adds some useful helpers
#
module.exports = class Assetter

  #
  # @param [Grunt] grunt                  Instance of Grunt
  # @param [Array] paths                  Array of load paths
  # @param [String] destination           Compilation destination
  # @param [Array] config                 Global static config
  # @param [String] environment           Environment string
  #
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

    @paths.add 'bower_components'
    @paths.each (p) => @environment.appendPath p

  #
  # Statically compiles all the assets
  #
  # Compiles only given roots for CSS and JS and everything but `skips` for other
  # content types
  #
  # @param [String] roots                  Glob-based pattern of files to compile for CSS and JS
  # @param [Array] roots                   Array of patterns of files to compile for CSS and JS
  # @param [String] skips                  Glob-based pattern of files to not compile
  # @param [Array] skips                   Array of patterns of files to not compile
  # @param [Array] callbacks               `error: (message) ->`, `compile: (asset, destination) ->`
  #
  compile: (roots, skips, callbacks) ->
    @paths.each (p) =>
      console.log p
      @grunt.file.expand({cwd: p}, '**/*').forEach (file) =>
        forced      = @grunt.file.match(roots, file).length > 0
        directory   = @grunt.file.isDir(p, file)
        pathname    = Path.resolve Path.join(p, file)
        meta        = @environment.attributesFor(pathname)
        compilable  = meta.contentType == 'application/javascript' || meta.contentType == 'text/css'
        compilable  = true if p == 'bower_components'
        skip        = @grunt.file.match(skips, file).length > 0
        destination = Path.join(@destination, meta.logicalPath)

        if directory
          return unless forced
          asset       = @environment.findAsset(file)
          file        = asset.pathname
          destination = Path.join(@destination, asset.logicalPath)

        if !skip && (!compilable || forced)
          if Path.extname(file).length == 0
            @grunt.file.copy pathname, destination
          else
            asset ||= @environment.findAsset file

            @grunt.file.mkdir Path.dirname(destination)
            FS.writeFileSync destination, asset.buffer

          callbacks.compiled? asset, destination

  #
  # Generates instance of Mincer.Server
  #
  server: ->
    new Mincer.Server(@environment)
