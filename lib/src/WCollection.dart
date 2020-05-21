import '../wormhole.dart';

class WCollection {
  String name;
  WRestApi api;
  List<WField> fields;
  String comment;
  int _idAt = -1;
  int refreshInterval;
  List<Map> _data = [];
  List<Function> _reactives = [];
  Map<String, WEndpoint> _endpoints = {};
  Map<String, WEndpoint> get endpoints => _endpoints;
  List<Map> defaultData;
  bool isLoading = false;

  WCollection({
    this.api,
    this.fields,
    this.refreshInterval = 0,
    this.comment,
    this.defaultData,
  }) : assert(fields != null)
  {
    // default request and response presence
    for (int i = 0; i < fields.length; i++) {
      if (fields[i] is WID) {
        assert(_idAt < 0, 'All collections must only contain a single ID field WID<T>(...)');

        _idAt = i;

        fields[i].requestPresence = fields[i].requestPresence ?? [];

        fields[i].responsePresence = fields[i].responsePresence ?? ['read', 'list', 'mine'];
      } else if (fields[i] is WAccountId) {
        fields[i].requestPresence = fields[i].requestPresence ?? [ 'create', 'update' ];
        fields[i].responsePresence = fields[i].responsePresence ?? [ 'list', 'read' ];
      } else if ((fields[i] is WUpdated) || (fields[i] is WCreated)) {
        fields[i].requestPresence = fields[i].requestPresence ?? [];
        fields[i].responsePresence = fields[i].responsePresence ?? [ 'list', 'read', 'mine' ];
      } else {
        fields[i].requestPresence = fields[i].requestPresence ?? [ 'create', 'update' ];
        fields[i].responsePresence = fields[i].responsePresence ?? [ 'list', 'read', 'mine' ];
      }
    }
  }

  setup() {
    List<WArg> queryArgs = [];

    for (WField field in fields) {
      if (!field.runtimeType.toString().contains('WID')) {
        queryArgs.add(field.toArg());
      }
    }

    List<WArg> pagingArgs = [
      WArg<WField, int>('offset', rangeDisabled: true),
      WArg<WField, int>('limit', rangeDisabled: true)
    ];

    _endpoints['list'] = _setupEndpoint(
      'list',
      WEndpoint(
        WHttpMethod.GET,
        hint: 'List ' + name,
        comment: 'A list of matched records from ' + name,
        args: queryArgs + pagingArgs
      )
    );
    
    _endpoints['read'] = _setupEndpoint(
      'read',
      WEndpoint(
        WHttpMethod.GET,
        hint: 'Get single',
        comment: 'Get a single record from ' + name,
        args: [ WArg<WID, String>('id', require: true) ]
      )
    );

    _endpoints['mine'] = _setupEndpoint(
      'mine',
      WEndpoint(
        WHttpMethod.GET,
        path: name + '/mine',
        hint: 'Get owned',
        comment: 'Get a list of records from ' + name + ' where there is the current user\'s ID mentioned.',
        args: [ ...queryArgs, ...pagingArgs ]
      )
    );

    _endpoints['create'] = _setupEndpoint(
      'create',
      WEndpoint(
        WHttpMethod.POST,
        hint: 'Create a record',
        comment: 'Create a record in ' + name,
      )
    );

    _endpoints['update'] = _setupEndpoint(
      'update',
      WEndpoint(
        WHttpMethod.PUT,
        hint: 'Change records',
        comment: 'Change records in ' + name,
        args: [ WArg<WID, String>('id', require: true), ...queryArgs, ...pagingArgs ]
      )
    );

    _endpoints['delete'] = _setupEndpoint(
      'delete',
      WEndpoint(
        WHttpMethod.DELETE,
        hint: 'Delete records',
        comment: 'Delete records from ' + name,
        args: [ WArg<WID, String>('id', require: true) ]
      )
    );
  }

  WEndpoint override(String operation, { WEndpoint endpoint }) {
    if (_endpoints.containsKey(operation)) {
      if (endpoint != null) {
        if (_endpoints[operation] == null)
          throw WDisabledEndpointException(api.name, name, operation);

        _endpoints[operation] = _setupEndpoint(operation, endpoint);
        return _endpoints[operation];
      } else {
        return _endpoints[operation];
      }
    }

    if (endpoint != null) {
      _endpoints[operation] = _setupEndpoint(operation, endpoint);
      return _endpoints[operation];
    }

    throw WUndefinedEndpointException(api.name, name, operation);
  }

