{assert} = require 'chai'
React = require 'react'
reactdi = require '../reactdi'


{div} = React.DOM
NONCE = {}


Component = React.createClass
  getInitialProps: ->
    default: 'value'
    nullDefault: null
  render: ->
    (div null, @props.children)


OtherComponent = React.createClass
  render: ->
    (div null, @props.message)


IsolatedContainer = React.createClass
  render: ->
    reactdi(isolate: true).inject =>
      OtherComponent()


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
          c = (Component null, (OtherComponent() ))
          html = React.renderComponentToString c
          assert.match html, /INJECTED/
    it "shouldn't inject into isolated children", ->
      reactdi()
        .map message: 'INJECTED'
        .inject ->
          c = (Component null, (IsolatedContainer() ))
          html = React.renderComponentToString c
          assert.notMatch html, /INJECTED/
