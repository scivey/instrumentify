instrument = require '../lib/instrument'
_ = require 'underscore'
sinon = require 'sinon'
chai = require 'chai'
{assert} = require '../testUtil'

describe 'instrument', ->

    stub = ->

    beforeEach ->
        @_stubs = stubList = []
        stub = (ref, method) ->
            aStub = sinon.stub ref, method
            stubList.push aStub
            aStub

    afterEach ->
        _.each @_stubs, (aStub) ->
            aStub.restore()

    it '#ensureList works', ->
        x = [5]
        assert.equal instrument.ensureList(x), x

        y = 7
        assert.deepEqual instrument.ensureList(y), [7]

    describe '#hasExt', ->
        {hasExt} = instrument
        it 'returns true if file has ext', ->
            file = 'foo.bar'
            assert.isTrue hasExt('bar', file)

        it 'returns false otherwise', ->
            file = 'foo.baz'
            assert.isFalse hasExt('bar', file)

    describe '#testExt', ->
        hasExt = ->

        beforeEach ->
            hasExt = stub(instrument, 'hasExt')

        it 'works', ->
            instrument.testExt('x', 'y')
            assert.calledWith(hasExt, 'y', 'x')

    describe '#hasAnyExt', ->
        {hasAnyExt} = instrument
        it 'works', ->
            exts = ['bar', 'baz', 'bop']
            file = 'foo.baz'
            file2 = 'foo.bop'
            badFile = 'foo.woz'
            assert.isTrue hasAnyExt(exts, file)
            assert.isTrue hasAnyExt(exts, file2)
            assert.isFalse hasAnyExt(exts, badFile)


    describe 'StreamBuilder', ->
        {StreamBuilder} = instrument
        builder = {}
        beforeEach ->
            builder = new StreamBuilder()
        it '#initialize works', ->
            chooser = {chooser: true}
            builder.initialize({chooser: chooser})
            assert.equal builder._chooser, chooser

        describe '#makeWriteFn', ->
            data = {}
            ctx = {}
            beforeEach ->
                data = {
                    push: sinon.stub()
                }
                ctx = {
                    push: sinon.stub()
                }
            it 'works - instrumenting', ->
                fn = builder.makeWriteFn(data)
                enc = 'ENC'
                buf = 'SOME_BUFF'
                cb = sinon.stub()
                fn.apply(ctx, [buf, enc, cb])
                assert.calledWith(data.push, buf)
                assert.calledOnce(cb)
                assert.notCalled(ctx.push)

            it 'works - not instrumenting', ->
                fn = builder.makeWriteFn null
                enc = 'ENC'
                buf = 'SOME_BUFF'
                cb = sinon.stub()
                fn.apply ctx, [buf, enc, cb]
                assert.calledWith(ctx.push, buf)
                assert.calledOnce(cb)

        describe '#makePassThroughCallback', ->
            it 'works', ->
                passthrough = builder.makePassThroughCallback()
                fn = sinon.stub()
                passthrough(fn)
                assert.calledOnce(fn)
        describe '#doThrough', ->
            throughFn = ->
            beforeEach ->
                throughFn = stub(instrument, 'through')
            it 'works', ->
                aStream = {aStream: true}
                throughFn
                    .withArgs('WRITE', 'END')
                    .returns(aStream)
                result = builder.doThrough('WRITE', 'END')
                assert.equal result, aStream

        describe '#makeEndFn', ->
            catBuffer = ->
            ctx = {}
            beforeEach ->
                catBuffer = stub(Buffer, 'concat')
                ctx = {
                    push: sinon.stub()
                }
            it 'works', ->
                data = {data: true}
                code = {code: true}
                catBuffer.withArgs(data).returns {
                    toString: sinon.stub().returns(code)
                }
                instrumented = {instrumented: true}
                instrumentFn = sinon.stub()
                instrumentFn
                    .callsArgWith 2, null, instrumented
                endFn = builder.makeEndFn 'fileName', data, instrumentFn
                cb = sinon.stub()
                endFn.apply(ctx, [cb])
                assert.calledWith(instrumentFn, code, 'fileName', sinon.match.func)
                assert.calledWith ctx.push, instrumented

        describe '#makeStream', ->
            choose = ->
            instrumentFn = ->
            beforeEach ->
                choose = sinon.stub()
                instrumentFn = sinon.stub()
                _.extend builder, {
                    _chooser: {
                       choose: choose
                    }
                    makeWriteFn: sinon.stub()
                    makeEndFn: sinon.stub()
                    makePassThroughCallback: sinon.stub()
                    doThrough: sinon.stub()
                }

            it 'works', ->
                fileName = 'some_file'
                choose.withArgs(fileName)
                    .returns(instrumentFn)

                writer = sinon.stub()
                end = sinon.stub()
                builder.makeEndFn.returns(end)
                builder.makeWriteFn
                    .withArgs([]).returns(writer)
                aStream = {aStream: true}
                builder.doThrough
                    .withArgs(writer, end)
                    .returns(aStream)
                result = builder.makeStream fileName
                assert.equal result, aStream

            it 'works - not instrumenting', ->
                fileName = 'some_file'
                choose.withArgs(fileName)
                    .returns(false)

                writer = sinon.stub()
                end = sinon.stub()
                builder.makePassThroughCallback.returns(end)
                builder.makeWriteFn
                    .withArgs(null).returns(writer)
                aStream = {aStream: true}
                builder.doThrough
                    .withArgs(writer, end)
                    .returns(aStream)
                result = builder.makeStream fileName
                assert.equal result, aStream

    describe 'InstrumentChooser', ->
        {InstrumentChooser} = instrument
        chooser = {}
        opts = {}
        beforeEach ->
            opts = {}
            chooser = new InstrumentChooser(opts)

        it '#initialize works', ->
            jsExt = {jsExt: true}
            coffeeExt= {coffeeExt: true}
            chooser.initInstrumenters = sinon.stub()
            opts2 = {
                jsExt: jsExt
                coffeeExt: coffeeExt
            }
            chooser.initialize(opts2)
            assert.equal chooser.jsExt, jsExt
            assert.equal chooser.coffeeExt, coffeeExt
            assert.calledOnce chooser.initInstrumenters

        it '#construct works', ->
            Cons = (opts) ->
                @init = sinon.stub()
                @init(opts)
            opts = {opts: true}
            cons = chooser.construct Cons, opts
            assert.calledWith cons.init, opts

        it '#initInstrumenters works', ->
            istanbul = require 'istanbul'
            ibrik = require 'ibrik'

            chooser.construct = sinon.stub()
            chooser.instrumentCallback = sinon.stub()

            istan = {stan: true}
            ibr = {ibr: true}

            chooser.construct
                .withArgs(istanbul.Instrumenter).returns(istan)
                .withArgs(ibrik.Instrumenter).returns(ibr)


            ibrCallback = {ibrCallback: true}
            istanCallback = {istanCallback: true}
            chooser.instrumentCallback
                .withArgs(ibr).returns(ibrCallback)
                .withArgs(istan).returns(istanCallback)
            chooser.initInstrumenters()
            assert.equal chooser._istanbulCallback, istanCallback
            assert.equal chooser._ibrikCallback, ibrCallback
            assert.equal chooser._istanbul, istan
            assert.equal chooser._ibrik, ibr

        it '#instrumentCallback works', ->
            anInstrumenter = {
                val: 10
                instrument: (x) ->
                    @val += x
            }
            cb = chooser.instrumentCallback(anInstrumenter)
            cb(15)
            assert.equal(anInstrumenter.val, 25)

        describe '#choose', ->
            hasAnyExt = ->
            beforeEach ->
                hasAnyExt = stub(instrument, 'hasAnyExt')
                _.extend chooser, {
                    _ibrikCallback: 'ibrikCallback'
                    _istanbulCallback: 'istanbulCallback'
                    coffeeExt: 'coffeeExt'
                    jsExt: 'jsExt'
                }
            it 'works - coffee', ->
                file = 'aFile'
                hasAnyExt
                    .withArgs('coffeeExt', 'aFile')
                        .returns(true)
                result = chooser.choose(file)
                assert.equal result, 'ibrikCallback'

            it 'works - js', ->
                file = 'aFile'
                hasAnyExt
                    .withArgs('jsExt', 'aFile')
                        .returns(true)
                result = chooser.choose(file)
                assert.equal result, 'istanbulCallback'

            it 'works - none', ->
                hasAnyExt.returns(false)
                result = chooser.choose('someFile')
                assert.isFalse result

