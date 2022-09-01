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
