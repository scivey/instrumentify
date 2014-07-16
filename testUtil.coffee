_ = require 'underscore'
chai = require 'chai'
sinon = require 'sinon'

{assert} = chai
_.each sinon.assert, (fn, name) ->
    assert[name] = (args...) ->
        sinon.assert[name].apply(sinon.assert, args)

module.exports = {
    assert: assert
}