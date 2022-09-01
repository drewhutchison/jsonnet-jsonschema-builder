# jsonnet jsonschema builder

This project creates [jsonschema](https://json-schema.org/) documents from
[jsonnet](https://jsonnet.org/) source files using a builder-like syntax, 
thus elimintating boilerplate, simplifying things like required object 
properties, and allowing for code reuse.

Instead of:

```json
{
   "description": "database record",
   "properties": {
      "friendly_name": {
         "maxLength": 80,
         "type": "string"
      },
      "id": {
         "type": "integer"
      },
      "visibility": {
         "enum": [
            "PUBLIC",
            "PRIVATE"
         ],
         "type": "string"
      }
   },
   "required": [
      "id",
      "visibility"
   ],
   "type": "object"
}
```

write this:

```jsonnet
local jsb = import 'jsonschemabuilder.libsonnet';

jsb.object
   .describe('database record')
   .withProperty('id',
                 jsb.integer,
                 required=true)
   .withProperty('friendly_name',
                 jsb.string
                    .withMaxLength(80))
   .withProperty('visibility',
                 jsb.string
                    .withEnum(['PUBLIC', 'PRIVATE']),
                 required=true)
```

## Requirements and compatability

Tested on jsonnet version v0.15.0, should work on more recent versions.

It was generally written against json schema
[draft 2020-12](https://json-schema.org/specification-links.html#2020-12)
but neither presumes to support the entire spec nor to rely on any features
specific to it.
It will probably generate jsonschema documents that will run happily against
previous implementations, and it will probably fail to implement some
boneheadedly-obvious capabilities of either.

Please open an issue or pull request with any bugs or feature requests
specific to your specific environment or use-case.

## Usage

The library provides the following attributes at top-level:

Instance types:

- `null`
- `boolean`
- `string`
- `number`
- `integer`
- `array`
- `object`

In-place subschemas:

- `allOf()`
- `anyOf()`
- `oneOf()`
- `not()`
- `if()`
- `then()`
- `else()`

`dependentSchemas` is not currently implemented.

### Instance types

These seven attributes represent the six primitive types defined at 
https://json-schema.org/draft/2020-12/json-schema-core.html#name-instance-data-model,
along with `integer`.
The latter is not defined in the core schema, but is a frequently-encountered
extension.
For purposes of this package, it is treated identically to `number`, although
certain consumers of jsonschema might treat these types differently.

Each of these is a jsonnet object, and referencing one simply returns an object
representing the jsonschema of the corresponding type:

```jsonnet
local jsb = import 'jsonschemabuilder.libsonnet';

jsb.string
```

produces:

```json
{
   "type": "string"
}
```

While this is a valid jsonschema, it is not a tremendously useful one, and each
of these objects provides methods for populating further attributes.

### Methods available on any instance type

The following methods are provided for any of the above types (although some
combinations are at best dubiously useful):

#### `describe()` and `withTitle()`

Each of these method takes a string and populates the `description` or `title`
field of the parent schema, respectively.

In line with general jsonnet patterns, successive calls to these functions will
be resolved according to last-one-wins:

```jsonnet
jsb.array
   .describe("first description")
   .withTitle("description and title example")
   .describe("second description")
```

produces:

```json
{
   "description": "second description",
   "title": "overloaded descriptions!",
   "type": "array"
}
```

According to https://json-schema.org/draft/2020-12/json-schema-validation.html#name-title-and-description,
either of these attributes, if present, must be string-valued.
Correspondingly an assertion error is raised if either method is called with an
argument of non-string type:

```
> jsonnet -e "local jsb = import 'jsonschemabuilder.libsonnet'; jsb.boolean.describe(12)"
RUNTIME ERROR: Assertion failed.
        jsonschemabuilder.libsonnet:(37:9)-(38:42)      function <anonymous>
        <cmdline>:1:51-75
```

#### `withConst()` and `withEnum()`

These methods are provided for populating the `const` and `enum` fields, respectively,
as desribed at https://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-any.

The argument supplied to `withConst` must be of the same type described by its
parent object.
That is, although the following is a (syntactically) valid jsonschema:

```json
{
  "type": "string",
  "const": false
}
```

there is no possible json data that will validate against it, and it's very
unlikely that anyone would write something like this on purpose.
This library attempts to guard against mistakes like this again by throwing an
error:

```
> jsonnet -e "local jsb = import 'jsonschemabuilder.libsonnet'; jsb.string.withConst(false)"
RUNTIME ERROR: schema is type string but withConst given argument: false (boolean)
        jsonschemabuilder.libsonnet:31:14-115   function <anonymous>
        <cmdline>:1:51-78
```

Similarly, the argument to `withEnum` must be an array, and typechecking is
performed on each element of the array.

### Methods that are specific to instance type

The above methods are available on all seven base instance types.
These are the _only_ methods available on `null` and `boolean` types (although,
as noted, this is of dubious utility).
Other types provide other methods, which are described here:

#### Methods available on `number` and `integer`

In addition to the methods described above that are common to any instance type,
`number` and `integer` instances are provided the following methods for
populating the attributes described at
https://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-num:

- `withMultipleOf()`
- `withMaximum()`
- `withExclusiveMaximum()`
- `withMinimum()`
- `withExclusiveMinimum()`

#### Methods available on `string`

In addition to the methods described above that are common to any instance type,
instances of `string` are provided the following methods for
populating the attributes described at
https://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-str:

- `withMaxLength()`
- `withMinLength()`
- `withPattern()`

#### Methods available on `array`

In addition to the methods described above that are common to any instance type,
instances of `array` are provided the following methods for validation as
described at
https://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-arr:

- `withMaxItems()`
- `withMinItems()` 
- `withUniqueItems()`
- `withMaxContains()`
- `withMinContains()`

Besides these methods providing validation properties, arrays are also furnished
with the following, described at
https://json-schema.org/draft/2020-12/json-schema-core.html#name-keywords-for-applying-subschema:

- `withPrefixItems()`
- `withItems()`
- `withContains()`

#### Methods available on `object`

In addition to the methods described above that are common to any instance type,
instances of `object` are provided the following methods for validation as
described at
https://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-obj:

- `withMaxProperties()`
- `withMinProperties()`

and these for the core properties described at
https://json-schema.org/draft/2020-12/json-schema-core.html#name-keywords-for-applying-subschema:

- `withAdditionalProperties()`
- `withPropertyNames()`

Note that direct access is not provided to the
`properties`,
`patternProperties`,
`required`,
or `dependentRequired` attributes.
This is intentional, and a result of the builder pattern this library is
attempting to enforce.
Thus, in lieu of direct access to these attributes, we provide the following
methods:

##### `withProperty(name, subschema, required=false, depends=[])`

This method creates a new attibute on the `properties` attribute of the parent
schema (creating it if necessary), which has attribute `name` and value
`subschema`.
Current behavior is to replace any previous attribute of the same `name`, in
accordance with the jsonnet precedence rules.
However, it would be unwise to depend upon this behavior, and you should avoid
calling this method mutiple times with the same `name`.

If `required` is true, `name` will be appended to the parent schema's `required`
attribute (which will also be created if necessary).

If `depends` is specified, its value should be a list of strings.
If this list is nonempty, it will be placed as the value of the attribute `name`
on the parent schema's attribute `dependentRequired` (which will also be created
if necessary).

Thus, the following:

```jsonnet
local jsb = import 'jsonschemabuilder.libsonnet';

jsb.object
   .withProperty('id',
                 jsb.integer,
                 required=true)
   .withProperty('description',
                 jsb.string)
   .withProperty('description_language',
                 jsb.string,
                 depends=['description'])
```

results in:

```json
{
   "dependentRequired": {
      "description_language": [
         "description"
      ]
   },
   "properties": {
      "description": {
         "type": "string"
      },
      "description_language": {
         "type": "string"
      },
      "id": {
         "type": "integer"
      }
   },
   "required": [
      "id"
   ],
   "type": "object"
}
```

##### `withPatternProperty(pattern, subschema)`

Similarly to the above, this method adds a new attribute to the `patternProperties` attribute
of the parent object (which is created if it does not exist), having key
`pattern` and value `subschema`.
Since, according to
https://json-schema.org/draft/2020-12/json-schema-core.html#name-patternproperties,
the value of `pattern` should be a regular expression, it does not make sense
to use this directly in `required` or `dependentRequired`.
Instead, use `addRequired` or `addDependentRequired`.

##### `addRequired(required)` and `addDependentRequired(name, depends)`

`addRequired` takes one argument, `required`, a list of strings.
The set union of this list with the contents of the parent object's existing `required` attribute is calculate and, if
nonempty, applied as this attribute.

`addDependentRequired` takes two arguments: `name` (a string), and `depends` (a list of strings).
The parent object's `dependentRequired` attribute is given a new attribute with this name and value, respectively,
being created if it does not exist.

For example:

```jsonnet
jsb.object
   .withProperty('description',
                 jsb.string
                    .withConst('the lone star state'),
                 required=true)
   .withPatternProperty('.+eers',
                        jsb.array)
   .addDependentRequired('steers',
                         ['beers'])
   .addRequired(['profiteers'])
```

results in:

```json
{
   "dependentRequired": {
      "steers": [
         "beers"
      ]
   },
   "patternProperties": {
      ".+eers": {
         "type": "array"
      }
   },
   "properties": {
      "description": {
         "const": "the lone star state",
         "type": "string"
      }
   },
   "required": [
      "description",
      "profiteers"
   ],
   "type": "object"
}
```

### In-place subschemas

In order to provide the functionality described at
https://json-schema.org/draft/2020-12/json-schema-core.html#name-keywords-for-applying-subsc,
the library includes the following methods:

- `allOf()`, `anyOf()`, and `oneOf()`, each of which takes a strictly nonempty
  array of schemas as its only argument.
- `not`, `if`, `then`, and `else`, each of which takes a single schema as its
  only argument.

A _schema_ is one of the following:

- any of the seven basic instances
- a value returned by any of the in-place methods described in this section
- a plain boolean value (which see https://json-schema.org/draft/2020-12/json-schema-core.html#name-boolean-json-schemas)

For example, the following snippet generates a schema which validates against
anything that's a positive even integer smaller than 100, a boolean false value,
or a string beginning with the letter Z:

```jsonnet
jsb.anyOf([
    jsb.integer
       .withMultipleOf(2)
       .withExclusiveMinimum(0)
       .withExclusiveMaximum(100),
    jsb.string
       .withPattern('^Z'),
    jsb.boolean
       .withConst(false)
])
```

## Known issues

- There is not currently an implementation of the `dependentSchemas` keyword described at
  https://json-schema.org/draft/2020-12/json-schema-core.html#name-dependentschemas
- The specification allows for `type` to be array-valued, whereas this implementation only allows for the specification
  of primitive types.
- Except `title` and `description`, none of the optional vocabularies described in sections 7, 8, or 9 of
  https://json-schema.org/draft/2020-12/json-schema-validation.html
  are implemented.
  Furthermore, there is not an implementation for the obvious workaround of applying arbitrary attributes to schema
  elements within the builder pattern used by this library (unless you tried monkeypatch it, which would probably
  work).

Please open an issue or pull request if you'd like to see resolution of any of the above or of any other problem you
find with this library!