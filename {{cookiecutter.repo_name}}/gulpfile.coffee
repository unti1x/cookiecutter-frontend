gulp = require 'gulp'
templates = require 'gulp-{{cookiecutter.template_engine}}'
coffee = require 'gulp-coffee'
styles = require 'gulp-{% if cookiecutter.style_engine == "scss" %}sass{% else %}{{cookiecutter.style_engine}}{% endif %}'
sync = require('browser-sync').create()
embedImages = require 'gulp-css-inline-images'
gutil = require 'gulp-util'

templates_path = 'src/templates/**/*.{{cookiecutter.template_engine}}'
styles_path = 'src/styles/**/*.{{cookiecutter.style_engine}}'
scripts_path = 'src/scripts/**/*.coffee'

debug = process.env.ENV isnt 'prod';
gutil.log('WARN: Building in prod environment') if not debug

# Build html templates
gulp.task 'templates', (cb)->
  gulp.src templates_path
    .pipe templates(
      {%- if cookiecutter.template_engine == 'twig' %}
      base: 'src/templates'
      data: {debug}
      errorLogToConsole: yes
      {%- endif -%}
    )
    .pipe gulp.dest('dist')

# Build coffee
gulp.task 'scripts', (cb)->
  gulp.src scripts_path
    .pipe coffee(bare: yes)
    .pipe gulp.dest('dist/scripts')
    .pipe sync.reload(stream: yes)

# Build styles
gulp.task 'styles', (cb)->
  gulp.src styles_path
    .pipe styles()
    {%- if cookiecutter.style_engine == 'sass' -%}
      .on('error', styles.logError)
    {%- endif %}
    .pipe embedImages(webRoot: '.')
    .pipe gulp.dest('dist/styles')
    .pipe sync.reload(stream: yes)

gulp.task 'build', ['scripts', 'styles', 'templates']

gulp.task 'serve', ->
  sync.init
    open: no
    reloadOnRestart: yes
    server: {baseDir: 'dist'}

gulp.task 'reload', ['templates'], (cb)->
  sync.reload()
  cb()

gulp.task 'watch', ->
  gulp.watch scripts_path, ['scripts']
  gulp.watch styles_path, ['styles']
  gulp.watch templates_path, ['reload']

gulp.task 'default', ['serve', 'watch']
