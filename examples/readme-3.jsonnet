local jsb = import 'jsonschemabuilder.libsonnet';

jsb.array
   .describe("first description")
   .withTitle("description and title example")
   .describe("second description")