  WEndpoint endpoint(String operation) {
    if (_endpoints.containsKey(operation)) {
      //if (_endpoints[operation] == null)
      //  throw WDisabledEndpointException(api.name, name, operation);

      return _endpoints[operation];
    }
    
    throw WUndefinedEndpointException(api.name, name, operation);
  }

  disable(String operation) {
    if (_endpoints.containsKey(operation)) {
      if (_endpoints[operation] == null)
        throw WDisabledEndpointException(api.name, name, operation);

      _endpoints[operation] = null;
    } else {
      assert(false, 'The endpoint for operation `$operation` in collection `$name` has not been specified. You seem to be trying to disable an unspecified endpoint. (That would probably make little sense.)');
    }
  }

  WEndpoint _setupEndpoint(String op, WEndpoint end) {
    end.operation = op;
    end.api = this.api;
    end.collection = this;

    if (end is WEndpoint)
      end.setup();

    return end;
  }

  _refreshData(/*Map<String, dynamic> conditions*/) async {
    isLoading = true;

    this._data = [];

    List<dynamic> data = await endpoint('list').perform();
    
    data.forEach((item) {
      Map record = {};

      if (item is Map) {
        this.fields.forEach((field) {
          if (item.containsKey(field.name)) {
            record[field.name] = item[field.name];
          }
        });

        _data.add(record);
      }
    });

    isLoading = false;

    notifyListeners();
  }

  loadData() {
    this._refreshData();
  }

  int get length {
    if (_data.isNotEmpty)
      return _data.length;

    if (defaultData != null)
      return defaultData.length;
    
    return _data.length;
  }

  void operator =(List<Map> value) {
    assert(false, 'Resetting an entire collection is forbidden. If you believe this should be possible, please discuss at https://github.com/kasp1/Wormhole/issues/1');
  };

  Map operator [](int index) {
    if (_data.isNotEmpty)
      return _data[index];

    if (defaultData != null)
      return defaultData[index];
    
    return _data[index];
  }

  WCollection operator &(Function notifyListenersCallback) {
    if (notifyListenersCallback != null)
      this._reactives.add(notifyListenersCallback);

    return this;
  }

  notifyListeners() {
    for (Function reactive in this._reactives) {
      if (reactive != null)
        reactive();
    }
  }

  loadCache() {
  }

  WField field(String name) {
    for (WField field in fields) {
      if (field.name == name)
        return field;
    }

    return null;
  }

  //
  // Actual operations
  //
  
  /// Returns local copy of the data.
  List<Map> get list {
    if (_data.isNotEmpty)
      return _data;

    if (defaultData != null)
      return defaultData;
    
    return _data;
  }

  List<Map> find(Map<String, dynamic> conditions) {

    // conditions validity check

    conditions.forEach((field, value) {
      if (this.field(field) == null)
        throw WInvalidConditionFieldException(api.name, name, field);

      if (value is List) {
        if (value.length == 2) {
          if (
            this.field(field).type.toString().contains(value[0].runtimeType.toString()) &&
            this.field(field).type.toString().contains(value[1].runtimeType.toString())
          ) {
            if (value[0] > value[1]) {
              throw WInvalidConditionValueException(api.name, name, field);
            }
          } else {
            throw WInvalidConditionValueException(api.name, name, field);
          }
        } else {
          throw WInvalidConditionValueException(api.name, name, field);
        }
      } else if (!this.field(field).type.toString().contains(value.runtimeType.toString())) {
        throw WInvalidConditionValueException(api.name, name, field);
      }
    });

    // selecting rows based on conditions

    List<Map> matched = [];

    Map row;
    for (int i = 0; i < list.length; i++) {
      row = list[i];
      conditions.forEach((field, value) {
        if (value is List) {
          if ((value[0] <= row[field]) && (row[field] <= value[1])) {
            matched.add(row);
          }
        } else if (row[field] == value) {
          matched.add(row);
        }
      }); 
    }

    return matched;
  }
  
