gulp = require 'gulp'
sync = require('browser-sync').create()
gutil = require 'gulp-util'
concat = require 'gulp-concat'
del = require 'rimraf'
plumber = require 'gulp-plumber'

templates = require 'gulp-{{cookiecutter.template_engine}}'
{% if cookiecutter.template_engine == 'twig' -%}
htmlmin = require 'gulp-htmlmin'
{%- endif %}

coffee = require 'gulp-coffee'
uglify = require 'gulp-uglify'

styles = require 'gulp-{% if cookiecutter.style_engine == "scss" %}sass{% else %}{{cookiecutter.style_engine}}{% endif %}'
embedImages = require 'gulp-css-inline-images'
cleancss = require 'gulp-clean-css'

templates_path = 'src/templates/**/*.{{cookiecutter.template_engine}}'
styles_path = 'src/styles/**/*.{{cookiecutter.style_engine}}'
scripts_path = 'src/scripts/**/*.coffee'

debug = process.env.NODE_ENV isnt 'prod';
gutil.log('WARN: Building in prod environment') if not debug

# Redefine gulp.src to keep pipes open on errors
if debug
  gulp._src = gulp.src
  gulp.src = (source)->
    gulp._src(source)
      .pipe plumber()
      .on 'error', gutil.log

# Remove contents of release dir
gulp.task 'clean_release', (done)-> del 'build', done

# Build html templates
gulp.task 'templates', (cb)->
  gulp.src templates_path
    .pipe templates
      {%- if cookiecutter.template_engine == 'twig' %}
      base: 'src/templates'
      data: {debug}
      errorLogToConsole: yes
      {%- elif cookiecutter.template_engine == 'pug' %}
      locals: {debug}
      basedir: 'src/templates'
      pretty: debug
      {%- elif cookiecutter.template_engine == 'haml' %}
      compilerOpts:
        locals: {debug}
        optimize: not debug
      {%- else -%}
        ()
      {%- endif %}
    .pipe gulp.dest('dist')

# Move templates to release path
gulp.task 'move_templates', ['clean_release', 'templates'], ->
  gulp.src 'dist/**/*.html'
    {% if cookiecutter.template_engine == 'twig' -%}
    .pipe htmlmin
      collapseWhitespace: yes
      minifyCSS: yes
      minifyJS: yes
      removeComments: yes
    {%- endif %}
    .pipe gulp.dest('build')

# Build coffee
gulp.task 'scripts', ->
  gulp.src scripts_path
    .pipe coffee(bare: yes)
    .pipe gulp.dest('dist/scripts')
    .pipe sync.reload(stream: yes)

# Minify and concat scripts
gulp.task 'min_scripts', ['clean_release', 'scripts'], ->
  gulp.src 'dist/scripts/**/*.js'
    .pipe uglify()
    .pipe concat('index.min.js')
    .pipe gulp.dest('build')

# Build styles
gulp.task 'styles', (cb)->
  gulp.src styles_path
    .pipe styles()
    {%- if cookiecutter.style_engine == 'sass' -%}
      .on('error', styles.logError)
    {%- endif %}
    .pipe embedImages(webRoot: './src')
    .pipe gulp.dest('dist/styles')
    .pipe sync.reload(stream: yes)

# Minify and concat styles
gulp.task 'min_styles', ['clean_release', 'styles'], ->
  gulp.src 'dist/styles/**/*.css'
    .pipe cleancss()
    .pipe concat('index.min.css')
    .pipe gulp.dest('build')

# Build everything
gulp.task 'build', ['scripts', 'styles', 'templates']

# TODO: templates
gulp.task 'build_release', ['clean_release', 'min_styles', 'min_scripts', 'move_templates']

# Start development server
gulp.task 'serve', ->
  sync.init
    open: no
    reloadOnRestart: yes
    server: {baseDir: 'dist'}

# Trigger livereload after templates are built
gulp.task 'reload', ['templates'], (done)->
  sync.reload()
  done()

# Watch for changes and rebuild files if nessesery
gulp.task 'watch', ->
  gulp.watch scripts_path, ['scripts']
  gulp.watch styles_path, ['styles']
  gulp.watch templates_path, ['reload']

# Start dev server and wait for changes
gulp.task 'default', ['serve', 'watch']
