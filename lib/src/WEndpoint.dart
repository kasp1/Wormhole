import 'package:http/http.dart';

import '../wormhole.dart';

import 'enums.dart';

class WArg<F, T> {
  String name;
  String comment;
  String example;
  bool require = false;
  bool rangeDisabled = false;

  WArg(this.name, { this.require = false, this.rangeDisabled = false, this.comment, this.example });

  get type => T;
  get fieldType => F;

  bool get ranged => ((T.toString().contains('int') || T.toString().contains('double')) && !rangeDisabled) ? true : false;
}

class WEndpoint {
  String operation;
  WRestApi api;
  WCollection collection;
  WHttpMethod method;
  String path;
  List<String> roles = [];
  String comment;
  String hint;
  Function handler;
  List<WArg> args = [];
  int _idAt;

  WEndpoint(this.method, {
    this.operation,
    this.api,
    this.collection,
    List<WArg> args,
    this.path,
    List<String> roles,
    this.comment,
    this.hint,
    this.handler,
  }) {
    if (args != null) this.args = args;
    if (roles != null) this.roles = roles;
  }

  setup() {
    assert(method != null, 'WHttpMethod must be specified.');
    assert(path != null || collection != null, 'Either url or collection has to be specified in a WCustomEndpoint instance.');

    path = (path != null ? path : collection.name);
  }

  int get idPos {
    if (_idAt == null) {
      bool notFound = true;
      for (int i = 0; i < args.length; i++) {
        if (args[i].fieldType.toString().contains('WID')) {
          assert(notFound, 'There can only be a single `WID` argument in an endpoint.');

          notFound = false;
          _idAt = i;
        }
      }

      if (notFound)
        _idAt = -1;
    }

    return _idAt;
  }

  String operationToString() => operation;

  String methodToString() {
    String met;

    switch (method) {
      case WHttpMethod.GET: met = 'GET'; break;
      case WHttpMethod.POST: met = 'POST'; break;
      case WHttpMethod.PUT: met = 'PUT'; break;
      case WHttpMethod.DELETE: met = 'DELETE'; break;
      case WHttpMethod.HEAD: met = 'HEAD'; break;
      case WHttpMethod.CONNECT: met = 'CONNECT'; break;
      case WHttpMethod.TRACE: met = 'TRACE'; break;
      case WHttpMethod.OPTIONS: met = 'OPTIONS'; break;
      case WHttpMethod.PATCH: met = 'PATCH'; break;
    }

    return met;
  }

  bool isAuthorized(List<String> userRoles) {
    if (roles == null) {
      return true;
    }

    for (String userRole in userRoles) {
      if (roles.contains(userRole)) {
        return true;
      }
    }

    return false;
  }

  Future perform({ Map args }) async {
    if (this.handler != null) {
      Response response = await this.api.request(method, url, args: args);

      return handler(this, response);
    } else {
      return await api.request(method, url, args: args);
    }
  }

  String get url => api.base + path;

  String toString() {
    List<WArg> requiredArgs = [];

    for (int i = 0; i < args.length; i++) {
      if (args[i].require && (i != idPos)) {
        requiredArgs.add(args[i]);
      }
    }

    List<String> query = [];
    for (WArg arg in requiredArgs) {
      query.add(arg.name + '=&lt;' + arg.type.toString() + '&gt;');
    }

    String ending = '';

    if (idPos >= 0) {
      ending += '/&lt;id, ' + args[idPos].type.toString() + '&gt;';
    } else {
      ending += requiredArgs.isNotEmpty ? '/' : '[/]';
    }
    
    ending += query.isNotEmpty ? '?' + query.join('&amp;') : '';

    return methodToString() + ' ' + path + ending;
  }
}