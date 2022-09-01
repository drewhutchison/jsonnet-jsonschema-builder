local jsb = import 'jsonschemabuilder.libsonnet';

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
