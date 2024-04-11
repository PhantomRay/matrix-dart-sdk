# Matrix API Lite

This package is a dead simple data model over the client-server specification of https://matrix.org and is mostly used as a base for a more complete Matrix SDK.
It doesn't contain any logic and just provides methods for all API endpoints and json parser for all objects. It is intended to be as close to the specificaton
as possible so we get a 1:1 relationship with the API. More complex logic like a sync loop or a data model for rooms should be implemented in a more complete
Matrix SDK.

## Usage

A simple usage example:

```dart
import 'package:matrix/matrix_api_lite.dart';

void main() async {
  final api = MatrixApi(homeserver: Uri.parse('https://matrix.org'));
  final capabilities = await api.requestServerCapabilities();
  print(capabilities.toJson());
}

```

## Generated code

The files in `lib/src/generated` are generated by [dart_openapi_codegen](https://gitlab.com/famedly/company/frontend/dart_openapi_codegen/)
from [matrix-spec](https://github.com/matrix-org/matrix-spec/).

To regenerate the code, follow these steps:

1. Clone both repositories next to each other
  1.1 `git clone git@github.com:famedly/dart_openapi_codegen.git`
  1.2 `git clone git@github.com:famedly/matrix-dart-sdk.git`
2. Execute the script in the dart_openapi_codegen directory:
```sh
cd dart_openapi_codegen
./scripts/matrix.sh ../matrix-dart-sdk/lib/matrix_api_lite/generated
cd ..
```
3. Run the build_runner in the matrix_api_lite directory to generate enhanced_enum stuff:
```sh
cd matrix-dart-sdk
dart pub get
dart run build_runner build
```
4. Check lints and tests and create a merge request