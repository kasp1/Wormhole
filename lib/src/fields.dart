import 'WEndpoint.dart';

class WField<T> {
  String name;
  String comment;
  T example;
  RegExp regex;
  List<String> requestPresence;
  List<String> responsePresence;

  WField(this.name, {
    this.comment,
    this.example,
    String regex,
    this.requestPresence,
    this.responsePresence,
  }) : assert(name != null)
  {
    if (regex != null) {
      this.regex = RegExp(regex);
    }
  }

  get type => T;

  WArg<WField, T> toArg<F>() {
    return WArg<WField, T>(this.name);
  }
}

class WID<T> extends WField<T> {
  WID(String name, { 
    String comment, 
    T example, 
    String regex, 
    List<String> requestPresence,
    List<String> responsePresence }) : 
    super(
      name,
      comment: comment,
      example: example,
      regex: regex,
      requestPresence: requestPresence,
      responsePresence: responsePresence
    );

  @override
  WArg<WID, T> toArg<F>() {
    return WArg<WID, T>(this.name);
  }
}

class WUpdated<T> extends WField<T> {
  WUpdated(String name, { 
    String comment, 
    T example, 
    String regex, 
    List<String> requestPresence,
    List<String> responsePresence }) : 
    super(
      name,
      comment: comment,
      example: example,
      regex: regex,
      requestPresence: requestPresence,
      responsePresence: responsePresence
    );

  @override
  WArg<WUpdated, T> toArg<F>() {
    return WArg<WUpdated, T>(this.name);
  }
}

class WCreated<T> extends WField<T> {
  WCreated(String name, { 
    String comment, 
    T example, 
    String regex, 
    List<String> requestPresence,
    List<String> responsePresence }) : 
    super(
      name,
      comment: comment,
      example: example,
      regex: regex,
      requestPresence: requestPresence,
      responsePresence: responsePresence
    );

  @override
  WArg<WCreated, T> toArg<F>() {
    return WArg<WCreated, T>(this.name);
  }
}

class WAccountId<T> extends WField<T> {
  WAccountId(String name, { 
    String comment, 
    T example, 
    String regex, 
    List<String> requestPresence,
    List<String> responsePresence }) : 
    super(
      name,
      comment: comment,
      example: example,
      regex: regex,
      requestPresence: requestPresence,
      responsePresence: responsePresence
    );

  @override
  WArg<WAccountId, T> toArg<F>() {
    return WArg<WAccountId, T>(this.name);
  }
}