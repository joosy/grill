module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-release'

  grunt.initConfig
    coffeelint:
      source:
        files:
          src: ['lib/**/*.coffee']
        options:
          'max_line_length':
            level: 'ignore'

    release:
      options:
        bump: false
        add: false
        commit: false
        push: false

  grunt.registerTask 'publish', ['coffeelint', 'release']