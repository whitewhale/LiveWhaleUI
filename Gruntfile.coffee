path = require 'path'

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
      site:
        options:
          paths: ['public/css']
        src:
          expand: true
          cwd: 'public/css'
          src: '*.less'
          ext: '.css'
      plugins:
        options:
          paths: ['public/css/plugins']
        files:
          'public/css/plugins/lw-timepickers.css': 'public/css/plugins/lw-timepicker.less'
          'public/css/plugins/lw-test.css': 'public/css/plugins/lw-test.less'
    watch:
      assemble:
        files: ['site/**/*.hbs']
        tasks: ['assemble']
        options:
          livereload: true
      less_site:
        files: ['public/css/*.less']
        tasks: ['less:site']
        options:
          livereload: true
      less_plugins:
        options:
          livereload: true
          nospawn: true
        files: ['public/css/plugins/*.less']
        tasks: ['less:plugins']

  grunt.loadNpmTasks('grunt-contrib-jasmine')
  grunt.loadNpmTasks('assemble')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-contrib-less')

  grunt.registerTask('default', ['jasmine'])

  # only compile the plugin files that have changed
  grunt.event.on 'watch', (action, filepath) ->
    grunt.config ['less', 'plugins', 'files'], [
      src: filepath,
      dest: 'public/css/plugins/' + path.basename(filepath, '.less') + '.css'
    ]
    return

  return
