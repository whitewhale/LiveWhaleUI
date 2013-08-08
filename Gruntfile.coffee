module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    jasmine:
      src: 'src/**/*.js'
      options:
        specs: 'spec/*Spec.js'
        vendor: [
          'vendor/jquery.js'
          'vendor/jquery-ui.widget.min.js'
        ]
    assemble:
      options:
        flatten: true
        partials: ['site/includes/**/*.hbs']
        layoutdir: 'site/layouts'
        data: ['site/data/**/*.{json,yml}']
      site:
        options:
          layout: 'default.hbs'
        src: ['site/*.hbs']
        dest: 'public/'

  grunt.loadNpmTasks('grunt-contrib-jasmine')
  grunt.loadNpmTasks('assemble')

  grunt.registerTask('default', ['jasmine'])
