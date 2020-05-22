> :warning: **Not production ready**: Wormhole is currently a concept library with uncertain future. 

# wormhole

![Wormhole Logo](assets/logo.png)

Client/server transport layer.

Wormhole loads data from any REST API service into your app and synchronizes data changes made in your app back to the REST API service. All automatic and controlled.

Just define the protocol and enjoy:
- Automatic data retrieval on demand.
- Optional periodic data refresh to reflect current data.
- Working with retrieved data the same way you would work with regular Dart `List`s and `Map`s.
- Automatic data creation (`POST`), update (`PUT`) and removal (`DELETE`) requests to the corresponding API service upon editing the locally held data copy.
- Provider compatibility.
- Support for user accounts and roles.
- Full endpoint and data processing customization.
- Working simultaneously with multiple REST API services.
- Server-less development with example data.
- API reference export to HTML or JSON for your server side dev.
- Offline apps with local data cache.


# Intro sample

Imagine you want to display a list of all countries of the world in your app. We'll use [this REST API endpoint](https://restcountries.eu/rest/v2/all) for that, which will give us a response in the following format:

```json
[
  {
    "name": "Country name",
  },
]
```

The code you need to display the list of countries is:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wormhole/wormhole.dart';

void main() {
  Store().setupProtocol();
  Store().bootstrap();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<Store>.value(
      value: Store(),
      child: MaterialApp(
        title: 'Wormhole Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: CountriesScreen()
      )
    );
  }
}

class CountriesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Store provider = Provider.of<Store>(context);

    return Scaffold(
      body: (provider.countries.length > 0) ? ListView.builder(
        itemCount: provider.countries.length,
        itemBuilder: (BuildContext context, int index) {
          return Card(
            child: Text(provider.countries.list[index]['name'])
          );
        }
      ) :
      Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

//
// This is a sort of fusion of Wormhole and Provider.
// While Wormhole automatically loads and synchronizes
// data between the app and the server, Provider takes
// care of automatically reflecting data in your app.
// The magic happens behind the scenes, you can focus
// on building your UI.
//

class Store with ChangeNotifier {
  WCollection countries;

  // Just define the REST API protocol, Wormhole handles the rest.
  void setupProtocol() {
    Wormhole()['countries-api'] = WRestApi(base: 'https://restcountries.eu/rest/v2/');

    // this translates into https://restcountries.eu/rest/v2/all
    Wormhole()['countries-api']['all'] = WCollection(
      fields: [
        WID<String>('name'),
      ]
    );

    Wormhole().setup();
  }

  void bootstrap() {
    countries = Wormhole()['countries-api']['all'] & notifyListeners;
  }
  
  // Singleton
  static final Store _singleton = Store._internal();
  factory Store() => _singleton;
  Store._internal();
}

```

Try this sample on your own. Just create a new Flutter project, replace the code in `main.dart` with the code above and add dependencies to the `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider:
  wormhole:
```

Also, please don't forget to use these dependencies with any of the below examples.

# How it works

Although you can customize endpoint URIs, HTTP methods, access conditions or event the way data is handled, by default Wormhole expects your API to be in the following format.

First, There's always a base URL for an API and the rest is a collection name. For example an app where people post their statuses (Twitter / Facebook like app) would have the following base URL:
```
https://YourRestService/v1/
```

Everything after the base URL would be collections, for example:
```
https://YourRestService/v1/posts
```

By default, Wormhole assumes the following endpoints are available for a collection:

- `GET https://YourRestService/v1/posts` responds with a complete list of posts.
- `GET https://YourRestService/v1/posts/mine` responds with a list of posts created by the currently logged in user.
- `POST https://YourRestService/v1/posts` creates a new post.
- `PUT https://YourRestService/v1/posts/<id>` edits an existing post.
- `DELETE https://YourRestService/v1/posts/<id>` deletes an existing post.

In Wormhole, the definition of such a protocol would look like this (`lib/protocol.dart`):
```dart
import 'dart:core';
import 'package:wormhole/wormhole.dart';

// This function is to be called at the very beginning of your app.
setupProtocols() {

  // Create an API definition. Because we can work with multiple
  // APIs simultaneously, we need to give each API an identifier,
  // which is `main` API in this case.
  Wormhole()['main'] = WRestApi(
    base: 'https://YourRestService/v1/',
    // comments are useful for exporting API reference
    comment: 'Posts App API',
  );

  // User posts definition
  Wormhole()['main']['posts'] = WCollection(
    comment: 'User posts.',
    fields: [
      WID<int>('id'),
      WField<String>('content'),
      WCreated<int>('created', comment: 'Creation timestamp (seconds).'),
      WCreated<int>('updated', comment: 'Last update timestamp (seconds).'),
    ],
  );

  Wormhole().setup();
} 
```

Once defined, we can use any collection just as regular a regular `List<Map>` in our app. Let's say we'll create a class called `Store` to hold our data:

```dart
import 'dart:async';
import 'package:wormhole/wormhole.dart';

import 'protocol.dart';

class Store  {
  WCollection posts;

  void bootstrap() async {
    setupProtocols();
    posts = Wormhole()['main']['posts'];
  }
  
  // Singleton
  static final Store _singleton = Store._internal();
  factory Store() => _singleton;
  Store._internal();
}

```

We can now call any regular `List<Map>` operations on `Store().posts`. For example, to add a new post, we can call:
```dart
Store().posts.add({
  content: 'My first post!'
  // id, created and updated can be omitted here
});
```

The above call will not only add the data to the Wormhole's local copy, but also will make a `POST https://YourRestService/v1/posts` request with the `content` parameter in the request body.

To achieve the ultimate zen mode, combine Wormhole with Provider:
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wormhole/wormhole.dart';

import 'protocol.dart';

class Store with ChangeNotifier {
  WCollection posts;

  void bootstrap() async {
    setupProtocols();
    // `& notifyListeners` makes Wormhole call notifyListeners() upon every
    // change to the local data copy 
    posts = Wormhole()['main']['posts'] & notifyListeners;
  }
  
  // Singleton
  static final Store _singleton = Store._internal();
  factory Store() => _singleton;
  Store._internal();
}
```

You can now use provider to reflect any data change in the list of posts in your UI:
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wormhole/wormhole.dart';

void main() {
  Store().bootstrap();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // notice we are using ChangeNotifierProvider parent to our entire app,
    // so changes in data trigger rebuilding the UI
    return ChangeNotifierProvider<Store>.value(
      value: Store(),
      child: MaterialApp(
        title: 'Wormhole Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: PostsScreen()
      )
    );
  }
}

class PostsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Store provider = Provider.of<Store>(context);

    return Scaffold(
      body: (provider.posts.length > 0) ? ListView.builder(
        itemCount: provider.posts.length,
        itemBuilder: (BuildContext context, int index) {
          return Card(
            child: Text(provider.posts.list[index]['content'])
          );
        }
      ) :
      Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```
