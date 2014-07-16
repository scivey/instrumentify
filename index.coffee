_ = require 'underscore'
fs = require 'fs'
ibrik = require 'ibrik'
istanbul = require 'istanbul'
through = require 'through2'
path = require 'path'

log = _.bind console.log, console

{InstrumentChooser} = require './lib/instrument'
{StreamBuilder} = require './lib/instrument'

instrumentify = (options) ->
    options ?= {}
    options = _.extend({
        coffeeExt: ['coffee']
        jsExt: ['js']
        basePath: null
    }, options)
    chooserOpts = _.pick options, 'coffeeExt', 'jsExt'
    chooser = new InstrumentChooser(chooserOpts)
    builder = new StreamBuilder {
        chooser: chooser,
        basePath: options.basePath
    }
    (fileName) ->
        builder.makeStream fileName

module.exports = instrumentify
