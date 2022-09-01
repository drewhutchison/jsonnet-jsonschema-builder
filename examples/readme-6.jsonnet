local jsb = import 'jsonschemabuilder.libsonnet';

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
