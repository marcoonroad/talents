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
in the references section.

---


### Goals

This library is intended to be pluggable on existent Lua OOP frameworks in the wild. Either if it is prototype-based
or class-based, this library only cares about the passed instances. That said, some trade-offs exist anyways. First
of all, to compose seamlessly on an unknown object, the library must yield a fresh object instead of making
some assumptions over this unknown object (I mean, assumptions intended to _modify_ the passed object). So,
to avoid inconsistent assumptions, fresh things are generated and they should replace explicitly their respective target
objects (surely, where it is planned to do that). By second, these fresh objects must behave almost like their target
objects counterparts, with minor and needed variations, if possible. In this library, a fresh object has its own identity,
and its own "state", but, for example, the target object's meta-table semantics are preserved in some way (with the
exception of the `__newindex` meta-method, which is used to provide a "local state" for this fresh object).


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


### Composition

Composition here means the symmetric sum operator known in the Traits model. This operation allows us to
decouple and combine multiple pieces of "abstract" objects. So, in some sense, this thing is a great helping
hand during the refactoring process. Nevertheless, it is possible to use it in the early process of development
as well (giving rise to much reuse and maintainability). This composition operator doesn't work only on behaviors,
but also for states. In the case, states are seen as "default" values (it's not possible to mutate the talent itself
'cause it is abstract and we must protect that against unwanted or accidental changes). Composition, so, takes two
talents and merges their associated definitions, possibly with conflicts.

For a better view of composition, the following table can help you to understand that (notice that row and column
headers are the elements being symmetrically composed, the cell between such rows and columns is the result of
such composition):

|          |  value1  |  value2  | required | conflict |
|:--------:|:--------:|:--------:|:--------:|:--------:|
|  value1  |  value1  | conflict |  value1  | conflict |
|  value2  | conflict |  value2  |  value2  | conflict |
| required |  value1  |  value2  | required | conflict |
| conflict | conflict | conflict | conflict | conflict |

Where value1 and value2 are distinct values. As you can see, it's really easy to produce conflicts, so a proper care
should be used when composing talents. To ignore conflicts, you can anyways resort to talent inheritance, but it is
strongly advised to use contextual activation (where talents are seen as contextual layers from the Context-Oriented
paradigm). To compose talents, we will often say:

```lua
local talent3 = talents.compose (talent1, talent2)
```

But a syntax sugar is provided as well:

```lua
local talent3 = talent1 + talent2
```

During talent application and talent activation, detected conflicts are raised under the standard below:

```lua
local reason = require ('talents.internals.reason').conflict (selector)

error (reason)
```

Where `selector` is the field which the system have detected an arising conflict.


### Contextual Activation

Contextual activation here stands for a function being called with a subjective object extension (followed by
a set of optional arguments). The function itself acts as a scope, whenever we call such function, it may be
seen as a scope activation. The talent used in this activation is not only seen as a contextual layer, but
also as a capability providing rights amplification over some passed target object. Rights amplification is
a kind of synergy on programming context, and in the Capability Model it's a form of _authentication_. That
said, it can be used to provide a certain degree of encapsulation for the target object -- if you have such
talent and such target object, you are able to access some hidden fields from the result subject, you have just
to ensure that the talent is not freely available to anyone.

Backing to the subjective/contextual theory, contextual activation give us the power to model explicitly use-cases
(from the Software Engineering field) on the software itself. We have just to provide unique talents for every
use-case in the design, and it become straightforward (perhaps, honestly) to map specification into the
implementation. By unique, I mean an almost exclusive talent, 'cause a subject is lazily computed for the interaction
between the talent with the target object.

Comparing with the ML functors, talents have two semantics akin to functor application semantics. While these
functor semantics depend upon the related types on the ML family, our talent semantics depend solely on the
passed target object. The first semantic is called __generative__, and it yields fresh modules even for the
same inputs passed to some ML functor. The second semantic is called __applicative__, and the same output module
is generated for the same input module (it's the ideal, but side-effects can give rise to needed fresh modules
"unsoundly" sharing an equality type constraint among functor-dependent type abstractions). If you are smart enough,
you may have noticed that talent application
is "generative" while talent activation is "applicative". Talent activation, so, is confined to avoid the leaking of
possible side-effects from the subject, thus, disallowing some kind of global state. But be aware, it relies on
the fact that both talent and target object aren't freely accessible (that is, one of them can be freely accessible,
but the other should not be exposed).

