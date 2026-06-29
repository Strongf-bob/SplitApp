# Архитектура iOS-приложения

## Слои

| Слой | Папка | Ответственность |
| --- | --- | --- |
| App | [SplitApp/App](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/App) | Entry point, dependency wiring, root view. |
| Core | [SplitApp/Core](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Core) | Network, auth primitives, database, shared infrastructure. |
| Domain | [SplitApp/Domain](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Domain) | Модели, repository contracts, command models. |
| Data | [SplitApp/Data](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Data) | DTO, mappers, repositories, endpoints, Core Data DTO mappers. |
| Features | [SplitApp/Features](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Features) | Экраны, view models и feature-specific models. |
| Shared | [SplitApp/Shared](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Shared) | UI components, modifiers, theme, errors, decoding helpers. |

## Dependency wiring

[AppDependencies.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/App/AppDependencies.swift) собирает live dependencies:

- `APIClient.shared`
- `CoreDataStore.shared`
- `NetworkMonitor.shared`
- repositories для events, receipts, users, balances, payments, active event и friends
- `EventManagementService`

Эта точка важна для тестируемости: feature view models должны зависеть от contracts/repositories, а не создавать network/database объекты напрямую.

## Feature-модули

| Feature | Папка | Назначение |
| --- | --- | --- |
| Authorization | [SplitApp/Features/Authorization](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Features/Authorization) | Login, bootstrap, logout, app auth state. |
| Navigation | [SplitApp/Features/Navigation](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Features/Navigation) | Bottom tab bar, route/state для событий. |
| Events | [SplitApp/Features/Events](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Features/Events) | Home screen, event list, receipt list, balances and event actions. |
| BillEntry | [SplitApp/Features/BillEntry](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Features/BillEntry) | Создание и редактирование чеков. |
| Friends | [SplitApp/Features/Friends](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Features/Friends) | Список друзей и debts view. |
| UserProfile | [SplitApp/Features/UserProfile](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Features/UserProfile) | Экран профиля и profile view model. |
| ReceiptScanner | [SplitApp/Features/ReceiptScanner](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Features/ReceiptScanner) | Сканирование/парсинг чеков и изображения. |
| EmojiFeature | [SplitApp/Features/EmojiFeature](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Features/EmojiFeature) | Emoji parsing and prediction helpers. |

## Поток данных

1. View вызывает ViewModel action.
2. ViewModel вызывает service или repository contract.
3. Data repository вызывает `APIClient` и, если нужно, обновляет Core Data.
4. DTO конвертируется mapper-ом в domain model.
5. UI получает domain/view model state.

## Правила разработки

- Не держать backend-specific JSON shape во View.
- Не вызывать `URLSession` напрямую из feature-кода; использовать `APIClient` через repository.
- Не хранить refresh token в UserDefaults; только Keychain.
- Не считать local cache источником authorization.
- Новые endpoints добавлять в `SplitApp/Data/Network/Endpoints`, DTO - в `SplitApp/Data/DTOs`, mapping - в `SplitApp/Data/Mappers`.

