# wormhole

![Wormhole Logo](assets/logo.png)

Client/server transport layer.

# Introduction

Imagine you want to display a list of all countries of the world in your app. We'll use [this REST API endpoint](https://restcountries.eu/rest/v2/all) for that, which will give us a response in the following format:

```json
[
  {
    name: "Country name",
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
// While Wormhole automatically loads and synchronizes,
// data between the app and the server, Provider takes
// care of automatically reflecting data in your app.
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

If you want to try this example on your own, just create a new Flutter project, replace the code in main.dart with the code above and add dependencies to the pubspec.yaml file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider:
  wormhole:
```

# Cookbook

## Chat protocol