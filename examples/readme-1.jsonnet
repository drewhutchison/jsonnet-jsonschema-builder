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