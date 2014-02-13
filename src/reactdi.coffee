def = (factory) =>
  if typeof define is 'function' && define.amd
    define ['react'], (React) ->
      @reactdi = factory React
  else if typeof exports is 'object'
    module.exports = factory require('react')
  else
    @reactdi = factory @React

def (React) ->

  clone = (obj) ->
    result = {}
    for own k, v of obj
      result[k] = v
    result

  injectors = []

  # Patch the class factory to add dependencies to props dict.
  oldCreateClass = React.createClass
  React.createClass = (args...) ->
    Cls = oldCreateClass args...
    constructor = Cls.componentConstructor

    oldConstruct = constructor::construct
    constructor::construct = (initialProps, args...) ->
      props = initialProps or {}
      for injector in injectors by -1
        props = injector.buildProps this, props
        break if injector.isolate
      oldConstruct.call this, props, args...

    Cls

  withInjector = (injector, scopedCallback) ->
    injectors.push injector
    try result = scopedCallback()
    finally injectors.pop()
    result

  class Injector
    constructor: (options) ->
      @rules = []
      @isolate = !!options?.isolate

    map: (props, optsOrTest, test) ->
      for own k, v of props
        @mapValue k, v, optsOrTest, test
      this

    # Map a value.
    #
    # @param {string}    prop    The property name.
    # @param {*}         value   The value to inject.
    # @param {?object}   options Mapping options.
    # @param {?function} test    A function that determines whether the props
    #                            should be injected.
    mapValue: (propName, value, optsOrTest, test) ->
      factory = -> value
      @mapFactory propName, factory, optsOrTest, test
      this

    mapFactory: (propName, factory, optsOrTest, test) ->
      if typeof optsOrTest is 'function'
        options = {}
        test = optsOrTest
      else
        options = optsOrTest ? {}
        test ?= -> true
      @rules.push {propName, factory, options, test: @buildTest(test, options)}
      this

    ruleMatches: (ruleOptions, args...) -> true

    buildTest: (test, ruleOptions) ->
      (args...) => !!(@ruleMatches(ruleOptions, args...) or test args...)

    buildProps: (component, defaults) ->
      props = clone defaults
      for {propName, factory, options, test} in @rules
        if (options.override or propName not of defaults) and test(component, props)
          props[propName] = factory component, props
      props

    inject: (scopedCallback) ->
      reactdi.inject this, scopedCallback

    @create = (args...) ->
      # Create an injector shortcut function
      inject = (args...) -> inject.inject args...

      # Mix the Injector functionality into the functon.
      inject[k] = v for k, v of reactdi.Injector.prototype
      reactdi.Injector.call inject, args...

      inject

  # Assemble and return the module.
  reactdi = (args...) -> reactdi.Injector.create args...
  reactdi.Injector = Injector
  reactdi.inject = (injectorOrProps, scopedCallback) ->
    if injectorOrProps instanceof Injector or typeof injectorOrProps is 'function'
      # This is either an Injector instance or shortcut inject function; not a
      # props object.
      injector = injectorOrProps
    else
      props = injectorOrProps
      injector = new Injector
      injector.map props, -> true

    withInjector injector, scopedCallback
  reactdi
