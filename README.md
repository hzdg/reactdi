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
var GrandParent = React.createClass({
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
var GrandParent = React.createClass({
    render: function () {
        var di = reactdi().map({greeting: 'hello'});
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
var GrandParent = React.createClass({
    render: function () {
        var di = reactdi().map({greeting: 'hello'});
        return di(function () {
            return Parent();
        });
    }
});

var Parent = React.createClass({
    render: function () {
        var di = reactdi().map({subject: 'world'});
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
`props.greeting` from the injector in `GrandParent`.

Sometimes, though, you may not want properties to be be passed down the
hierarchy forever. In those cases, you can create isolated injectors:

```javascript
var GrandParent = React.createClass({
    render: function () {
        var di = reactdi().map({greeting: 'hello'});
        return di(function () {
            return Parent();
        });
    }
});

var Parent = React.createClass({
    render: function () {
        var di = reactdi({isolate: true}).map({subject: 'world'});
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
be injected with `GrandParent`'s `greeting` prop. That means it'll render the
string `"hey world"`.


## Limiting Injection Scope

TODO


## Events

TODO


[ReactJS]: http://reactjs.org
