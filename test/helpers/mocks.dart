import 'package:amconnect/core/network/api_client.dart';
import 'package:mocktail/mocktail.dart';

/// Doble de `ApiClient` para pruebas de repositorios/providers. Se inyecta con
/// `ProviderContainer(overrides: [apiClientProvider.overrideWithValue(mock)])`.
class MockApiClient extends Mock implements ApiClient {}
