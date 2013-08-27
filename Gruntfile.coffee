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
    less:
      development:
        options:
          paths: ['public/css']
        files:
          'public/css/main.css': 'public/css/main.less'
    watch:
      assemble:
        files: ['site/**/*.hbs']
        tasks: ['assemble']
        options:
          livereload: true
      less:
        files: ['public/css/**/*.less']
        tasks: ['less']
        options:
          livereload: true

  grunt.loadNpmTasks('grunt-contrib-jasmine')
  grunt.loadNpmTasks('assemble')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-contrib-less')

  grunt.registerTask('default', ['jasmine'])
