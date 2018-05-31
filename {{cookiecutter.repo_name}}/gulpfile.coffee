gulp = require 'gulp'
sync = require('browser-sync').create()
log = require 'fancy-log'
concat = require 'gulp-concat'
del = require 'del'
plumber = require 'gulp-plumber'

templates = require 'gulp-{{cookiecutter.template_engine}}'
htmlmin = require 'gulp-htmlmin'

coffee = require 'gulp-coffee'
uglify = require 'gulp-uglify'

styles = require 'gulp-{% if cookiecutter.style_engine == "scss" %}sass{% else %}{{cookiecutter.style_engine}}{% endif %}'
embedImages = require 'gulp-css-inline-images'
cleancss = require 'gulp-clean-css'

templates_path = 'src/templates/**/*.{{cookiecutter.template_engine}}'
styles_path = 'src/styles/**/*.{{cookiecutter.style_engine}}'
scripts_path = 'src/scripts/**/*.coffee'

debug = process.env.NODE_ENV isnt 'prod';
log.warn('Building in prod environment') if not debug

# Redefine gulp.src to keep pipes open on errors
if debug
  gulp._src = gulp.src
  gulp.src = (source)->
    gulp._src(source)
      .pipe plumber()
      .on 'error', log.error

# Remove contents of release dir
gulp.task 'clean_release', -> del 'build'

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
move_templates = ->
  gulp.src 'dist/**/*.html'
    {% if cookiecutter.template_engine == 'twig' -%}
    .pipe htmlmin
      collapseWhitespace: yes
      minifyCSS: yes
      minifyJS: yes
      removeComments: yes
    {%- endif %}
    .pipe gulp.dest('build')

gulp.task 'move_templates', gulp.series('clean_release', 'templates', move_templates)

# Build coffee
build_scripts = ->
  gulp.src scripts_path
    .pipe coffee(bare: yes)
    .pipe gulp.dest('dist/scripts')
    .pipe sync.reload(stream: yes)

gulp.task 'scripts', build_scripts

# Minify and concat scripts
min_scripts = ->
  gulp.src 'dist/scripts/**/*.js'
    .pipe uglify()
    .pipe concat('index.min.js')
    .pipe gulp.dest('build')

gulp.task 'min_scripts', gulp.series('clean_release', 'scripts', min_scripts)

# Build styles

build_styles = ->
  gulp.src styles_path
    .pipe styles()
    {%- if cookiecutter.style_engine == 'sass' -%}
      .on('error', styles.logError)
    {%- endif %}
    .pipe embedImages(webRoot: './src')
    .pipe gulp.dest('dist/styles')
    .pipe sync.reload(stream: yes)

gulp.task 'styles', build_styles

# Minify and concat styles
min_styles = ->
  gulp.src 'dist/styles/**/*.css'
    .pipe cleancss()
    .pipe concat('index.min.css')
    .pipe gulp.dest('build')

gulp.task 'min_styles', gulp.series('clean_release', 'styles', min_styles)

# Build everything
gulp.task 'build', gulp.parallel('scripts', 'styles', 'templates')

# TODO: templates
gulp.task 'build_release', gulp.series(
  'clean_release',
  gulp.parallel('min_styles', 'min_scripts', 'move_templates')
)

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

gulp.task 'reload', gulp.series('templates', sync.reload)

# Watch for changes and rebuild files if nessesery
watch_scripts = ->
  gulp.watch scripts_path, build_scripts

watch_styles = ->
  gulp.watch styles_path, build_styles

watch_templates = ->
  gulp.watch templates_path, gulp.series('templates', sync.reload)

gulp.task 'watch', gulp.parallel(watch_scripts, watch_styles, watch_templates)

# Start dev server and wait for changes
gulp.task 'default', gulp.parallel('serve', 'watch')
