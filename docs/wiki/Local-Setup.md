# Локальный запуск

## Требования

- macOS с Xcode.
- iOS Simulator или физическое устройство.
- Доступ к repository [Strongf-bob/SplitApp](https://github.com/Strongf-bob/SplitApp).
- Доступный backend API. По умолчанию frontend обращается к серверу `http://46.243.201.8:8080`.
- Для полной локальной разработки рядом нужен backend repository [Strongf-bob/SplitAppBackend](https://github.com/Strongf-bob/SplitAppBackend).

## Запуск iOS-приложения

1. Открыть [SplitApp.xcodeproj](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp.xcodeproj) в Xcode.
2. Выбрать scheme `SplitApp`.
3. Выбрать iOS Simulator.
4. Запустить `Run`.

## Backend для разработки

Backend запускается из репозитория [Strongf-bob/SplitAppBackend](https://github.com/Strongf-bob/SplitAppBackend). Инструкции находятся в:

- [README backend](https://github.com/Strongf-bob/SplitAppBackend/blob/main/README.md)
- [Backend Local Setup Wiki](https://github.com/Strongf-bob/SplitAppBackend/blob/main/docs/wiki/Local-Setup.md)

Коротко:

```bash
cd ../SplitAppBackend
make setup
cp .env.example .env
make run-dev
```

Local backend URL по умолчанию:

```text
http://localhost:8000
```

## Backend base URL

Сейчас base URL задан в [APIConfiguration.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Network/APIConfiguration.swift) как:

```swift
static let baseURL = URL(string: "http://46.243.201.8:8080")!
```

Так как текущий сервер доступен по HTTP и IP-адресу, в [Info.plist](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Info.plist) добавлено ATS-исключение для `46.243.201.8`. Для удобной локальной backend-разработки позже можно добавить environment-aware switch: production server, simulator local backend и, при необходимости, staging.

## Где смотреть ошибки

- Network errors нормализуются в [NetworkError.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Network/NetworkError.swift).
- User-facing mapping находится в [UserFacingErrorMapper.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Shared/Errors/UserFacingErrorMapper.swift).
- Decode failures дополнительно печатают тело ответа в [APIClient.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Network/APIClient.swift), чтобы быстрее поймать рассинхрон DTO и backend schema.
