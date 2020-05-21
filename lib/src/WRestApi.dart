import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart';

import '../wormhole.dart';

class WRestApi {
  Map<String, WCollection> _collections = {};
  String base;
  String name;
  String comment;
  String authToken;
  dynamic accountId;
  bool setupNotRun = true;
  WFilteringFormat filteringFormat = WFilteringFormat.RHS_Colon;
  bool supplyExampleDataIfError = false;

  WRestApi({ this.base, this.comment }) :
    assert(base != null);

  Map<String, WCollection> get collections => _collections;

  operator []=(String name, WCollection collection) {
    assert(collection != null, 'Collection `$name` can\'t be null.');
    assert(setupNotRun, 'Adding collections after Wormhole.setup() has been run is forbidden.');
    assert(this._collections.containsKey(name) != true, 'Attempt to override an already registered collection `$name` in the `${this.name} API`.');
    
    collection.name = name;
    collection.api = this;

    this._collections[name] = collection;

    collection.setup();
  }

  WCollection operator [] (String apiName) {
    assert(this._collections.containsKey(apiName), 'The specified API `$apiName` doesn\'t seem to be registered.');
    
    return this._collections[apiName];
  }

  Future request(WHttpMethod method, url, { Map args }) async {
    Response response;

    Map<String, String> headers = {};
    
    if (authToken == null) {
      if (Wormhole().cache != null) {
        if (Wormhole().cache.getPers(name + '-authToken') != null) {
          authToken = Wormhole().cache.getPers(name + '-authToken');
        }
      }
    }
    
    if (authToken != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer ' + authToken;
    }

    switch (method) {
      case WHttpMethod.GET: response = await get(url, headers: headers); break;
      case WHttpMethod.POST: response = await post(url, body: args, headers: headers); break;
      case WHttpMethod.PUT: response = await put(url, headers: headers); break;
      case WHttpMethod.DELETE: response = await delete(url, headers: headers); break;
      default:  break;
    }

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body));
    }
  }

  Future requestGet(url) { return this.request(WHttpMethod.GET, url); }
  Future requestPost(url, Map args) { return this.request(WHttpMethod.POST, url, args: args); }
  Future requestPut(url, Map args) { return this.request(WHttpMethod.PUT, url, args: args); }
  Future requestDelete(url) { return this.request(WHttpMethod.DELETE, url); }

  void loadCache() {
    this._collections.forEach((name, collection) {
      collection.loadCache();
    });
  }
  void loadData() {
    this._collections.forEach((name, collection) {
      collection.loadData();
    });
  }
}