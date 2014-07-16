_ = require 'underscore'
browserify = require 'browserify'
fs = require 'fs'
path = require 'path'
source = require 'vinyl-source-stream'
instrumentify = require '../'
concatStream = require 'concat-stream'
{assert} = require '../testUtil'

getResult = (cb) ->

    ENTRY = './data/src/app.js'
    OUT = './bundle.js'
    b = browserify {
        entries: [ENTRY]
        extensions: ['.js', '.coffee']
    }

    onFinish = concatStream (res) ->
        fs.writeFile './OUT.js', res, (err) ->
            cb(res)

    b
        .transform(instrumentify())
        .bundle({debug: true})
        .pipe( onFinish )


describe 'integration', ->
    data = {}
    before (done) ->
        @timeout 10000
        getResult (res) ->
            data.result = res
            data.text = res.toString()
            done()

    it 'returns a buffer', ->
        assert.isTrue Buffer.isBuffer(data.result)

    it 'includes all bundled files', ->
        shouldInclude = [
            'src/app.js'
            'src/mathFn.js'
            'src/otherFn.coffee'
            "require('./mathFn')"
            "require('./otherFn')"
        ]
        _.each shouldInclude, (str) ->
            assert.include data.text, str