  List<Map> read(dynamic id) {
    if (_endpoints['read'] == null)
      throw WUndefinedEndpointException(api.name, name, 'read');

    if (_idAt < 0)
      throw WMissingIdFieldException(api.name, name);
    
    return find({ 'id': id });
  }
  
  List<Map> mine() {
    if (_endpoints['mine'] == null)
      throw WUndefinedEndpointException(api.name, name, 'mine');
    
    return list;
  }
  
  Future create(Map record) async {
    if (_endpoints['create'] == null)
      throw WUndefinedEndpointException(api.name, name, 'create');
    // ...

    notifyListeners();
  }
  
  Future update(dynamic id, Map record) async {
    if (_endpoints['update'] == null)
      throw WUndefinedEndpointException(api.name, name, 'update');

    if (_idAt < 0)
      throw WMissingIdFieldException(api.name, name);
    // ...

    notifyListeners();
  }
  
  Future delete(dynamic id) async {
    if (_endpoints['delete'] == null)
      throw WUndefinedEndpointException(api.name, name, 'delete');

    if (_idAt < 0)
      throw WMissingIdFieldException(api.name, name);
    // ...

    notifyListeners();
  }

  Future noSuchMethod(Invocation invocation) {
    String operation = invocation.memberName.toString();

    if (_endpoints.containsKey(operation)) {
      if (_endpoints[operation] == null)
        throw WDisabledEndpointException(api.name, name, operation);

      return _endpoints[operation].perform();
    }
    
    throw WUndefinedEndpointException(api.name, name, 'delete');
  }
}

//
// Account collection
//

class WAccountCollection extends WCollection {

  WAccountCollection({
    WRestApi api,
    List<WField> fields,
    int refreshInterval,
    String comment,
    List<Map> defaultData
  }) : super(
    api: api,
    fields: fields,
    refreshInterval: refreshInterval,
    comment: comment,
    defaultData: defaultData
  );

  setup() {
    super.setup();

    _endpoints['create'].hint = 'Registration';
    _endpoints['create'].comment = 'New account registration.';

    _endpoints['mine'].hint = 'Own account';
    _endpoints['mine'].comment = 'Retrieve the account information of the currently signed in account.';

    _endpoints['update'].hint = 'Change account';
    _endpoints['update'].comment = 'Change account information. E.g. email, name, password or any account fields.';

    _endpoints['delete'].hint = 'Remove account';
    _endpoints['delete'].comment = 'Remove the user account from the API server.';

    _endpoints['sign-in'] = _setupEndpoint(
      'sign-in',
      WEndpoint(
        WHttpMethod.GET,
        hint: 'Authentication',
        comment: 'Authenticate with the server using a specific account.',
        path: 'sign-in',
        args: [
          WArg<WField, String>('email', require: true),
          WArg<WField, String>('password', require: true),
        ],
        handler: (context, response) {
          context.api.authToken = response.data.token;
        }
      )
    );

    _endpoints['sign-out'] = _setupEndpoint(
      'sign-out',
      WEndpoint(
        WHttpMethod.GET,
        hint: 'Sign-out',
        comment: 'Sign out from the server with the currently authenticated account.',
        path: 'signout',
      )
    );

    _endpoints['initiate-password-recovery'] = _setupEndpoint(
      'initiate-password-recovery',
      WEndpoint(
        WHttpMethod.GET,
        hint: 'Password reset part 1',
        comment: 'The API server sends an email to the specified email address (unless it is not connected with an existing account). The email contains a token / PIN code, which is then passed into the `password-recovery` endpoint.',
        path: 'initiate-password-recovery',
        args: [
          WArg<WField, String>('email', require: true),
        ],
      )
    );

    _endpoints['password-recovery'] = _setupEndpoint(
      'password-recovery',
      WEndpoint(
        WHttpMethod.GET,
        hint: 'Password reset part 2',
        comment: '',
        path: 'password-recovery',
        args: [
          WArg<WField, String>('token', require: true, comment: 'PIN recevied in an email from the server.'),
          WArg<WField, String>('password', require: true, comment: 'The new password.'),
        ],
      )
    );
  }
}