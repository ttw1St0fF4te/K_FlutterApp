# Настройка API для разных окружений

## Обзор

Приложение поддерживает работу в четырех режимах:
1. **Android Emulator** - для тестирования в Android эмуляторе
2. **iOS Simulator** - для тестирования в iOS симуляторе
3. **Web** - для веб-версии приложения  
4. **Device** - для работы на реальных устройствах (iPhone/Android)

## Текущий IP-адрес компьютера

**IP-адрес в локальной сети:** `192.168.1.90`

> ⚠️ **Важно:** Если ваш IP-адрес изменится, обновите его в файле `lib/config/api_config.dart`

## Переключение между режимами

Откройте файл `lib/config/api_config.dart` и измените значение `currentEnvironment`:

```dart
// Для Android эмулятора
static const Environment currentEnvironment = Environment.androidEmulator;

// Для iOS симулятора  
static const Environment currentEnvironment = Environment.iOSSimulator;

// Для веб-версии
static const Environment currentEnvironment = Environment.web;

// Для реальных устройств (текущая настройка)
static const Environment currentEnvironment = Environment.device;
```

## URL для каждого режима

- **Android Emulator:** `http://10.0.2.2:3000`
- **iOS Simulator:** `http://127.0.0.1:3000`
- **Web:** `http://localhost:3000`
- **Device:** `http://192.168.1.90:3000`

## Проверка IP-адреса

Если IP-адрес компьютера изменился, найдите новый адрес командой:

```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Затем обновите `localNetworkIp` в файле `api_config.dart`.

## Сборка для iOS

1. Убедитесь, что установлен режим `Environment.device`
2. Запустите сервер: `cd nest_api && npm run start:dev`
3. Соберите iOS приложение: `flutter build ios`
4. Убедитесь, что iPhone и компьютер подключены к одной Wi-Fi сети

## Отладка подключения

1. Проверьте доступность сервера: `curl http://192.168.1.90:3000`
2. Убедитесь, что firewall не блокирует порт 3000
3. Проверьте, что устройства в одной сети: пингните с телефона IP компьютера
