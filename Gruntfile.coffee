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
        partials: ['public/includes/**/*.hbs']
        layoutdir: 'public/layouts'
        data: ['public/data/**/*.{json,yml}']
      site:
        options:
          layout: 'default.hbs'
        src: ['public/*.hbs']
        dest: 'public/'
    clean:
      release: ['release']
    coffee:
      release:
        files: [
          expand: true
          cwd: 'src/'
          src: ['{,*/}*.coffee']
          dest: 'release/'
          rename: (dest, src) ->
            return dest + src.replace(/\.coffee$/, '.js')
        ]
      dev:
        files: [
          expand: true
          cwd: 'src/'
          src: ['{,*/}*.coffee']
          dest: 'src/'
          rename: (dest, src) ->
            return dest + src.replace(/\.coffee$/, '.js')
        ]
    concat:
      js:
        files:
          'release/frontend.js': [
            'vendor/jquery-ui.widget.js'
            'vendor/imagesloaded.js'
            'release/jquery.lw-overlay.js'
            'release/jquery.lw-slideshow.js'
          ]
          'release/frontend.min.js': [
            'vendor/jquery-ui.widget.min.js'
            'vendor/imagesloaded.min.js'
            'release/jquery.lw-overlay.min.js'
            'release/jquery.lw-slideshow.min.js'
          ]
          'release/backend.js': [
            'vendor/lodash.js'
            'vendor/jquery.ba-bbq.js'
            'vendor/imagesloaded.js'
            'release/jquery.lw-overlay.js'
            'release/jquery.lw-timepicker.js'
            'release/jquery.lw-popover.js'
            'release/jquery.lw-slideshow.js'
          ]
          'release/backend.min.js': [
            'vendor/lodash.min.js'
            'vendor/jquery.ba-bbq.min.js'
            'vendor/imagesloaded.min.js'
            'release/jquery.lw-overlay.min.js'
            'release/jquery.lw-timepicker.min.js'
            'release/jquery.lw-popover.min.js'
            'release/jquery.lw-slideshow.min.js'
          ]
      css:
        src: [
          'public/css/plugins/lw-overlay.css'
          'public/css/plugins/lw-timepicker.css'
          'public/css/plugins/lw-popover.css'
          'public/css/plugins/lw-slideshow.css'
        ]
        dest: 'release/css/default.css'
    uglify:
      release:
        files: [
          expand: true
          cwd: 'release/'
          src: ['{,*/}*.js']
          dest: 'release/'
          rename: (dest, src) ->
            return dest + src.replace(/\.js/, '.min.js')
        ]
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
        dest: lwdir + '/www/livewhale/scripts/lwui/'
      css:
        expand: true
        flatten: true
        cwd: 'release/css/'
        src: '*'
        dest: lwdir + '/www/livewhale/theme/core/styles/lwui/'
      vendor:
        options:
          flatten: true
        files: [
          {
            expand: true
            flatten: true
            cwd: 'vendor/'
            dest: lwdir + '/www/livewhale/thirdparty/jquery/'
            src: [
              'jquery.js'
              'jquery.min.js'
              'jquery-ui.js'
              'jquery-ui.min.js'
              'jquery-ui.widget.js'
              'jquery-ui.widget.min.js'
              'jquery.ba-bbq.js'
              'jquery.ba-bbq.min.js'
            ]
          }
          {
            expand: true
            flatten: true
            cwd: 'vendor/'
            dest: lwdir + '/www/livewhale/thirdparty/'
            src: [
              'lodash.js'
              'lodash.min.js'
              'imagesloaded.js'
              'imagesloaded.min.js'
            ]
          }
        ]
    less:
      site:
        options:
          paths: ['public/css']
        files:
          'public/css/main.css': 'public/css/main.less'
      plugins:
        files: [
          expand: true
          cwd: 'public/css/plugins'
          src: ['*.less']
          dest: 'public/css/plugins'
          ext: '.css'
        ]
    watch:
      assemble:
        files: ['README.md', 'public/**/*.hbs']
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

  grunt.registerTask('website', ['assemble', 'less'])
  
  grunt.registerTask('release', [
    'clean', 'coffee', 'uglify', 'concat:js', 'less:plugins', 'concat:css'
  ])

  # copy release to LiveWhale
  grunt.registerTask('copy_to_lw', ['copy:js', 'copy:css', 'copy:images', 'copy:vendor'])

  # only compile the plugin less files that have changed
  grunt.event.on 'watch', (action, filepath) ->
    grunt.config ['less', 'plugins', 'files'], [
      src: filepath,
      dest: 'public/css/plugins/' + path.basename(filepath, '.less') + '.css'
    ]
    return
  return
