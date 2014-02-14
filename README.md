reactdi
=======

Dependency injection for React components!

* Uses props instead of inventing a new concept
* Components don't need to know about reactdi so they stay portable
* No need to rewrite existing components

**WARNING: This project is experimental!**


## Why?

In [ReactJS], the data is normally passed directly from parent to child as
props. However, when working with large component trees, forwarding props to
descendants can become cumbersome and couple components unnecessarily.


## Example

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

The basic idea is this:

1. We create a reactdi injector and map properties to values
2. We use that in the `render()` method in place of `React.withContext`
3. Our `Child` gets its data from its `props` object as normal

If a prop isn't provided, the component will continue to use its default value
(from `getDefaultProps`). If you want to override an injected value, you can
just pass a value from the parent as usual.

This approach has two big benefits:

1. props are king. They're how data comes into your component—regardless of
   where it's coming from.
2. Components don't need to be rewritten to take advantage of dependency
   injection. Just wire them up at a higher level.

This kind of dependency injection makes your components super portable!
Injectors can even be nested—but don't go overboard! Keep your mappings together
to minimize [action at a distance][1].

*Note: we don't have to create the `di` instance in the `render()` method—if the
values are constant, it would probably be a good idea to do that in
`componentWillMount` instead.*


## Limiting Injection Scope

The example above showed how to inject a prop into subcomponents, but the
injection wasn't very targeted. With reactdi, you can (and probably should!)
specify that only specific component types be injected using either the class:

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

Now the `Grandparent` can know when one of its descendants has changed. Notice
that the `Parent` is blissfully unaware that this is happening; its callback
will execute normally.

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

This kind of event handling is great for responding to changes in your component
from higher in the component tree without coupling your components to the
response.


## API

Calling `reactdi` will return an injector. Below is the API for an injector
("di"):

<table>
    <tr>
        <th>Method</th>
        <th>Description</th>
    </tr>
    <tr>
        <td><code>di(<i>scopedCallback</i>)</code></td>
        <td>
            Injects all mapped props into any components created in the
            <code>scopedCallback</code> function. This is a shorcut for
            <code>di.inject()</code>.
        </td>
    </tr>
    <tr>
        <td><code>di.inject(<i>scopedCallback</i>)</code></td>
        <td>
            The long form of <code>di()</code>. This can be useful for chaining.
            For example:

            <code><pre>reactdi()
    .mapValue(Widget, 'someProp', 5)
    .on(Widget, 'change', handleChange)
    .inject(function () {
        return Button();
    });</pre></code>
        </td>
    </tr>
    <tr>
        <td><code>di.mapValue(<i>componentType</i>?, <i>propName</i>, <i>value</i>, <i>options</i>?, <i>test</i>?)</code></td>
        <td>
            Maps a particular prop value for injection.
            <code>componentType</code> may be either a React class or a
            displayName. If provided, the mapping will only be used for the
            matching components. For more fine-grained control, pass a
            <code>test</code> function that returns a boolean.
        </td>
    </tr>
    <tr>
        <td><code>di.mapValue(<i>componentType</i>?, <i>props</i>, <i>options</i>?, <i>test</i>?)</code></td>
        <td>
            Like <code>di.mapValue</code>, but maps several values at once.
            <code>props</code> is an object whose keys are prop names.
        </td>
    </tr>
    <tr>
        <td><code>di.mapFactory(<i>componentType</i>?, <i>propName</i>, <i>factory</i>, <i>options</i>?, <i>test</i>?)</code></td>
        <td>
            Like <code>di.mapValue</code>, but maps a factory function. This
            function will be invoked and the result used for the prop value.
            The factory function is passed the component and current props.
        </td>
    </tr>
    <tr>
        <td><code>di.on(<i>componentType</i>?, <i>eventName</i>, <i>listener</i>, <i>options</i>?, <i>test</i>?)</code></td>
        <td>
            Adds the provided listener as a callback for the given event.
            Callback names are derived from the <code>eventName</code> by
            prefixing "on" and capitalizing the first letter, so passing the
            event name `"change"` will result in a binding to the `onChange`
            prop.
        </td>
    </tr>
</table>


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

In this case, the `Child` component will get `props.subject` from the injector
in `Parent` but (since the `Parent` uses an isolate injector) it won't be
injected with `Grandparent`'s `greeting` prop. That means it'll render the
string `"hey world"`.


## vs `React.withContext`

React's solution to making sense of deep hierarchies is to use
`React.withContext`:

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

reactdi uses an alternative method for getting data to deeply nested components:
Instead of adding a special property (like `context`), you simply inject props.

Check out the [Example](#example) section of this document to see how to write
the above example using reactdi. It should look pretty similar!


[1]: http://en.wikipedia.org/wiki/Action_at_a_distance_(computer_programming)
[ReactJS]: http://reactjs.org
[callbacks]: http://facebook.github.io/react/docs/tutorial.html#callbacks-as-props
