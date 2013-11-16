## LiveWhale UI

LiveWhale UI is a collection of jQuery plugins developed for the [LiveWhale Content Management System](http://www.livewhale.net).  This website provides usage examples, and API documentation for each plugin.  

## Dependencies

* jQuery >= 1.8
* jQuery UI 1.10 Widget Factory

## Development 

The plugins are written in [CoffeeScript](http://coffeescript.org), and each inherits from the [jQuery UI 1.10 widget factory](http://api.jqueryui.com/jQuery.widget/), which provides a framework that simplifies plugin development, and standardizes API interactions.  We use the JavaScript build tool [Grunt](http://gruntjs.com/) to compile and test the plugins, and to build the LiveWhale UI website.

To contribute to LiveWhale UI, make sure you have node v0.10 or greater and grunt-cli installed, and run the following in your terminal. 

```
$ git clone git@github.com:whitewhale/LiveWhaleUI.git
$ cd LiveWhaleUI 
$ npm install
$ grunt website
```

Create a virtual host that points to the location of the LiveWhaleUI folder.  You should now see the LiveWhale UI website when you visit the host's url in your browser.

### TODO

Explain website structure, assemble grunt package, and grunt watch.
