def = (factory) =>
  if typeof define is 'function' && define.amd
    define ['react'], (React) ->
      @reactdi = factory React
  else if typeof exports is 'object'
    module.exports = factory require('react')
  else
    @reactdi = factory @React

def (React) ->
  {}
