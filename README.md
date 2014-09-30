# Cheker v0.0
Cheker is a small and simple type checking library for JavaScript. The main goal is to provide some 'peace of mind' in your gnarly JS applications, by ensuring that you're passing around the objects that you think you are, and that they conform to an interface which you specify.

The primary method `guard` takes a list of types and a function, and when the function is called it will do type checks to verify that the passed in parameters are as expected, and the same for the return value after execution.


## Installation
Not on NPM just yet, so use `npm install UnquietCode/cheker`, and then `require('cheker')` as usual.


## Usage
Where indicated, `[primitive]` should be interpreted as any one of the following options:

* `null`
* `undefined`
* `number`
* `string`
* `boolean`
* `object`
* `array`
* `function`
* `regex`/`regEx`


 
### cheker.is\[primitive](value)
Returns true if the value is of the type, false otherwise.
```
cheker.is.string("hello")  # true
cheker.is.number({})  # false
```

### cheker.not\[primitive](value)
Returns true if the value is not of the type, false otherwise.
```
cheker.not.boolean(1)  # true
```

### cheker.extends(objA, objB)
Returns true if for every property of A there exists an equal property in B.
```
objA = { one: 1, two: "2" }
objB = { one: 1, two: "2", three: 3 }

cheker.extends(objA, objB)  # true
cheker.extends(objA, {})  # false
```

### cheker.assert.X
Same as the above methods, but will throw an exception rather than returning false.

* **assert.is**
* **assert.not**
* **assert.extends**


### cheker.guard(returnType, types..., function)
Guards a function with automatic type checking for arguments and return values. If the types do not match then an exception this thrown. This is especially useful for ensuring that the objects you are receiving fully implement a certain interface.

#### Specifying Types

* `if typeof argument is 'function'`
  perform an `instanceof` check, such that the argument
  is and it is an instanceof the function (prototypes match)

* `if typeof argument is 'object`
 
* is [Enum](#Enum)
 


### cheker.apply()
Similar to `cheker.guard`, but returns a function which will type check its arguments and partially apply them to the function. This avoids having to check the type of every argument on each function invocation. Useful when you have some static arguments which don't change (like services or helpers), and dynamic arguments which vary with every call.
```
func = (n1, n2) -> "#{n1} | #{n2}"
func = cheker.apply(String, Number, Number, func)(1)
func(2)  # ok
func("3")  # error!
```


### cheker.extend(objA, objB)
A simple extension method which iterates all properties of A and B, copies them to a new object, and returns it. Properties inherited though the prototype chain **are included**. Duplicate properties in B will clobber those in A.

This method is good for extending interface specifications, since they are just objects.

```
IPerson = {
  name: String
  age: Number
}

ILocalizedPerson = cheker.extend(IPerson, {
  language: String
})
```


### cheker.narrow
Similar to `cheker.guard`, but does not consider object specifications. Instead, in order to satisfy the type constraints a value must either `extend` (when the type is an object), or be an `instanceof` (when the type is a function). This method is particularly useful for narrowing the type specifications themselves, which provides a basic support for generics in your guarded methods.

See the XYZ example for a fuller example.
```
IPerson = {
  name: String
  language: String
}

ILocalizedPerson = cheker.extend(IPerson, {
  
})

GenericGreeter = cheker.narrow(IPerson, (PersonType) ->
  cheker.guard(undefined, PersonType, (person) ->
    message = switch language
      when "English" then "Howdy diddly ho #{person.name}!"
      when "French" then "Bonjour #{person.name}!"
      
    console.log(message)

greet({ name: "Tina", age: 20, language: "English" }
greet({ name: "Fred", age: 40 }  # error!

TODO
``` 

### cheker.Enum <a name="Enum"></a>
A helper type which can be used to create a close approximation to Enums in JavaScript. To create your own Enum, inherit from this fuction and pass the list of possible values to the constructor, then construct a new instance of your object. All of the enum constants are available as fields on the instance, and each has a 'value'. property. The constructor accepts either an array of strings (field name will be the same as the value), or an object mapping names to values.

You should try to construct only a single instance of your Enum type, however all of the instances are connected so that the fields of two instances will still 'belong' to the same Enum type.

You can check whether a provided value is of the expected type by looking at the `marker` property on both the constants and the constructor function.


```

```
