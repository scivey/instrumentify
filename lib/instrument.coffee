ibrik = require 'ibrik'
istanbul = require 'istanbul'
path = require 'path'
_ = require 'underscore'
through = require 'through2'

module.exports = exports = {}
exports.through = through


_.extend exports, {
    hasExt: (toMatch, fileName) ->
        ext = path.extname fileName
        ext.indexOf(toMatch) isnt -1
    testExt: (fileName, toMatch) ->
        exports.hasExt toMatch, fileName
    ensureList: (x) ->
        if _.isArray(x) then x else [x]
    hasAnyExt: (toMatch, fileName) ->
        toMatch = exports.ensureList(toMatch)
        _.any toMatch, _.partial(exports.testExt, fileName)
}

InstrumentChooser = (options) ->
    @_ = _
    options ?= {}
    @initialize(options)


_.extend InstrumentChooser.prototype, {
    initialize: (options) ->
        @coffeeExt = options.coffeeExt
        @jsExt = options.jsExt
        @initInstrumenters()
        this
    construct: (Cons, props) ->
        return new Cons(props)
    initInstrumenters: ->
        @_istanbul = @construct(istanbul.Instrumenter)
        @_ibrik = @construct(ibrik.Instrumenter)
        @_istanbulCallback = @instrumentCallback(@_istanbul)
        @_ibrikCallback = @instrumentCallback(@_ibrik)
    instrumentCallback: (instrumenter) ->
        (src, fileName, cb) ->
            instrumenter.instrument src, fileName, cb
        # @_.bind(instrumenter.instrument, instrumenter)
    choose: (fileName) ->
        choice = false
        if exports.hasAnyExt(@coffeeExt, fileName)
            choice = @_ibrikCallback
        if exports.hasAnyExt(@jsExt, fileName)
            choice = @_istanbulCallback
        choice
}
exports.InstrumentChooser = InstrumentChooser

StreamBuilder = (options) ->
    options ?= {}
    @initialize(options)

_.extend StreamBuilder.prototype, {
    initialize: (opts) ->
        @_chooser = opts.chooser
        this
    makeWriteFn: (dataTarget) ->
        (buf, enc, cb) ->
            if dataTarget or _.isArray(dataTarget)
                dataTarget.push buf
            else
                @push buf
            cb()
    makePassThroughCallback: ->
        (cb) ->
            cb()
    makeEndFn: (fileName, data, instrumentFn) ->
        (cb) ->
            contents = Buffer.concat(data).toString()
            self = this
            instrumentFn contents, fileName, (err, instrumented) ->
                self.push instrumented
                cb()
    doThrough: (write, end) ->
        exports.through(write, end)
    makeStream: (fileName) ->
        instrumentFn = @_chooser.choose(fileName)
        shouldInstrument = !!instrumentFn
        data = if shouldInstrument then [] else null
        write = @makeWriteFn(data)
        if shouldInstrument
            end = @makeEndFn fileName, data, instrumentFn
        else
            end = @makePassThroughCallback()
        stream = @doThrough(write, end)
        stream
}

exports.StreamBuilder = StreamBuilder