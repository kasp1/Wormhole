
class WUndefinedEndpointException implements Exception {
  String api, collection, operation;

  WUndefinedEndpointException(this.api, this.collection, this.operation);

  @override
  String toString() => 'The endpoint for operation `$operation` in collection `$collection` has not been specified yet. You can specify it using the `endpoint` argument, e.g.: `Wormhole()[\'$api\'][\'$collection\'].override(\'$operation\', WEndpoint( /* ... */ ));`';
}

class WDisabledEndpointException implements Exception {
  String api, collection, operation;

  WDisabledEndpointException(this.api, this.collection, this.operation);

  @override
  String toString() => 'The endpoint for operation `$operation` in collection `$collection` has not been specified yet. You can specify it using the `endpoint` argument, e.g.: `Wormhole()[\'$api\'][\'$collection\'].override(\'$operation\', WEndpoint( /* ... */ ));`';
}

class WMissingIdFieldException implements Exception {
  String api, collection;

  WMissingIdFieldException(this.api, this.collection);

  @override
  String toString() => 'This collection Wormhole()[\'$api\'][\'$collection\'] doesn\'t seem to contain an ID field WID<T>( /* ... */ )';
}

class WInvalidConditionFieldException implements Exception {
  String api, collection, field;

  WInvalidConditionFieldException(this.api, this.collection, this.field);

  @override
  String toString() => 'Wormhole()[\'$api\'][\'$collection\'].find() was called with an unknown condition field `$field`.';
}

class WInvalidConditionValueException implements Exception {
  String api, collection, field;

  WInvalidConditionValueException(this.api, this.collection, this.field);

  @override
  String toString() => 'Wormhole()[\'$api\'][\'$collection\'].find() was called with an unknown condition field `$field`. Each condition has to be a `Map<String, dynamic>{\'field_name\': \'value\'}` or `Map<String, dynamic>{\'field_name\': [0, 10] }` for an interval.';
}

class WUndefinedApiException implements Exception {
  String api;

  WUndefinedApiException(this.api);

  @override
  String toString() => 'No api \'$api\' has been specified.';
}

class WUndefinedFieldException implements Exception {
  String api, collection, field;

  WUndefinedFieldException(this.api, this.collection, this.field);

  @override
  String toString() => 'Wormhole()[\'$api\'][\'$collection\'].create(), .add() or update() was called with an undefined field `$field` in the proposed record. Please check whether your record field names match your collection defintion of fields.';
}