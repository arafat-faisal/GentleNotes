enum Flavor {
  dev,
  prod,
}

class FlavorConfig {
  final Flavor flavor;
  final String appName;
  final String apiBaseUrl; 
  
  static FlavorConfig? _instance;
  
  factory FlavorConfig({
    required Flavor flavor,
    required String appName,
    String apiBaseUrl = '',
  }) {
    _instance ??= FlavorConfig._internal(flavor, appName, apiBaseUrl);
    return _instance!;
  }
  
  FlavorConfig._internal(this.flavor, this.appName, this.apiBaseUrl);
  
  static FlavorConfig get instance {
    return _instance!;
  }
  
  static bool get isDev => _instance?.flavor == Flavor.dev;
  static bool get isProd => _instance?.flavor == Flavor.prod;
}
