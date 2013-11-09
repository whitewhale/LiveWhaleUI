path = require 'path'

module.exports = (grunt) ->
  lwdir = grunt.option('lwdir') || '../LiveWhale'
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
    clean:
      release: ['release']
    coffee:
      #release:
      #  expand: true
      #  cwd: 'src/'
      #  src: ['**/*.coffee']
      #  dest: 'release/'
      #  ext: '.js'
      release:
        files:
          'release/jquery.lw-overlay.js': 'src/jquery.lw-overlay.coffee'
          'release/jquery.lw-timepicker.js': 'src/jquery.lw-timepicker.coffee'
          'release/jquery.lw-popover.js': 'src/jquery.lw-popover.coffee'
    concat:
      js:
        options:
          separator: ';'
        files:
          'release/frontend.js': ['release/jquery.lw-overlay.js']
          'release/backend.js': [
            'release/jquery.lw-overlay.js'
            'release/jquery.lw-timepicker.js'
            'release/jquery.lw-popover.js'
          ]
      css:
        src: [
          'public/css/plugins/lw-overlay.css'
          'public/css/plugins/lw-timepicker.css'
          'public/css/plugins/lw-popover.css'
        ]
        dest: 'release/css/default.css'
    uglify:
      release:
        files:
          'release/frontend.min.js': ['release/frontend.js']
          'release/backend.min.js': ['release/backend.js']
          'release/jquery.lw-overlay.min.js': ['release/jquery.lw-overlay.js']
    copy:
      images:
        expand: true
        flatten: true
        src: 'public/css/plugins/images/*'
        dest: lwdir + '/www/livewhale/theme/core/styles/lwui/images/'
      js:
        expand: true
        flatten: true
        src: 'release/*.js'
        dest: lwdir + '/www/livewhale/plugins/lwui/'
      css:
        expand: true
        flatten: true
        cwd: 'release/css/'
        src: '*'
        dest: lwdir + '/www/livewhale/theme/core/styles/lwui/'
    less:
      site:
        options:
          paths: ['public/css']
        files:
          'public/css/main.css': 'public/css/main.less'
      plugins:
        options:
          paths: ['public/css/plugins']
        files:
          'public/css/plugins/lw-timepickers.css': 'public/css/plugins/lw-timepicker.less'
          'public/css/plugins/lw-overlay.css': 'public/css/plugins/lw-overlay.less'
    watch:
      assemble:
        files: ['README.md', 'site/**/*.hbs']
        tasks: ['assemble']
        options:
          livereload: true
      less_site:
        files: ['public/css/**/*.less']
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
  grunt.loadNpmTasks('grunt-contrib-clean')

  grunt.registerTask('default', ['assemble', 'less'])

  grunt.registerTask('release', [
    'clean', 'coffee:release', 'concat:js', 'uglify:release', 'less:plugins', 'concat:css'
  ])

  grunt.registerTask('lw', ['copy:js', 'copy:css', 'copy:images'])

  # only compile the plugin files that have changed
  grunt.event.on 'watch', (action, filepath) ->
    grunt.config ['less', 'plugins', 'files'], [
      src: filepath,
      dest: 'public/css/plugins/' + path.basename(filepath, '.less') + '.css'
    ]
    return
  return