Also, activations can also be seen as a kind of Ownership, most specifically, a model following the
_owners-as-accessors_ discipline, that is, Dynamic Ownership. Every time we perform activation on the same pair
(talent & target), we gain the capability to access the associated subject, but only in some given scope. Let's assume
that the system _owns_ such subject, it can be leaked, but not accessed outside the owner's boundaries (this is the
general definition for Dynamic Ownership). On such activation, the passed scope function can be thought like a client
performing a _borrowing_ (i.e, temporary ownership) before its own activation, and after that activation, the scope
gives up from this temporary ownership, transferring back the ownership control to our system kernel. Boundaries here
stands for all potential calls derived from the point of the boundary object (that is, inspecting the call stack, to
be a valid operation, it must have the boundary object appearing in some point on such stack). Owners as accessors
discipline is related to an Abstract Data Type in some sense -- the owner is the module and the owned is the data
type.

Enough of cheap talking, to perform activation we will rather say:

```lua
local result = {
        talents.activate (talent, object, scope, ...)
}
```

Where scope will be often bound to something like that below:

```lua
local function scope (subject, ...)
        -- perform some actions on subject here --
end
```

Internally, it will lazily compute a talent application, the result of such application will be associated for both
talent and target object, so further activations on these pairs will avoid unnecessary re-computation. Note that the
lifetime of the associated subject depends on that pair, if some of these objects die, the subject will be dead as
well (unless there are leaked references, but these will be pretty useless due the death of one needed key).


### Inheritance

It's also possible to extend existent talents and thus, reuse some definitions, requirements and even some unwanted conflicts
(surely, nobody likes to inherit "errors"). The only important points are:
* If you are willing to define a requirement, but it is already provided on the parent talent, this requirement is discarded
  anyways by the child talent.
* It is possible to "solve" conflicts through "overriding". If you provide some definition, and in the parent talent it is
  actually a conflict, the conflict is ignored and the child talent takes that definition. Note that conflicts are unaccessible
  values (different of requirements), so they only arise on some certain specific conditions of symmetrical sums. If this conflict
  is due two different primitive values of the same type (e.g, numbers such 0 and 1), it's not quite bad to override such conflict,
  but if it is due _two different and unrelated functions/methods accidentally sharing the same selector field_, codes relying
  specifically on some of these parts might be broken with your own definition. This is the why of the advice for contextual activation
  on top of this documentation.

Despite such "issues" and "problems" of inheritance, to use inheritance between talents we just write:

```lua
-- assume that `parent` contains our parent talent --

local child = talents.extend (parent, definitions)
```

