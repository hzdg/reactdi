(function() {
  var def,
    _this = this,
    __hasProp = {}.hasOwnProperty,
    __slice = [].slice;

  def = function(factory) {
    if (typeof define === 'function' && define.amd) {
      return define(['react'], function(React) {
        return this.reactdi = factory(React);
      });
    } else if (typeof exports === 'object') {
      return module.exports = factory(require('react'));
    } else {
      return _this.reactdi = factory(_this.React);
    }
  };

  def(function(React) {
    var Injector, Mixin, activeInjectors, clone, indexOf, isComponentType, oldConstruct, parseMapArgs, reactdi, typesMatch, withInjector, withInjectors;
    clone = function(obj) {
      var k, result, v;
      result = {};
      for (k in obj) {
        if (!__hasProp.call(obj, k)) continue;
        v = obj[k];
        result[k] = v;
      }
      return result;
    };
    indexOf = [].indexOf || function(item) {
      var el, i, _i, _len;
      for (i = _i = 0, _len = this.length; _i < _len; i = ++_i) {
        el = this[i];
        if (i in this && el === item) {
          return i;
        }
      }
      return -1;
    };
    activeInjectors = [];
    isComponentType = function(val) {
      return typeof val === 'string' || React.isValidClass(val);
    };
    typesMatch = function(values, types) {
      var i, type, _i, _len;
      for (i = _i = 0, _len = types.length; _i < _len; i = ++_i) {
        type = types[i];
        if (!(type === '*' || type === typeof values[i])) {
          return false;
        }
      }
      return true;
    };
    parseMapArgs = function(mapArgTypes, fn) {
      return function() {
        var args, componentType, mapArgs, options, optsOrTest, test, _ref;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if ((args[0] == null) || isComponentType(args[0]) && typesMatch(args.slice(1, +mapArgTypes.length + 1 || 9e9), mapArgTypes)) {
          componentType = args.shift();
        }
        mapArgs = args.slice(0, mapArgTypes.length);
        _ref = args.slice(mapArgTypes.length), optsOrTest = _ref[0], test = _ref[1];
        if (typeof optsOrTest === 'function') {
          options = {};
          test = optsOrTest;
        } else {
          options = optsOrTest != null ? optsOrTest : {};
          if (test == null) {
            test = function() {
              return true;
            };
          }
        }
        return fn.call.apply(fn, [this, componentType].concat(__slice.call(mapArgs), [options], [test]));
      };
    };
    Mixin = React.__internals.Component.Mixin;
    oldConstruct = Mixin.construct;
    Mixin.construct = function() {
      var args, initialProps, injector, oldRender, props, _i;
      initialProps = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      props = initialProps || {};
      this._injectors = activeInjectors.slice(0);
      for (_i = activeInjectors.length - 1; _i >= 0; _i += -1) {
        injector = activeInjectors[_i];
        props = injector.buildProps(this, props);
        if (injector.isolate) {
          break;
        }
      }
      oldConstruct.call.apply(oldConstruct, [this, props].concat(__slice.call(args)));
      oldRender = this.render;
      this.render = function() {
        var args,
          _this = this;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return withInjectors(this._injectors, function() {
          return oldRender.call.apply(oldRender, [_this].concat(__slice.call(args)));
        });
      };
    };
    withInjectors = function(injectors, scopedCallback) {
      var result;
      activeInjectors.push.apply(activeInjectors, injectors);
      try {
        result = scopedCallback();
      } finally {
        activeInjectors = activeInjectors.slice(0, -injectors.length);
      }
      return result;
    };
    withInjector = function(injector, scopedCallback) {
      return withInjectors([injector], scopedCallback);
    };
    Injector = (function() {
      function Injector(options) {
        this.rules = [];
        this.isolate = !!(options != null ? options.isolate : void 0);
      }

      Injector.prototype.mapValues = parseMapArgs(['object'], function(componentType, props, options, test) {
        var k, v;
        for (k in props) {
          if (!__hasProp.call(props, k)) continue;
          v = props[k];
          this.mapValue(componentType, k, v, options, test);
        }
        return this;
      });

      Injector.prototype.mapValue = parseMapArgs(['string', '*'], function(componentType, propName, value, options, test) {
        var factory;
        factory = function() {
          return value;
        };
        this.mapFactory(componentType, propName, factory, options, test);
        return this;
      });

      Injector.prototype.mapFactory = parseMapArgs(['string', 'function'], function(componentType, propName, factory, options, test) {
        if (test == null) {
          test = function() {
            return true;
          };
        }
        this.rules.push({
          propName: propName,
          factory: factory,
          options: options,
          test: this.buildTest(test, componentType)
        });
        return this;
      });

      Injector.prototype.on = parseMapArgs(['string', 'function'], function(componentType, eventName, listener, options, test) {
        var factory, handlerName, newOptions;
        handlerName = "on" + (eventName.charAt(0).toUpperCase()) + eventName.slice(1);
        newOptions = clone(options);
        newOptions.override = true;
        factory = function(component, props) {
          var handler, i, listeners, oldHandler;
          handler = props[handlerName];
          if (!(listeners = handler != null ? handler.listeners : void 0)) {
            oldHandler = props[handlerName];
            handler = function() {
              var args, fn, _i, _len, _ref;
              args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
              _ref = handler.listeners;
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                fn = _ref[_i];
                fn.call.apply(fn, [this].concat(__slice.call(args)));
              }
            };
            listeners = handler.listeners = oldHandler ? [oldHandler] : [];
          }
          if ((i = indexOf.call(listeners, listener)) >= 0) {
            listeners.splice(i, 1);
          }
          listeners.push(listener);
          return handler;
        };
        return this.mapFactory(componentType, handlerName, factory, newOptions, test);
      });

      Injector.prototype.buildTest = function(test, componentType) {
        var _this = this;
        if (componentType == null) {
          return test;
        } else if (typeof componentType === 'string') {
          return function(component, props) {
            var _ref;
            return !!(componentType === ((_ref = component.constructor) != null ? _ref.displayName : void 0) && test(component, props));
          };
        } else {
          return function(component, props) {
            return !!(component instanceof componentType.componentConstructor && test(component, props));
          };
        }
      };

      Injector.prototype.buildProps = function(component, defaults) {
        var factory, options, propName, props, test, _i, _len, _ref, _ref1;
        props = clone(defaults);
        _ref = this.rules;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          _ref1 = _ref[_i], propName = _ref1.propName, factory = _ref1.factory, options = _ref1.options, test = _ref1.test;
          if ((options.override || !(propName in defaults)) && test(component, props)) {
            props[propName] = factory(component, props);
          }
        }
        return props;
      };

      Injector.prototype.inject = function(scopedCallback) {
        return reactdi.inject(this, scopedCallback);
      };

      Injector.create = function() {
        var args, inject, k, v, _ref, _ref1;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        inject = function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return inject.inject.apply(inject, args);
        };
        _ref = reactdi.Injector.prototype;
        for (k in _ref) {
          v = _ref[k];
          inject[k] = v;
        }
        (_ref1 = reactdi.Injector).call.apply(_ref1, [inject].concat(__slice.call(args)));
        return inject;
      };

      return Injector;

    })();
    reactdi = function() {
      var args, _ref;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return (_ref = reactdi.Injector).create.apply(_ref, args);
    };
    reactdi.Injector = Injector;
    reactdi.inject = function(injectorOrProps, scopedCallback) {
      var injector, props;
      if (injectorOrProps instanceof Injector || typeof injectorOrProps === 'function') {
        injector = injectorOrProps;
      } else {
        props = injectorOrProps;
        injector = new Injector;
        injector.mapValues(props, function() {
          return true;
        });
      }
      return withInjector(injector, scopedCallback);
    };
    return reactdi;
  });

}).call(this);
