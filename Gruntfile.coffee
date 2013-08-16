module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-release'
  grunt.loadNpmTasks 'grunt-mocha-test'

  grunt.initConfig
    coffeelint:
      source:
        files:
          src: ['lib/**/*.coffee']
        options:
          'max_line_length':
            level: 'ignore'

    mochaTest:
      grill:
        src: 'spec/**/*_spec.coffee'

    release:
      options:
        bump: false
        add: false
        commit: false
        push: false

  grunt.registerTask 'default', ['mochaTest']
  grunt.registerTask 'test',    ['mochaTest']
  grunt.registerTask 'spec',    ['mochaTest']

  grunt.registerTask 'publish', ['coffeelint', 'release']