Talent inheritance also works internally in the same way of talent definition: the passed definitions are cloned through an iteration
(using the passed configuration's iterator). Shallow cloning is used in the inheritance internals, but deep cloning can be provided
(with a custom configuration) as well.


### Introspection

Some kind of primitive introspection is provided in this library, __but only on talent-level__ (to not violate any kind of
encapsulation on object-level). It also provides some sort of reflection upon objects, querying and "extracting" (without
the loss) the current applied talent, only if such object is actually an object provided by this library. The introspection
functions for talents are:

```lua
talents.requires  (talent1, selector1) --> boolean
talents.provides  (talent2, selector2) --> boolean
talents.conflicts (talent3, selector3) --> boolean
```

While, the talent query over the object (here, called _talent abstraction_) is called as:

```lua
local talent = talents.abstract (result)
```

Where:

```lua
-- assume again that 'talents' contains the reference to our major module --

local result  = talents.decorate (talent1, object)
local talent2 = talents.abstract (result)

assert (rawequal (talent1, talent2))
```

Holds for all talent1 existing in the set of talents, and also for all object existing in the set of Lua's objects.


### Ownership

There is a really simple Ownership System in this library. It employs _owners-as-modifiers_ discipline, meaning
that the given object is only "modified" inside the respective owner's scope. Every time we decorate a target
object, the result one will be internally attached with a owner reference. This owner reference is bound to the
current thread reference calling `talents.decorate`, and any sender running inside this thread can indeed perform
mutations on that owned receiver. Senders running inside other threads are only able to read from the owned object,
even if these senders are the same which previously have accessed this owned object inside the owner thread.

Although Lua's threads (often known as coroutines) are green threads (so no parallelism is used internally),
computations are still prone to the "interleaving of mutations" (that is, race conditions). This is the why
of restricting mutations to only one thread. Note that this prevents data races, but not non-synchronized
updates. For that, you must explicitly use some kind of Observer/Listener design pattern, or even Reactive
Programming if needed.

Talent (contextual) activation has some subtle things here. First, 'cause an internal decorated object is dependent
over the identity of the talent and the identity of the target object, this library won't generate fresh objects
depending on the current/running thread. Secondly, 'cause this decorated object is lazily computed, it will force
the evaluation of the "thunk" in the current thread scope, and then, bind it as owner. You should pay much attention
in your code, mostly where `talents.activate` is initially called -- calling it twice with the same inputs, on different
coroutines and with no known evaluation order (dependent on random numbers, for instance) can lead to unexpected
things (they are yet trapped errors, assuming that the provided test suite covers sufficient cases).

On any attempt to mutate an object outside its owner thread, the following exception is raised:

```lua
-- assume that `selector` and `value` are bound to the values used on mutation, e,g: --
--   object[ selector ] = value                                                      --

local reason = require ('talents.internals.reason').ownership (selector, value)

error (reason)
```


### Configuration

To plug directly this library, you can use the `'talents.pluggable'` module. This module always returns a function,
which acts like a ML Functor providing inversion of control and dependency injection. This "functor" will take a
certain structure and yield a fresh/instantiated `talents` module. In such structure, some properties can be defined
(they're optional, not required, though):

```lua
local functor = require 'talents.pluggable'

-- assume by now that the following values are blindly bound --
local configuration = {
   identity = identity,
   equality = equality,
   iterator = iterator,
   inspect  = inspect,
}

local talents = functor (configuration)
```

---

__NOTE__: You should try to subsume how many default configurations you can in your configuration functions. The
default configurations can be found in the module `'talents.internals.default'`, just require it and select the
appropriate configuration property.

---


The `identity` function is used to provide proxies assuming the target object identity. To do that, you just map
references to references here, if a reference maps to itself, it will use its own identity (which is the default
configuration if `identity` is not provided). This configuration is needed to _read from_ and _write to_ Lua tables, which
are by default based on the `rawequal` identity discrimination. So, all of the pluggable module external reads and writes pass
through the `identity` function, a custom one will provide you the capability to define your own operators for these talents,
for instance.

The `equality` is a function to compare values. The default configuration stands for the `rawequal`, discriminating
the identity. It's used internally, for example, to compare if a slot value is either a requirement or an arising conflict.

For type introspection, use `inspect`. You can plug your own type introspection capability, for example, performing
class introspection of class-based objects. By default, it will be bound implicitly to the `type` function. By now,
this configuration is pretty useless, but it is parametrized anyways due the future support for contracts on talent
requirements.

Another configuration here is the `iterator`, which is by default `pairs`. It is used to perform shallow cloning in
this library, you can anyways plug your own definition and iterate private/protected fields, or even restrict the
iteration for some sort of subjective/contextual fields. As said previously on the introduction, it is also possible
to provide an iterator which performs deep cloning.


### Planned Features

+ Ownership transference and borrowing
+ Super-sends for both talents and target objects
+ Intercession through proxies and handlers
+ Attenuation of interface with talent coercions
+ Explicit and implicit talent activation/deactivation


### Motivations

I was searching for a library to support abstraction, decomposition and composition on concrete things for Lua.
But all I found was these things applied on somehow "abstract" concepts, such classes and prototypes. 'Cause I'm lazy
enough to create an expensive & well-tested yet another OOP framework(TM), I'm only delivering "composable factories of
decorated objects" (this is the real name of this library, but a huge one) for now (and maybe for ever). Be satisfied
with that, or fork this code away & implement your own most wanted stuff on top of it.


### References
+ [1] _The programming language Jigsaw: Mixins, Modularity & Multiple Inheritance_, by Gilad Bracha, __1992__
+ [2] _Object-Centric Reflection: Unifying Reflection & Bringing it back to Objects_, by Jorge Ressia, __2012__
+ [3] _Talents: An environment for Dynamically Composing Units of Reuse_, by Jorge Ressia et al, __2012__
+ [4] _Traits: Composing Classes from Behavioral Building Blocks_, by Nathanael Schärli, __2005__
+ [5] _Talented Streams: Implementation_, by Manuel Leuenberger, __2013__

