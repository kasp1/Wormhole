import '../wormhole.dart';
import 'WGenerator.dart';

class WHtmlGenerator extends WGenerator {
  String generate() {
    String output = '''
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="UTF-8">
    <title>REST API Protocol</title>
    <style>
    body { font-family: 'Arial'; color: #303030; padding: 20px; }
    h1, h2, h3, h4, h5, h6 { display: inline-block; }
    details { margin-left: 15px; }
    code, .role, .required, .range { background-color: #eee; padding: 3px; padding-left: 6px; padding-right: 6px; border-radius: 3px; }
    table { border-collapse: collapse; }
	  table, th, td { border-bottom: 1px solid #eee; }
    th { background-color: #eee; }
    td, th { padding: 6px; }
    td code { white-space: nowrap; }
    summary { cursor: pointer; }
    summary:focus { outline: none; }
    .role, .required { background-color: lightblue; margin-left: 6px; margin-right: 6px; }
    .ranged-info { font-size: .8em; }

    @keyframes open {
      0% { opacity: 0; }
      100% { opacity: 1; }
    }
    details[open] summary ~ * { animation: open .5s ease-in-out; }
    </style>
    </head>
    <body>

    <h1>REST API Protocol</h1>
    ''';

    String emptyCell ='<div style="text-align: center;">-</div>';

    singleEndpoint(WEndpoint endpoint) {
      String roles = '';
      if (endpoint.roles != null) {
        for (String role in endpoint.roles) {
          roles += '<code class="role" title="This role is required to execute this endpoint.">$role</code>';
        }
      }

      String output = '';

      output += '''
      <details>
        <summary><h3><code>${endpoint.toString()}</code></h3>$roles${endpoint.hint != null ? '<span> - ' + endpoint.hint + '</span>' : ''}</summary>
        ${ endpoint.comment != null ? '<p>' + endpoint.comment + '</p>' : '' }
        <p>URL: <code>${endpoint.url}</code></p>
      ''';

      String table = '';
      bool display = true;

      // Query parameters

      table = '';
      String label;
      bool containsRanged = false;
      for (WArg arg in endpoint.args) {
        label = arg.name;

        if (arg.require)
          label = '<span class="required" title="Required parameter">' + label + '</span>';

        if (arg.ranged) {
          containsRanged = true;
          label += ' <span class="range" title="This parameter can be a range, see below.">R*</span>';
        }

        table += '''
        <tr>
          <td>$label</td>
          <td>${arg.type}</td>
          <td>${arg.comment ?? emptyCell}</td>
          <td>${arg.example ?? emptyCell}</td>
        </tr>
        ''';
      }

      String rangeInfo = '';

      if (containsRanged) {
        rangeInfo = '''
              <p class="ranged-info">
                <span class="range">R*</span> Range parameters can be presented in 3 forms:
                <ul class="ranged-info">
                  <li><strong>Equal to value:</strong> <code>parameter=value</code></li>
                  <li><strong>Greater than or equal to value:</strong> <code>parameter=gte:value</code></li>
                  <li><strong>Less than or equal to value:</strong> <code>parameter=lte:value</code></li>
                </ul>
              </p>
        ''';

        if (endpoint.api.filteringFormat == WFilteringFormat.LHS_Brackets) {
          rangeInfo = '''
              <p class="ranged-info">
                <span class="range">R*</span> Range parameters can be presented in 3 forms:
                <ul class="ranged-info">
                  <li><strong>Equal to value:</strong> <code>parameter=value</code></li>
                  <li><strong>Greater than or equal to value:</strong> <code>parameter[gte]=value</code></li>
                  <li><strong>Less than or equal to value:</strong> <code>parameter[lte]=value</code></li>
                </ul>
              </p>
        ''';
        }

        if (endpoint.api.filteringFormat == WFilteringFormat.SearchQuery) {
          rangeInfo = '''
              <p class="ranged-info">
                <span class="range">R*</span> Range parameters can be enclosed in the search query parameter:
                <ul class="ranged-info">
                  <li><strong>Equal to value:</strong> <code>q=parameter1:value[ AND|OR ][parameter2:value]</code></li>
                  <li><strong>Value range:</strong> <code>q=parameter1:[value TO value][ AND|OR ]parameter2:value</code></li>
                </ul>
              </p>
        ''';
        }
      }

      if (endpoint.args.isNotEmpty) {
        output += '''
          <details>
            <summary><h4>Query parameters</h4></summary>
            <table>
              <thead>
                <tr><th>Name</th><th>Type</th><th>Comment</th><th>Example</th></tr>
              </thead>
              <tbody>
                $table
              </tbody>
            </table>
            $rangeInfo
          </details>
        ''';
      }

      // Request body fields

      table = '';
      for (WField field in endpoint.collection.fields) {
        if (field.requestPresence != null) {
          if (field.requestPresence.indexOf(endpoint.operation) >= 0) {

            display = true;
          } else {
            display = false;
          }
        } else {
          display = true;
        }

        if (display) {
          table += '''
          <tr>
            <td>${field.name}</td>
            <td>${field.type} ${field.regex != null ? '<small><code>' + field.regex.pattern + '</code></small>': ''}</td>
            <td>${field.comment ?? emptyCell}</td>
            <td>${field.example ?? emptyCell}</td>
          </tr>
          ''';
        }
      }

      if (table.isNotEmpty) {
        output += '''
          <details>
            <summary><h4>Request body</h4></summary>
            <table>
              <thead>
                <tr><th>Name</th><th>Type</th><th>Comment</th><th>Example</th></tr>
              </thead>
              <tbody>
                $table
              </tbody>
            </table>
          </details>
        ''';
      }

      // Response body fields

      table = '';
      for (WField field in endpoint.collection.fields) {
        if (field.responsePresence != null) {
          if (field.responsePresence.indexOf(endpoint.operation) >= 0) {

            display = true;
          } else {
            display = false;
          }
        } else {
          display = true;
        }

        if (display) {
          table += '''
          <tr>
            <td>${field.name}</td>
            <td>${field.type} ${field.regex != null ? '<small><code>' + field.regex.pattern + '</code></small>': ''}</td>
            <td>${field.comment ?? emptyCell}</td>
            <td>${field.example ?? emptyCell}</td>
          </tr>
          ''';
        }
      }

      if (table.isNotEmpty) {
        output += '''
            <details>
            <summary><h4>Response body</h4></summary>
            <p>The response body is a list of objects with the following properties:</p>
            <table>
              <thead>
                <tr><th>Name</th><th>Type</th><th>Comment</th><th>Example</th></tr>
              </thead>
              <tbody>
                $table
              </tbody>
            </table>
          </details>
        ''';
      }

      output += '</details>';

      return output;
    }

    this.wormhole.apis.forEach((name, api) {
      
      output += '''
      <details open>
        <summary><h2>API: <code>$name</code></h2></summary>
        <p>${api.comment}</p>
        <p>Base URL: <code>${api.base}</code></p>
      ''';

      api.collections.forEach((name, collection) {
        
        output += '''
        <details>
          <summary><h3>Collection: <code>$name</code></h3></summary>
          <p>${collection.comment}</p>
          <p>URL: <code>${api.base}$name[/]</code></p>
        ''';

        collection.endpoints.forEach((operation, endpoint) {
          output += (collection.endpoint(operation) is WEndpoint) ?
            singleEndpoint(endpoint) : '';
        });

        output += '</details>';
      });

      output += '</details>';
    });

    output += '''
    </body>
    </html>
    ''';

    return output.replaceAll(RegExp('(\n|\\s{2,})'), ' ');
    //return output;
  }
}