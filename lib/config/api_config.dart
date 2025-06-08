// API Configuration for different environments
class ApiConfig {
  // IP адрес вашего компьютера в локальной сети (для реальных устройств)
  static const String localNetworkIp = '192.168.1.90';
  
  // Different base URLs for different environments
  static const String _androidEmulatorUrl = 'http://10.0.2.2:3000';
  static const String _iOSSimulatorUrl = 'http://127.0.0.1:3000';
  static const String _webUrl = 'http://localhost:3000';
  static const String _deviceUrl = 'http://$localNetworkIp:3000';
  
  // Current environment - change this based on your needs
  static const Environment currentEnvironment = Environment.device;
  
  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.androidEmulator:
        return _androidEmulatorUrl;
      case Environment.iOSSimulator:
        return _iOSSimulatorUrl;
      case Environment.web:
        return _webUrl;
      case Environment.device:
        return _deviceUrl;
    }
  }
}

enum Environment {
  androidEmulator,
  iOSSimulator,
  web,
  device,
}
