module.exports = Grill =

  #
  # Modules
  #
  Assetter: require './grill/assetter'
  Bower: require './grill/bower'
  Server: require './grill/server'

  #
  # Settings
  #
  settings:
    prefix: 'grill'
    source: 'source'
    destination: 'public'
    assets:
      vendor: ['node_modules/joosy/source']
    server:
      port: 4000

  #
  # Factories
  #
  assetter: (grunt, environment) ->
    new Grill.Assetter grunt,
      grunt.file.expand("#{Grill.settings.source}/*").add(Grill.settings.assets.vendor),
      Grill.settings.destination,
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
    Object.merge Grill.settings, settings

    grunt.registerTask "#{Grill.settings.prefix}:bower", ->
      Grill.Bower.install grunt, @async()

    grunt.registerTask "#{Grill.settings.prefix}:server", ["#{Grill.settings.prefix}:server:development"]

    grunt.registerTask "#{Grill.settings.prefix}:server:development", ->
      @async()

      assetter = Grill.assetter(grunt, 'development')
      server   = Grill.server grunt

      server.start Grill.settings.server.port, (connect) ->
        server.serveProxied connect, Grill.config(grunt, 'server.proxy')
        server.serveAssets connect, assetter

    grunt.registerTask "#{Grill.settings.prefix}:server:production", ->
      @async()

      server = Grill.server grunt
      server.start process.env['PORT'] ? Grill.settings.server.port, (connect) ->
        server.serveStatic connect, Grill.settings.destination, true

    grunt.registerTask "#{Grill.settings.prefix}:compile", ->
      Grill.assetter(grunt, 'production').compile(
        Grill.config(grunt, 'assets.roots'),
        Grill.config(grunt, 'assets.skip') || [],
        error: (asset, msg) -> grunt.fail.fatal msg
        compiled: (asset, dest) -> grunt.log.ok "Compiled #{dest}"
      )

    grunt.registerTask "#{Grill.settings.prefix}:clean", ->
      grunt.file.delete 'public' if grunt.file.exists('public')
