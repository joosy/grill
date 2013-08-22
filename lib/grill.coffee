require 'sugar'

module.exports = Grill =

  #
  # Modules
  #
  Assetter: require './grill/assetter'
  Bower: require './grill/bower'
  Server: require './grill/server'

  #
  # Suite-level settings that can be used to use grill as
  # building platform for other frameworks or toolbelts
  #
  settings:
    prefix: 'grill'                 # prefixes all grunt tasks fith this
    assets:
      vendor: ['app/*', 'vendor/*'] # vendor paths to grab assets from
      destination: 'public'         # directory containing static build output
    server:
      port: 4000                    # default local server port

  #
  # Factories
  #
  assetter: (grunt, environment) ->
    paths = Array.create(
      Grill.settings.assets.vendor,
      Grill.config(grunt, 'assets.paths')
    ).compact()

    new Grill.Assetter grunt,
      grunt.file.expand(paths),
      Grill.config(grunt, 'assets.destination') ? Grill.settings.assets.destination,
      Grill.config(grunt, 'config'),
      environment

  server: (grunt) ->
    new Grill.Server grunt

  config: (grunt, key) ->
    grunt.config.get "#{Grill.settings.prefix}.#{key}"

  #
  # Setup routine
  #
  setup: (grunt, settings={}) ->
    Object.merge Grill.settings, settings, true

    grunt[Grill.settings.prefix] =
      assetter: (environment) => @assetter grunt, environment
      server: => @server grunt

    grunt.registerTask "#{Grill.settings.prefix}:bower", ->
      Grill.Bower.install grunt, @async()

    grunt.registerTask "#{Grill.settings.prefix}:server", ["#{Grill.settings.prefix}:server:development"]

    grunt.registerTask "#{Grill.settings.prefix}:server:development", ->
      @async()

      assetter = Grill.assetter(grunt, 'development')
      server   = Grill.server grunt
      port     = Grill.config(grunt, 'server.port') ? Grill.settings.server.port

      server.start port, (express) ->
        server.serveMiddlewares express, Grill.config(grunt, 'middlewares')
        server.serveProxied express, Grill.config(grunt, 'proxy')
        server.serveAssets express, assetter, Grill.config(grunt, 'assets.greedy')

    grunt.registerTask "#{Grill.settings.prefix}:server:production", ->
      @async()

      server = Grill.server grunt
      port   = process.env['PORT'] ? (Grill.config(grunt, 'server.port') ? Grill.settings.server.port)

      server.start port, (express) ->
        server.serveStatic express, Grill.config(grunt, 'assets.destination') ? Grill.settings.assets.destination, true

    grunt.registerTask "#{Grill.settings.prefix}:compile", ["#{Grill.settings.prefix}:compile:development"]

    grunt.registerTask "#{Grill.settings.prefix}:compile:development", ->
      Grill.assetter(grunt, 'production').compile(
        Grill.config(grunt, 'assets.root'),
        Grill.config(grunt, 'assets.skip') || [],
        error: (asset, msg) -> grunt.fail.fatal msg
        compiled: (asset, dest) -> grunt.log.ok "Compiled #{dest}"
      )

    grunt.registerTask "#{Grill.settings.prefix}:compile:production", ->
      grunt.task.run("#{Grill.settings.prefix}:compile:development") if process.env['NODE_ENV'] == 'production'

    grunt.registerTask "#{Grill.settings.prefix}:clean", ->
      grunt.file.delete 'public' if grunt.file.exists('public')
