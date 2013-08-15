#
# Tiny wrapper around Bower allowing Grunt-compatible automated usage
#
# Bower has no interactive conflicts resolution when called through API
# This is here to fix it with help of `commander`
#
module.exports = class Bower

  #
  # Installs packages if `bower.json` is in root
  #
  # @param [Grunt] grunt                       Instance of grunt
  # @param [Function] complete                 Called on complete
  #
  @install: (grunt, complete) ->
    if grunt.file.exists('bower.json')
      require('bower').commands.install()
        .on('data', (msg) -> grunt.log.ok msg)
        .on('error', (error) ->
          if error.code == 'ECONFLICT'
            @resolve complete, error
          else
            grunt.log.subhead "Bower has errored"
            grunt.log.warn error
            grunt.log.warn error.details if error.details?
        )
        .on('end', complete)
    else
      complete()

  #
  # Triggers interactive conflicts resolution or simply dies with error within `production` environment
  #
  # @param [Function] complete                 Called on complete
  # @param [Object] error                      Instance of ECONFLICT error generated by Bower
  #
  @resolve: (complete, error) ->
    grunt.log.subhead "Bower conflict for '#{error.name}'"

    error.picks.each (p) ->
      dependencies = p.dependants.map((x) -> x.endpoint.name).join(',')
      grunt.log.warn "#{p.endpoint.target} (#{dependencies.yellow}: resolves to #{p.pkgMeta._release.yellow})"

    resolutions = error.picks.map((x) -> x.pkgMeta._release).unique()

    unless process.env['NODE_ENV'] == 'production'
      grunt.log.subhead "Pick a resolution from the list:"

      require('commander').choose resolutions, (i) ->
        bowerConfig = JSON.parse grunt.file.read('./bower.json')
        bowerConfig.resolutions ||= {}
        bowerConfig.resolutions[error.name] = resolutions[i]

        grunt.file.write './bower.json', JSON.stringify(bowerConfig, null, 2)

        grunt.joosy.bower.install complete
    else
      grunt.log.subhead "Possible resolutions:"
      resolutions.unique().each (r) -> grunt.log.warn r
      grunt.fatal "Bower has errored"