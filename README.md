# talents
Pluggable contextual talents implementation for Lua.

[![Build Status](https://travis-ci.org/marcoonroad/talents.svg?branch=master)](https://travis-ci.org/marcoonroad/talents)

This library provides talents, a kind of traits/mixins/roles applied on object-level. However, the set of operators
known in these four features is somehow _very restricted_ in this library. To be honest, this library only
supports the following operators:
+ Symmetric sum (a.k.a conflict-aware merge operator) of talents, and;
+ Inheritance/inclusion of talents (with potentially replaced definitions).

I have not implemented aliasing and exclusion, due the following reasons:
+ In the Lua programming language, there's no standard OOP programming framework and style, so,
  aliasing and exclusion can lead to potential and unexpected issues, bugs and side-effects;
+ Aliasing and exclusion together yield the rename operator. To be "sound", it also must rename
  internal self-sends, which is an expensive operation (but possible in Lua in some sense, through
  source introspection of functions, string patterns, dynamic loading of code and debug facilities
  on environments and up-values -- also known as closure variables -- but, all of these things will
  lead to a different method being assigned, which can also yield unexpected issues through the freely
  available Lua's identity discrimination capabilities).

Instead, it is highly desirable and recommended to use different talent applications for the same object,
or even _contextual talent activation_ to __avoid__ arising conflicts rather than __solving__ them with
aliasing and exclusion.


---

__NOTE__: If you don't know anything about traits, talents and mixins, it's recommended to take a look
in the references section into the [wiki](http://github.com/marcoonroad/talents.wiki/).

---


### Introduction

By default, you have an already configured talent module instance (I will explain later how to configure this library
and so, plug it on a given existent framework). To use this already configured module, we say:

```lua
local talents = require 'talents'

-- here comes your code, kiddo --
```

This configured module will provide you a bunch of things, but let's take the _most_ easy parts first. The talent
definition and talent application seem very good candidates, so, to create a talent we just say:

```lua
-- assume that 'talents' is bound to the loaded module --

local talent = talents.talent (definitions)

-- the rest of the code lies here --
```

Where `definitions` will be often a table that we will call `pairs` on it (but Lua gives you the capability to
overload any value for this iterator). Once the iteration is performed, a fresh talent is generated and it
_isn't directly synchronized anymore with the passed definitions_, that is, changes performed on the passed
definitions won't be _propagated on_ neither _observed by_ the generated talent (due the shallow cloning used
internally to yield that talent). Note that indirect mutations, for example, on the reference for some definition,
may yet be observed/propagated. You can plug a different iterator generating a pair of a `selector` and a `value`,
where `value` is a deeply cloned reference, though.

To "apply" this talent, we should call `decorate` from this module:

```lua
-- assuming that 'object', 'talents' and 'talent' are bound --

local result = talents.decorate (talent, object)

-- yadda yadda yadda --
```

For a matter of simplicity, a syntax sugar is also provided:

```lua
local result = talent (object)
```

If you are paying attention enough, you might have noticed that talents are nothing but objects parametrized over other
objects, or, mathematically speaking, a function mapping objects to objects (it is a monoid somehow if we provide an unit
value, roughly speaking, an empty singleton object). The result object here will delegate to both talent and object, but
in the following order:
+ Firstly, look for a definition matching X in the talent itself;
+ If the talent doesn't provide it, try looking into the object for that X.

The talent, so, __overrides__ the object without touching it (I mean, without any interferences on object). If you know traits
or mixins, you may think that it is a bit strange, because frequently the inverse happens: traits and mixins (the counterparts
of our talents) are __overridden__ by the target classes (the counterparts of our objects). But there is a good reason for
that, we just want to __individually extend__ concrete things. Applied talents are still isolated from their result objects,
so any effects (I mean, mutation) performed on the result are not reflected on the talent (neither on the target object).
That said, let us skip to a really important note.


---

__NOTE__: To be "pluggable", this library must not violate the encapsulation of existent objects. The assumptions over
target's definitions must be _explicit_ as a derived rule of encapsulation (and to not lead to subtle bugs through
implicit assumptions as well).

---


Unlike Ruby mixins, our talents make explicit assumptions over target's definitions. On any attempt to make an implicit
assumption over target's definitions, an exception is thrown in runtime, but only during the execution of a talent's bound
method (methods outside the talent's boundary, that is, methods from either the target object or from the proxy itself are
free to make implicit assumptions). These explicit assumptions are made with requirements (it's planned to add contracts for
these requirements, this is the why of a call -- contracts can be types passed as strings, the default case, i.e, for nil,
will type-check against the Dynamic type):

```lua
local point2D = talents.talent {
    x = talents.required ( ),
    y = talents.required ( ),

    move = function (self, x, y)
        self.x = self.x + x
        self.y = self.y + y
    end,
}
```

The exception for the implicit assumption is:

```lua
-- assume that 'selector' is bound to the implicit assumption on some talent's method --

local reason = require ('talents.internals.reason').violation (selector)
```

During talent application, the target object is queried against the talent's requirements, and if one of these is not
fulfilled, an error is raised on runtime (if possible, saying which requirement is not fulfilled). This error can be found
through:

```lua
local reason = require ('talents.internals.reason').required (selector)
```

Where `selector` stands for the unfulfilled requirement.

### Useful links

For more information, check out that [wiki](http://github.com/marcoonroad/talents.wiki/) carefully written.

