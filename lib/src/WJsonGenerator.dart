import 'dart:convert';
import 'WEndpoint.dart';
import 'WGenerator.dart';
import 'WCollection.dart';
import 'Exceptions.dart';
import 'fields.dart';

class WJsonGenerator extends WGenerator {
  String generate({ String api }) {
    Map output = {};

    if (api != null) {
      if (this.wormhole.apis.containsKey(api))
        output = singleApi(api);
      else
        throw WUndefinedApiException(api);
    } else {
      this.wormhole.apis.forEach((name, a) {
        output[name] = singleApi(name); 
      });
    }

    JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    return encoder.convert(output);
  }

  singleApi(String name) {
    Map output = {};

    this.wormhole[name].collections.forEach((collectionName, collection) {
      output[collectionName] = singleCollection(name, collectionName);
    });

    return output;
  }

  singleCollection(String apiName, String collectionName) {
    Map output = {};

    WCollection collection = this.wormhole[apiName][collectionName];

    output['fields'] = {};

    for (WField field in collection.fields) {
      output['fields'][field.name] = {
        'type': field.runtimeType.toString().split('<')[0],
        'valueType': field.type.toString(),
        'regex': field.regex.toString() == 'null' ? null : field.regex.toString(),
      };
    }
    
    output['endpoints'] = {};

    collection.endpoints.forEach((operation, endpoint) {

      if (endpoint != null) {
        Map args = {};

        for (WArg arg in endpoint.args) {
          args[arg.name] = {
            'type': arg.type.toString(),
            'required': arg.require,
            'ranged': arg.ranged,
          };
        }

        output['endpoints'][operation] = {
          'method': endpoint.methodToString(),
          'path': endpoint.path,
          'arguments': args,
        };
      } else {
        output['endpoints'][operation] = null;
      }
    });

    return output;
  }
}