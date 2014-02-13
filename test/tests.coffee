{assert} = require 'chai'
React = require 'react'
reactdi = require '../reactdi'


{div} = React.DOM
NONCE = {}


Component = React.createClass
  getDefaultProps: ->
    default: 'value'
    nullDefault: null
  render: ->
    (div null, @props.children)

MessageContainer = React.createClass
  displayName: 'mc'
  render: ->
    (div null, @props.message)

MessageContainer2 = React.createClass
  displayName: 'mc2'
  render: ->
    (div null, @props.message)

IsolatedContainer = React.createClass
  render: ->
    reactdi(isolate: true).inject =>
      MessageContainer()

Dog = React.createClass
  render: -> (div() )


describe 'reactdi', ->
  it 'should return an injector function', ->
    assert.typeOf reactdi(), 'function'

  describe 'an injector', ->
    it 'should inject missing props', ->
      reactdi()
        .map newProp: NONCE
        .inject ->
          c = Component()
          React.renderComponentToString c
          assert.equal c.props.newProp, NONCE
    it 'should be an injection function itself', ->
      di = reactdi().map newProp: NONCE
      di ->
        c = Component()
        React.renderComponentToString c
        assert.equal c.props.newProp, NONCE
    it "shouldn't override null values", ->
      reactdi()
        .map nullDefault: NONCE
        .inject ->
          c = Component()
          React.renderComponentToString c
          assert.equal c.props.newProp, null
    it 'should inject into children', ->
      reactdi()
        .map message: 'INJECTED'
        .inject ->
          c = (Component null, (MessageContainer() ))
          html = React.renderComponentToString c
          assert.match html, /INJECTED/
    it "shouldn't inject into isolated children", ->
      reactdi()
        .map message: 'INJECTED'
        .inject ->
          c = (Component null, (IsolatedContainer() ))
          html = React.renderComponentToString c
          assert.notMatch html, /INJECTED/
    it 'should support injection by class', ->
      reactdi()
        .map MessageContainer2, message: 'INJECTED'
        .inject ->
          c = (MessageContainer() )
          c2 = (MessageContainer2() )
          assert.notMatch React.renderComponentToString(c), /INJECTED/
          assert.match React.renderComponentToString(c2), /INJECTED/
    it 'should support injection by displayName', ->
      reactdi()
        .map 'mc2', message: 'INJECTED'
        .inject ->
          c = (MessageContainer() )
          c2 = (MessageContainer2() )
          assert.notMatch React.renderComponentToString(c), /INJECTED/
          assert.match React.renderComponentToString(c2), /INJECTED/
    it 'should allow the addition of event handlers', ->
      barkCount = 0
      injectedBarkCount = 0
      reactdi()
        .on 'bark', => injectedBarkCount += 1
        .inject ->
          winston = (Dog onBark: -> barkCount += 1)
          winston.props.onBark()  # Normally this would be called from within the component, e.g. on user interaction.
          assert.equal barkCount, 1
          assert.equal injectedBarkCount, 1
    it 'should allow the nested addition of event handlers', ->
      barkCount = 0
      injectedBarkCount = 0
      reactdi()
        .on 'bark', => injectedBarkCount += 1
        .inject ->
          reactdi()
            .on 'bark', => injectedBarkCount += 1
            .inject ->
              winston = (Dog onBark: -> barkCount += 1)
              winston.props.onBark()
              assert.equal barkCount, 1
              assert.equal injectedBarkCount, 2
