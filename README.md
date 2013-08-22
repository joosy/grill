# Grill

[![NPM version](https://badge.fury.io/js/grill.png)](http://badge.fury.io/js/grill)
[![Build Status](https://travis-ci.org/inossidabile/grill.png)](https://travis-ci.org/inossidabile/grill)

Grill is Node.js environment for convenient development of static front-end projects be that a RICH application or a statically generated blog. It is based on [Grunt](http://gruntjs.com), [Mincer](https://github.com/nodeca/mincer) and hope.

Grill sits in the middle between [Lineman](https://github.com/testdouble/lineman) and [Wintersmith](https://github.com/jnordberg/wintersmith). It's less opinionated and (much) more flexible than both of them. And that's exactly why it expects you to be more aware of community best-practices on your own. In fact you can think about **Grill** as if it was a **Grunt** plugin.

It can do this for you:

  * Enhance your JS and CSS assets with dependencies and includes (like [Sprockets](https://github.com/sstephenson/sprockets))
  * Serve assets from local development server
  * Serve greedy URLs suitable for HTML5 routing
  * Proxy requests to solve Cross-Origin issues
  * Stub backend API
  * Statically build the result
  * Prepare and deploy

And it has shortcuts for everything-else-based-on-Grunt. I.e. for tests we recommend the usage of [grunt-contrib-testem](https://github.com/inossidabile/grunt-contrib-testem) that plugs into the system as-is.

## What's behind Grill

<a href="http://joosy.ws"><img src="http://f.cl.ly/items/3X0f2K1z3r1X3K162W2c/logo.png" align="right" /></a>

Grill was developed as a building environment for **[Joosy](http://joosy.ws) Framework** standalone mode. We wanted to have an ability to share the dependency system between the framework core and project utilizing it. As the result we ended up using Grill to compile even **Joosy** itself. But you can use it for any framework and any project since **Mincer** approach is really the flexible and the powerful one.

## Why Grill?

  * Grill is based on [Mincer](https://github.com/nodeca/mincer)

    * Out of box it supports: CoffeeScript, Coco, JST, ECO, EJS, HAML, Jade, Less, Stylus, Sass. And it has powerful standardized API that you can easily extend with anything. Totally anything

    * Forget about laggy-buggy watchers for the development mode. Instead we serve stuff using Express.js middle-wares with on-the-fly compilation and intelligent caching

    * It mimics Sprockets. Not only it gives you incredibly powerful `#= require` preprocessing but also opens the door for people coming from Rails world (and be honest, Sprockets IS awesome)

  * Grill is a toolbelt not a framework

    * Flexible routing – we don't really have much conventions on placement of files. Only a small rule that helps you to organize stuff based on its content type

    * Grill stays out of your way. We don't override / reimplement / hide things like Grunt, Bower and npm from you. Instead we add a pinch of spice to that mix. Use best-practices and things you are used to in _conjuction_ with the new stuff Grill brings in

    * Because of this it's only about 200 LoC. Small things are easier to support so you can expect Grill to be more stable

## Installation

```
$ mkdir dummy
$ cd dummy
$ mkdir -p app/images app/javascripts app/stylesheets app/haml public
$ npm init
```

Now you should install proper npm packages. The total list of them depends on file formats you are going to use. Grill does not depend directly on everything so you have to manually install libraries that are required to compile what you want. In this example we use HamlCoffee, Stylus (with nib) and Coffee-Script.

```
$ npm install grunt grill haml-coffee stylus nib coffee-script --save-dev
```

And here's the look of initial Grunt config:

```javascript
module.exports = function(grunt) {
  grunt.loadNpmTasks('grill')

  grunt.initConfig({
    grill: {
      assets: {
        root: [ 'application.*' ]
      }
    }
  })
}
```

## How to use?

### Folder structure

In Grill you have an application folder (typically `app`) that consists of a set of subdirectories holding different type of assets. Like this:

```
|- app
|--- images
|--- haml
|--- javascripts
|--- stylesheets
```

You can put anything having supported extension to any of them and as the result it will get to the "output" directory (typically `public`). During compilation the first level of folders will be striped. So having this file tree:

```
|- app
|--- images
|------ test.png
|------ subdirectory
|-------- another.png
|--- haml
|------ index.haml
|--- javascripts
|------ application.coffee
```

would result into the following output:

```
|- public
|---- test.png
|---- subdirectory
|------ another.png
|---- index.html
|---- application.js
```

During the compilation of stylesheets and javascripts, Grill compiles only the root files (configuration option `assets.root`). Everything else gets compiled file to file unless it matches skip mask (configuration option `assets.skip`).

So try to put some HAML into `app/haml/index.haml`, and run `grunt grill:compile`. Then try to run `grunt grill:server` – your HAML is now compiled on-request at `http://localhost:4000`.

And did you notice you used Grunt directly? Go unleash the power of anything with thousands of available Grunt plugins.

### Understanding Mincer-way of handling assets

... :godmode:

### Commands

#### grunt grill:bower

Runs prouction-safe bower installer. Meant for the cases when you don't want to commit `bower_components` to your repo but want to run in during deployment instead.

#### grunt grill:server -> grunt grill:server:development

Runs development web-server on port 4000.

#### grunt grill:server:production

Runs production web-server that serves static files from `public` compressing them on the fly.

#### grunt grill:compile -> grunt grill:compile:development

Statically compiles your assets into `public`.

#### grunt grill:compile:production

Runs **grunt compile:development** if Node.js production environment is active. Does nothing otherwise.

#### grunt grill:clean

Cleans up `public`

### Options and features

#### Global config and environment

You can pass global data to those kind of assets that can handle it (currently HAML and Stylus).

```javascript
grill: {
  config: require('./config.json')
}
```

When used like that it globally defines `@config` variable within your assets. Additionaly Grill globally sets `@environment` variable. It's equal to 'development' when running from development server and 'production' during static build.

#### Assets configurations

```javascript
grill: {
  assets: {
    paths:  ['vendor/*'],       // Adds root-level inclusion paths
    roots:  ['application.*']   // The list of first-level JS and CSS assets
    skip:   ['_partials/**/*']  // List of files that should not be compiled statically
    greedy: ['url/']            // List of URLs that will respond to `url/*` unless another asset was found
  }
}
```

##### Use partials and layouts at HAML

You can't make a web-site without partials. That's why Grill bundles this...

```haml
!= @partial 'path/to/asset', {foo: 'bar'}
```

...into `.haml` kind of assets so you can use it keep your layout DRY. Also you can use the following syntax to wrap part of your page into a layout:

```haml
!= @layout 'path/to/layout.haml', {foo: 'bar'}, =>
  #page
    .goes Here
```

And in the end you might want to exclude that partials and layouts from compilation by using `skip: ['_partials/**/*']` at assets configuration section.

##### Use HTML5 routing

Say you want to make your application work with HTML5 pushState feature from the root url. Add `greedy: ['/']` to your assets configuration section. It will make development server fallback to index of resource if no another asset was found. Note that other assets will keep working – the asset having straight URL match will respond first.

#### Proxying Cross-Origin requests

There are several valid syntaxes to make development server proxy something:

```javascript
grill: {
  proxy: {
    '/path/from': 'http://host.com/path/to'
  }
  // or
  proxy: {
    src: '/path/from',
    dest: 'http://host.com/path/to'
  }
  // or 
  proxy: [{
    src: '/path/from',
    dest: 'http://host.com/path/to'
  }]
}
```

Use anyone you like and make it proxy!

#### Fine-tuning development server

You can directly assign middlewares to the internal Express.js server:

```javascript
grill: {
  middlewares: function(express) {
    // make express do anything for you
  }
}
```

Using this you can easily organize any kind of stubs.

### More examples

We use Grill to build [website of Joosy](https://github.com/joosy/website), [its Guides](https://github.com/joosy/guides) and even [Joosy](https://github.com/joosy/joosy) itself.

If you want to see Grill in action without all the hackery, you can give **Joosy** a try. Go to the [guides section](http://guides.joosy.ws) and follow the **standalone mode** branch.

## Maintainers

* Boris Staal, [@inossidabile](http://staal.io)
* Andrew Shaydurov, [@ImGearHead](http://twitter.com/ImGearHead)

## License

Copyright 2013 [Boris Staal](http://staal.io)

It is free software, and may be redistributed under the terms of MIT license.
