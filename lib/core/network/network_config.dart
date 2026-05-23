import 'package:injectable/injectable.dart';

abstract class NetworkConfig {
  String get baseUrl;
}

@Injectable(as: NetworkConfig)
class DevNetworkConfig implements NetworkConfig {
  @override
  String get baseUrl => 'https://api.heidev.dev';
}
