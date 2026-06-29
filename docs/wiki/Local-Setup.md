# Локальный запуск

## Требования

- macOS с Xcode.
- iOS Simulator или физическое устройство.
- Доступ к repository [Strongf-bob/SplitApp](https://github.com/Strongf-bob/SplitApp).
- Доступный backend API. По умолчанию frontend обращается к production URL `https://splitapp.tech`.
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

## Важное ограничение base URL

Сейчас base URL задан в [APIClient.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Network/APIClient.swift) как:

```swift
private let baseURL = URL(string: "https://splitapp.tech")!
```

Для удобной локальной backend-разработки нужен environment-aware switch: production `https://splitapp.tech`, simulator local backend и, при необходимости, staging. Пока такого переключателя нет, локальная проверка backend-интеграции требует временного изменения URL или отдельной настройки.

## Где смотреть ошибки

- Network errors нормализуются в [NetworkError.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Network/NetworkError.swift).
- User-facing mapping находится в [UserFacingErrorMapper.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Shared/Errors/UserFacingErrorMapper.swift).
- Decode failures дополнительно печатают тело ответа в [APIClient.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Network/APIClient.swift), чтобы быстрее поймать рассинхрон DTO и backend schema.

