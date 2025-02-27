// The +'a marks the abstract type parameter as covariant, which essentially means that
// a value of type 'a is immutable and may not be used in some mutable context.
//
// This makes sense for promises, since according to their specification, once a promise has
// been resolved (with a specific value), it will never change its resolved value.
//
// More details about polymorphism / invariance / covariance,... can be found here:
// https://caml.inria.fr/pub/docs/manual-ocaml/polymorphism.html#ss:variance:abstract-data-types
type t<+'a> = promise<'a>

/**
[resolve(value)] creates a resolved Promise with a given `value`

```rescript
let p = Promise.resolve(5) // promise<int>
```
*/
@val
@scope("Promise")
external resolve: 'a => t<'a> = "resolve"

@scope("Promise") @val
external reject: exn => t<_> = "reject"

/**
`make(callback)` creates a new Promise based on a `callback` that receives two
uncurried functions `resolve` and `reject` for defining the Promise's result.

```rescript
open Promise

let n = 4
Promise.make((resolve, reject) => {
  if(n < 5) {
    resolve(. "success")
  }
  else {
    reject(. "failed")
  }
})
->then(str => {
  Console.log(str)->resolve
})
->catch(e => {
  Console.log("Error occurred")
  resolve()
})
->ignore
```
*/
@new
external make: ((@uncurry (. 'a) => unit, (. 'e) => unit) => unit) => t<'a> = "Promise"

/**
`catch(promise, errorCallback)` registers an exception handler in a promise chain.
The `errorCallback` receives an `exn` value that can later be refined into a JS error or ReScript
error. The `errorCallback` needs to return a promise with the same type as the consumed promise.

```rescript
open Promise

exception SomeError(string)

reject(SomeError("this is an error"))
->then(_ => {
  Ok("This result will never be returned")->resolve
})
->catch(e => {
  let msg = switch(e) {
    | SomeError(msg) => "ReScript error occurred: " ++ msg
    | Exn.Error(obj) =>
      switch Exn.message(obj) {
        | Some(msg) => "JS exception occurred: " ++ msg
        | None => "Some other JS value has been thrown"
      }
    | _ => "Unexpected error occurred"
  }

  Error(msg)->resolve
})
->then(result => {
  switch result {
  | Ok(r) => Console.log2("Operation successful: ", r)
  | Error(msg) => Console.log2("Operation failed: ", msg)
  }->resolve
})
->ignore // Ignore needed for side-effects
```

In case you want to return another promise in your `callback`, consider using \`then\` instead.
*/
let catch: (t<'a>, exn => t<'a>) => t<'a>

/**
`then(promise, callback)` returns a new promise based on the result of `promise`'s value. 
The `callback` needs to explicitly return a new promise via `resolve`.

It is **not allowed** to resolve a nested promise (like `resolve(resolve(1))`).

```rescript
Promise.resolve(5)
->then(num => {
  resolve(num + 5)
})
->then(num => {
  Console.log2("Your lucky number is: ", num)
  resolve()
})
->ignore
```
*/
@send
external then: (t<'a>, @uncurry ('a => t<'b>)) => t<'b> = "then"

/**
`thenResolve(promise, callback)` converts an encapsulated value of a promise into another promise wrapped value. 

It is **not allowed** to return a promise within the provided callback (e.g. `thenResolve(value => resolve(value))`).

```rescript
resolve("Anna")
->thenResolve(str => {
  "Hello " ++ str
})
->thenResolve(str => {
  Console.log(str)
})
->ignore // Ignore needed for side-effects
```

In case you want to return another promise in your `callback`, consider using \`then\` instead.
*/
@send
external thenResolve: (t<'a>, @uncurry ('a => 'b)) => t<'b> = "then"

/**
[finally(promise, callback)] is used to execute a function that is called no matter if a promise
was resolved or rejected. It will return the same `promise` it originally received.

```rescript
exception SomeError(string)
let isDone = ref(false)

resolve(5)
->then(_ => {
  reject(TestError("test"))
})
->then(v => {
  Console.log2("final result", v)
  resolve()
})
->catch(_ => {
  Console.log("Error handled")
  resolve()
})
->finally(() => {
  Console.log("finally")
  isDone := true
})
->then(() => {
  Console.log2("isDone:", isDone.contents)
  resolve()
})
->ignore
```
*/
@send
external finally: (t<'a>, unit => unit) => t<'a> = "finally"

/* Combining promises. */
@scope("Promise") @val
external race: array<t<'a>> => t<'a> = "race"

/**
[all(promises)] runs all promises in parallel and returns a new promise resolving all gathered results in a unified array.

```rescript
open Promise
let promises = [resolve(1), resolve(2), resolve(3)]

all(promises)
->then((results) => {
  results->Array.forEach(num => {
    Console.log2("Number: ", num)
  })

  resolve()
})
->ignore
```
*/
@scope("Promise")
@val
external all: array<t<'a>> => t<array<'a>> = "all"

/**
[all2((p1, p2))]. Like `all()`, but with a fixed size tuple of 2
*/
@scope("Promise")
@val
external all2: ((t<'a>, t<'b>)) => t<('a, 'b)> = "all"

/**
[all3((p1, p2, p3))]. Like `all()`, but with a fixed size tuple of 3
*/
@scope("Promise")
@val
external all3: ((t<'a>, t<'b>, t<'c>)) => t<('a, 'b, 'c)> = "all"

/**
[all4((p1, p2, p3, p4))]. Like `all()`, but with a fixed size tuple of 4
*/
@scope("Promise")
@val
external all4: ((t<'a>, t<'b>, t<'c>, t<'d>)) => t<('a, 'b, 'c, 'd)> = "all"

/**
[all5((p1, p2, p3, p4, p5))]. Like `all()`, but with a fixed size tuple of 5
*/
@scope("Promise")
@val
external all5: ((t<'a>, t<'b>, t<'c>, t<'d>, t<'e>)) => t<('a, 'b, 'c, 'd, 'e)> = "all"

/**
[all6((p1, p2, p4, p5, p6))]. Like `all()`, but with a fixed size tuple of 6
")*/
@scope("Promise")
@val
external all6: ((t<'a>, t<'b>, t<'c>, t<'d>, t<'e>, t<'f>)) => t<('a, 'b, 'c, 'd, 'e, 'f)> = "all"

/**
`done` is a safe way to ignore a promise. If a value is anything else than a promise, it will raise a type error.
*/
external done: promise<'a> => unit = "%ignore"

external unsafe_async: 'a => promise<'a> = "%identity"
external unsafe_await: promise<'a> => 'a = "?await"
