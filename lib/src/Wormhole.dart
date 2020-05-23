import 'dart:core';

import '../wormhole.dart';
import 'WHtmlGenerator.dart';
import 'WJsonGenerator.dart';

class Wormhole {
  bool setupNotRun = true;

  Map<String, WRestApi> _apis = {};
  Map<String, WRestApi> get apis => _apis;
  set apis(Map<String, WRestApi> apis) {
    assert(false, 'Please do not set the _apis variable directly, use `Wormhole().add(...)` instead, because there is some additional processing needed to be done.');
  }

  WormholeCache _cache;
  WormholeCache get cache => _cache;
  set cache(WormholeCache c) {
    assert(_apis.length == 0, 'Cache can only be assigned before Wormhole().setup() has been run.');
    _cache = c;
  }

  operator []=(String name, WRestApi api) {
    assert(api != null, 'API `$name` can\'t be null.');
    assert(setupNotRun, 'Adding APIs after Wormhole.setup() has been run is forbidden.');
    assert(this._apis.containsKey(name) != true, 'Attempt to override an already registered API: `$name`.');

    api.name = name;

    this._apis[name] = api;
  }

  WRestApi operator [] (String name) {
    assert(this.apis.containsKey(name), 'The specified API `$name` doesn\'t seem to be registered.');
    
    return this.apis[name];
  }

  String persistentPrefix = 'wormhole-';

  setup() {
    _apis.forEach((nane, api) => api.loadCache());
    _apis.forEach((nane, api) => api.loadData());
  }

  WRestApi api(String name) {
    assert(this.apis.containsKey(name), 'Attempt to access an unregistered API.');
    return this.apis[name];
  }

  toHtml({ String api }) {
    return WHtmlGenerator().generate();
  }

  toJson({ String api }) {
    return WJsonGenerator().generate(api: api);
  }
  
  //
  // Singleton
  //

  static final Wormhole _singleton = Wormhole._internal();

  factory Wormhole() {
    return _singleton;
  }

  Wormhole._internal();
}

abstract class WormholeCache {

  dynamic getPers(String key);

  void setPers(String key, String val);
}