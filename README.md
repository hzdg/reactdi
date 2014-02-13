reactdi
=======

Dependency injection for React components.

**WARNING: This project is experimental!**


## Why?

In [ReactJS], the data is normally passed directly from parent to child as
props. However, when working with large component trees, forwarding props to
descendants can become cumbersome and couple components unnecessarily. React's
solution to this is to use `React.withContext`:

```javascript
var Grandparent = React.createClass({
    render: function () {
        return React.withContext({greeting: 'hello'}, function () {
            return Parent();
        });
    }
});

var Parent = React.createClass({
    render: function () {
        return Child();
    }
});

var Child = React.createClass({
    render: function () {
        return div(null, this.context.greeting);
    }
});
```

In this example, `Child` will render the `"hello"` greeting even though it
wasn't passed via props.

While this approach works, your components now need to know what data they get
from props and what comes from context. If you change your mind about how data
is given to the component, you need to rewrite your component. Components that
want to support both will have to be written to do so.

**reactdi uses an alternative method for getting data to deeply nested
components:** Instead of adding a special property (like `context`), you simply
inject props.


## Example

The usage for reactdi should be very familiar. Here are our previous components
rewritten to use reactdi:

```javascript
var Grandparent = React.createClass({
    render: function () {
        var di = reactdi().mapValues({greeting: 'hello'});
        return di(function () {
            return Parent();
        });
    }
});

var Parent = React.createClass({
    render: function () {
        return Child();
    }
});

var Child = React.createClass({
    render: function () {
        return div(null, this.props.greeting);
    }
});
```

As you can see, there are only a few differences from before: 1) we create a
reactdi injector and map properties to values, 2) we use that in the `render()`
method in place of `React.withContext`, and 3) our `Child` gets its data from
its `props` object instead of `context`. If a prop isn't provided, the component
will continue to use its default value (from `getDefaultProps`). If you want to
override an injected value, you can just pass a value from the parent as usual.

*Note: we don't have to create the `di` instance in the `render()` method—if the
values are constant, it would probably be a good idea to do that in
`componentWillMount` instead.*

This approach has two big benefits:

1. props are king. They're how data comes into your component—regardless of
   where it's coming from.
2. Components don't need to be rewritten to take advantage of dependency
   injection. Just wire them up at a higher level.


## Isolate Injectors

There's no rule that says you can only have one injector for your hierarchy—feel
free to create as many as you want. Normally, components will receive props from
all of the injectors above them in the tree:


```javascript
var Grandparent = React.createClass({
    render: function () {
        var di = reactdi().mapValues({greeting: 'hello'});
        return di(function () {
            return Parent();
        });
    }
});

var Parent = React.createClass({
    render: function () {
        var di = reactdi().mapValues({subject: 'world'});
        return di(function () {
            return Child();
        });
    }
});

var Child = React.createClass({
    render: function () {
        return div(null, this.props.greeting + ', ' + this.props.subject);
    }
});
```

Here, `Child` will get `props.subject` from the injector in `Parent` and
`props.greeting` from the injector in `Grandparent`.

Sometimes, though, you may not want properties to be be passed down the
hierarchy forever. In those cases, you can create isolated injectors:

```javascript
var Grandparent = React.createClass({
    render: function () {
        var di = reactdi().mapValues({greeting: 'hello'});
        return di(function () {
            return Parent();
        });
    }
});

var Parent = React.createClass({
    render: function () {
        var di = reactdi({isolate: true}).mapValues({subject: 'world'});
        return di(function () {
            return Child();
        });
    }
});

var Child = React.createClass({
    getDefaultProps: function () {
        return {
            greeting: 'hey',
            subject: 'you'
        }
    },
    render: function () {
        return div(null, this.props.greeting + ', ' + this.props.subject);
    }
});
```

In this case, the `Child` component will get `props.punctuation` from the
injector in `Parent` but (since the `Parent` uses an isolate injector) it won't
be injected with `Grandparent`'s `greeting` prop. That means it'll render the
string `"hey world"`.


## Limiting Injection Scope

Another drawback of React's `withContext` is that it doesn't allow for very
targeted injection. With reactdi, you can specify that only specific component
types be injected using either the class:

```javascript
var di = reactdi()
    .mapValues(MyWidget, {greeting: 'hello'});
```

…or the `displayName`:

```javascript
var di = reactdi()
    .mapValues('mywidget', {greeting: 'hello'});
```

For cases when this isn't enough, you can provide your own test function, which
will be passed the component instance and its current props:

```javascript
var di = reactdi()
    .mapValues({greeting: 'hello'}, function (component, props) {
        if (someCondition) {
            return true;
        }
        return false;
    });
```


## Events

By default, reactdi will only inject props that aren't set explicitly by the
parent component. You can force it to override those values by passing
`{override: true}` as an option when configuring your mappings. However, there's
one common case where you don't want either of these behaviors: event handling.

In ReactJS, event handling is done by [passing callbacks as props][callbacks].
This works out fine as long as only one thing (the parent component) needs to
listen. But with reactdi, you now have access to deeply nested components from
other locations. In order to let you hook into component events without
overriding the handlers their parents have set, reactdi provides the `on`
method:

```javascript
var Grandparent = React.createClass({
    render: function () {
        var di = reactdi()
            .on('change', function () { console.log('something changed!') });
        return di(function () {
          return Parent();
        });
    }
});

var Parent = React.createClass({
    handleChildChange: function () {
        console.log('my kid changed!');
    },
    render: function () {
      return Child({onChange: this.handleChildChange});
    }
});

var Child = React.createClass({
    handleClick: function () {
        this.props.onChange();
    },
    render: function () {
        return div({onClick: this.handleClick});
    }
});
```

Now the `Grandparent` can know when one of its descendants has changed without.
Notice that the `Parent` is blissfully unaware that this is happening; its
callback will execute normally.

Like the `map*` functions, `on` can be easily scoped to particular component
types:

```javascript
var Grandparent = React.createClass({
    render: function () {
        var di = reactdi()
            .on(Child, 'change', function () { console.log('a Child changed!') });
        return di(function () {
          return Parent();
        });
    }
});
```


[ReactJS]: http://reactjs.org
[callbacks]: http://facebook.github.io/react/docs/tutorial.html#callbacks-as-props
