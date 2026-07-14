# Локальный запуск

## Требования

| Что | Зачем |
| --- | --- |
| macOS и Xcode | сборка SwiftUI-приложения и Simulator |
| iOS Simulator или устройство | запуск UI и проверка OAuth callback |
| Доступ к backend | реальные сценарии требуют API по base URL из [APIConfiguration](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Network/APIConfiguration.swift) |
| Yandex OAuth configuration | вход через SDK; значения определены в [YandexOAuthConfiguration](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Auth/YandexOAuthConfiguration.swift) |

## Запуск

1. Откройте [`SplitApp.xcodeproj`](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp.xcodeproj) в Xcode.
2. Выберите scheme `SplitApp` и доступный simulator/устройство.
3. Соберите и запустите приложение (`Cmd+R`).
4. Для запуска тестов используйте scheme тестов или `Cmd+U`.

Для backend-разработки работайте рядом с [SplitAppBackend](https://github.com/Strongf-bob/SplitAppBackend): локальный запуск, env и миграционные сведения есть в [backend Local Setup](https://github.com/Strongf-bob/SplitAppBackend/blob/main/docs/wiki/Local-Setup.md). Не меняйте base URL в произвольном feature-файле — единственная клиентская конфигурация находится в `APIConfiguration`.

## Быстрая диагностика

| Симптом | Проверить |
| --- | --- |
| Всегда виден login | refresh token/Keychain и [bootstrap](Authentication-And-Security) |
| После входа нет данных | base URL, сеть, backend health и `APIClient` error |
| Ошибка OAuth callback | bundle/configuration и логи `YandexLoginSDK` |
| Экран показывает старые данные | состояние сети, repository fallback и Core Data |

Дальше: [Тесты и качество](Testing-And-Quality).
