# {{cookiecutter.project_name}}
{{cookiecutter.description}}

# Build
```bash
npm start
```
It will build all the styles, scripts and templates, then
start local development server on `localhost:3000` with `livereload`. You may also prepend `NODE_ENV=prod` to build templates without `livereload` and with production paths.

```bash
npm run release
```
It is a shortcut for
```bash
NODE_ENV=prod node_modules/.bin/gulp build_release
```
