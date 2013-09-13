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
    coffee:
      release:
        files:
          'release/jquery.lw-overlay.js': 'src/jquery.lw-overlay.coffee'
          'release/jquery.lw-timepicker.js': 'src/jquery.lw-timepicker.coffee'
      blah:
        expand: true
        flatten: true
        cwd: 'src'
        src: ['*.coffee']
        dest: 'release/'
        ext: '.js'
    uglify:
      production:
        files:
          'release/frontend.min.js': ['src/jquery.lw-overlay.js']
          'release/lw-overlay.min.js': ['src/jquery.lw-overlay.js']
    concat:
      frontend_css:
        src: ['public/css/plugins/lw-overlay.css', 'public/css/plugins/lw-timepicker.css']
        dest: 'release/css/frontend.css'
    clean:
      release: ['release', 'release/css']
    copy:
      js:
        src: 'src/*.js'
        dest: '../LiveWhale/www/livewhale/plugins/lwui/'
      css:
        expand: true
        cwd: 'release/css/'
        src: '*.css'
        dest: '../LiveWhale/www/livewhale/theme/core/styles/lwui/'
        flatten: true
        filter: 'isFile'
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
  grunt.loadNpmTasks('grunt-contrib-concat')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks('grunt-contrib-coffee')

  grunt.registerTask('default', ['jasmine'])
  grunt.registerTask('production', ['uglify:production', 'copy:production'])
  grunt.registerTask('lw', ['copy:js', 'copy:css'])

  # only compile the plugin files that have changed
  grunt.event.on 'watch', (action, filepath) ->
    grunt.config ['less', 'plugins', 'files'], [
      src: filepath,
      dest: 'public/css/plugins/' + path.basename(filepath, '.less') + '.css'
    ]
    return

  return
