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

  indexOf = [].indexOf or (item) ->
    for el, i in this
      return i if i of this and el is item
    return -1

  injectors = []

  # Can the value be used to filter component types? Valid values are component
  # classes and strings (which will be matched against the display name).
  isComponentType = (val) -> typeof val is 'string' or React.isValidClass val

  typesMatch = (values, types) ->
    for type, i in types
      return false unless type is '*' or type is typeof values[i]
    return true

  # A utility for parsing args for the map* methods. Returns a new function
  # that invokes the provided one with the correct positional args.
  #
  # The map* functions have signatures that look like this:
  #
  #     (componentType?, mapArgs..., options?, test?)
  #
  # This function accounts for missing optional args and normalizes the
  # signature.
  parseMapArgs = (mapArgTypes, fn) ->
    (args...) ->
      componentType = args.shift() if not args[0]? or isComponentType(args[0]) and typesMatch args[1..mapArgTypes.length], mapArgTypes
      mapArgs = args[...mapArgTypes.length]
      [optsOrTest, test] = args[mapArgTypes.length...]

      if typeof optsOrTest is 'function'
        options = {}
        test = optsOrTest
      else
        options = optsOrTest ? {}
        test ?= -> true

      fn.call this, componentType, mapArgs..., options, test

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

    map: parseMapArgs ['object'], (componentType, props, options, test) ->
      for own k, v of props
        @mapValue componentType, k, v, options, test
      this

    # Map a value.
    #
    # @param {string}    prop    The property name.
    # @param {*}         value   The value to inject.
    # @param {?object}   options Mapping options.
    # @param {?function} test    A function that determines whether the props
    #                            should be injected.
    mapValue: parseMapArgs ['string', '*'], (componentType, propName, value, options, test) ->
      factory = -> value
      @mapFactory componentType, propName, factory, options, test
      this

    mapFactory: parseMapArgs ['string', 'function'], (componentType, propName, factory, options, test) ->
      test ?= -> true
      @rules.push {propName, factory, options, test: @buildTest(test, componentType)}
      this

    on: parseMapArgs ['string', 'function'], (componentType, eventName, listener, options, test) ->
      handlerName = "on#{ eventName.charAt(0).toUpperCase() }#{ eventName[1..] }"
      newOptions = clone options
      newOptions.override = true
      factory = (component, props) ->
        # Set up the listener chain by creating a new 
        handler = props[handlerName]
        unless listeners = handler?.listeners
          oldHandler = props[handlerName]
          props[handlerName] = newHandler = (args...) ->
            do (listener) =>
              for listener in newHandler.listeners
                listener.call this, args...
            return
          # newHandler.listeners = [oldHandler]
          newHandler.listeners = if oldHandler then [oldHandler] else []
          # Call the factory recursively to add the new handler.
          return factory component, props

        # Add the listener to the list. If it's already there, remove it
        # first.
        listeners.splice i, 1 if (i = indexOf.call listeners, listener) >= 0
        listeners.push listener
        handler

      @mapFactory componentType, handlerName, factory, newOptions, test

    buildTest: (test, componentType) ->
      if not componentType?
        test
      else if typeof componentType is 'string'
        (component, props) =>
          !!(componentType is component.constructor?.displayName and test component, props)
      else
        (component, props) =>
          !!(component instanceof componentType.componentConstructor and test component, props)

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
