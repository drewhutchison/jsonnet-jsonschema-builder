/***********************************************************************************************************************
/ jsonschemabuilder.libsonnet
/
/ v0.1
/
/ Copyright 2022 Andrew James Hutchison
/ See https://github.com/drewhutchison/jsonnet-jsonschema-builder for license and more information
/
***********************************************************************************************************************/

local NULL = "null";
local BOOLEAN = "boolean";
local STRING = "string";
local NUMBER = "number";
local INTEGER = "integer";
local ARRAY =  "array";
local OBJECT = "object";

local validateAgainstParentType = function(o, parent)
    local t = parent.type;
    (t == NULL && o == null) ||
    (t == BOOLEAN && std.isBoolean(o)) ||
    (t == STRING && std.isString(o)) ||
    (t == NUMBER && std.isNumber(o)) ||
    (t == INTEGER && std.isNumber(o)) ||
    (t == ARRAY && std.isArray(o)) ||
    (t == OBJECT && std.isObject(o));

local isSchema = function(o) std.isObject(o) || std.isBoolean(o);

local validatesAny = {
    withEnum:: function(values=[])
        assert std.isArray(values);
        local badIndices = std.find(false, [validateAgainstParentType(i, self) for i in values]);
        if std.length(badIndices) > 0
        then error 'schema is type %s but withEnum argument contains: %s (%s) at position %d' %
                   [self.type, values[badIndices[0]], std.type(values[badIndices[0]]), badIndices[0]]
        else self + {enum: values},
    withConst:: function(value)
        if validateAgainstParentType(value, self) == false
        then error 'schema is type %s but withConst given argument: %s (%s)' % [self.type, value, std.type(value)]
        else self + {const: value},
    withTitle:: function(title)
        assert std.isString(title);
        self + {title: title},
    describe:: function(description)
        assert std.isString(description);
        self + {description: description},
};

local validatesNumeric = {
    withMultipleOf:: function(value)
        assert std.isNumber(value);
        assert value > 0;
        self + {multipleOf: value},
    withMaximum:: function(value)
        assert std.isNumber(value);
        self + {maximum: value},
    withExclusiveMaximum:: function(value)
        assert std.isNumber(value);
        self + {exclusiveMaximum: value},
    withMinimum:: function(value)
        assert std.isNumber(value);
        self + {minimum: value},
    withExclusiveMinimum:: function(value)
        assert std.isNumber(value);
        self + {exclusiveMinimum: value},
};

local validatesString = {
    withMaxLength:: function(value)
        assert std.isNumber(value);
        assert value >= 0;
        self + {maxLength: value},
    withMinLength:: function(value)
        assert std.isNumber(value);
        assert value >= 0;
        self + {minLength: value},
    withPattern:: function(value)
        assert std.isString(value);
        self + {pattern: value},
};

local validatesArray = {
    withMaxItems:: function(value)
        assert std.isNumber(value);
        assert value >= 0;
        self + {maxItems: value},
    withMinItems:: function(value)
        assert std.isNumber(value);
        assert value >= 0;
        self + {minItems: value},
    withUniqueItems:: function(value)
        assert std.isBoolean(value);
        self + {uniqueItems: value},
    withMaxContains:: function(value)
        assert std.isNumber(value);
        assert value >= 0;
        self + {maxContains: value},
    withMinContains:: function(value)
        assert std.isNumber(value);
        assert value >= 0;
        self + {minContains: value},
};

local validatesObject = {
    withMaxProperties:: function(value)
        assert std.isNumber(value);
        assert value >= 0;
        self + {maxProperties: value},
    withMinProperties:: function(value)
        assert std.isNumber(value);
        assert value >= 0;
        self + {minProperties: value},
};

local subschemaInPlace = {
    allOf:: function(subschemas)
        assert std.isArray(subschemas);
        assert std.length(subschemas) > 0;
        {allOf: subschemas},
    anyOf:: function(subschemas)
        assert std.isArray(subschemas);
        assert std.length(subschemas) > 0;
        {anyOf: subschemas},
    oneOf:: function(subschemas)
        assert std.isArray(subschemas);
        assert std.length(subschemas) > 0;
        {oneOf: subschemas},
    not:: function(subschema)
        assert isSchema(subschema);
        {not: subschema},
    'if':: function(subschema)
        assert isSchema(subschema);
        {'if': subschema},
    'then':: function(subschema)
        assert isSchema(subschema);
        {'then': subschema},
    'else':: function(subschema)
        assert isSchema(subschema);
        {'else': subschema},
    // TODO dependentSchmas
};

local subschemaForArray = {
    withPrefixItems:: function(subschemas) self + {prefixItems: subschemas},
    withItems:: function(subschema) self + {items: subschema},
    withContains:: function(subschema) self + {contains: subschema},
};

local subschemaForObject = {

    withProperty:: function(name, subschema, required=false, depends=[])
        local oldProperties = if std.objectHas(self, 'properties')
                              then self.properties
                              else {};
        local newProperties = oldProperties + {[name]: subschema};
        local oldRequireds = if std.objectHas(self, 'required')
                             then self.required
                             else [];
        local newRequireds = if required
                             then std.uniq(std.sort(oldRequireds + [name]))
                             else oldRequireds;
        local oldDependentRequired = if std.objectHas(self, 'dependentRequired')
                                     then self.dependentRequired
                                     else {};
        local newDependentRequired = if std.length(depends) > 0
                                     then oldDependentRequired + {
                                        [name]: depends}
                                     else oldDependentRequired;
        self + {
            properties: newProperties,
            [if std.length(newRequireds) > 0 then 'required']: newRequireds,
            [if std.length(newDependentRequired) > 0 then 'dependentRequired']: newDependentRequired},

    withPatternProperty:: function(pattern, subschema)
        local oldPatternProperties = if std.objectHas(self, 'patternProperties')
                              then self.patternProperties
                              else {};
        local newPatternProperties = oldPatternProperties + {[pattern]: subschema};
        self + {patternProperties: newPatternProperties},

    withAdditionalProperties:: function(schema)
        self + {additionalProperties: schema},

    withPropertyNames:: function(schema)
        self + {propertyNames: schema},

    addRequired:: function(required)
        assert std.isArray(required);
        local oldRequireds = if std.objectHas(self, 'required')
                             then self.required
                             else [];
        local newRequireds = std.uniq(std.sort(oldRequireds + required));
        self + {[if std.length(newRequireds) > 0 then 'required']: newRequireds},

    addDependentRequired:: function(name, depends)
        assert std.isString(name);
        assert std.isArray(depends);
        local oldDependentRequired = if std.objectHas(self, 'dependentRequired')
                                     then self.dependentRequired
                                     else {};
        local newDependentRequired = if std.length(depends) > 0
                                     then oldDependentRequired + {
                                        [name]: depends}
                                     else oldDependentRequired;
        self + {[if std.length(newDependentRequired) > 0 then 'dependentRequired']: newDependentRequired},
};

{
    'null': {
        type: "null",
    } + validatesAny,

    boolean: {
        type: "boolean",
    } + validatesAny,

    string: {
        type: "string",
    } + validatesAny
      + validatesString,

    number: {
        type: "number",
    } + validatesAny
      + validatesNumeric,

    integer: {
        type: "integer",
    } + validatesAny
      + validatesNumeric,

    array: {
        type: "array",
    } + validatesAny
      + validatesArray
      + subschemaForArray,

    object: {
        type: "object",
    } + validatesAny
      + validatesObject
      + subschemaForObject,
} + subschemaInPlace
