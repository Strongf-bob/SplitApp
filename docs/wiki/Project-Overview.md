# Обзор проекта

## Назначение

SplitApp помогает группе людей разделять общие расходы. Пользователь создает событие, добавляет участников, вносит чеки, распределяет позиции между участниками и видит итоговые долги. Платежи используются для фиксации погашения долга между двумя пользователями.

## Связанные GitHub-репозитории

| Часть | Репозиторий | Ответственность |
| --- | --- | --- |
| iOS frontend | [Strongf-bob/SplitApp](https://github.com/Strongf-bob/SplitApp) | SwiftUI UI, local cache, Yandex login flow, network client, DTO mapping. |
| Backend API | [Strongf-bob/SplitAppBackend](https://github.com/Strongf-bob/SplitAppBackend) | Auth, users, events, receipts, balances, payments, storage, API contract. |
| Backend contract | [openapi.yaml](https://github.com/Strongf-bob/SplitAppBackend/blob/main/openapi.yaml) | Источник правды по HTTP endpoints, request/response models и status codes. |

## Основные пользовательские сценарии

- Авторизация через Yandex OAuth.
- Просмотр списка событий и выбор активного события.
- Создание события и управление его участниками.
- Добавление чека с позициями, payer и shares.
- Просмотр балансов по событию.
- Создание и подтверждение платежей.
- Просмотр списка друзей и долгов.
- Просмотр профиля текущего пользователя.

## Ключевые файлы frontend

- App entrypoint: [SplitApp/App/SplitAppApp.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/App/SplitAppApp.swift)
- Dependency wiring: [SplitApp/App/AppDependencies.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/App/AppDependencies.swift)
- Main content: [SplitApp/App/ContentView.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/App/ContentView.swift)
- Network client: [SplitApp/Core/Network/APIClient.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Network/APIClient.swift)
- Endpoint declarations: [SplitApp/Data/Network/Endpoints](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Data/Network/Endpoints)
- Core Data store: [SplitApp/Core/Database/CoreDataStore.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Database/CoreDataStore.swift)
- Shared UI components: [SplitApp/Shared/Components](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Shared/Components)
- Feature screens: [SplitApp/Features](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Features)

## Доменные сущности

| Сущность | Где в frontend | Что означает |
| --- | --- | --- |
| User | [SplitApp/Domain/Models/User.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Domain/Models/User.swift) | Пользователь, известный backend. |
| Event | [SplitApp/Domain/Models/Event.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Domain/Models/Event.swift) | Пространство расходов с creator, participants и lifecycle state. |
| Receipt | [SplitApp/Domain/Models/Receipt.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Domain/Models/Receipt.swift) | Чек внутри события. |
| EventReceiptItem | [SplitApp/Domain/Models/EventReceiptItem.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Domain/Models/EventReceiptItem.swift) | Строка чека. |
| Share | [SplitApp/Domain/Models/Share.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Domain/Models/Share.swift) | Доля участника в позиции чека. |
| EventBalance | [SplitApp/Domain/Models/EventBalance.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Domain/Models/EventBalance.swift) | Долг debtor -> creditor. |
| Payment | [SplitApp/Domain/Models/Payment.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Domain/Models/Payment.swift) | Заявление о погашении долга. |

## Что важно помнить

- `main` должен отражать совместимый набор frontend и backend changes.
- Backend authorization всегда authoritative.
- Closed event должен блокировать financial mutations на UI-уровне и на backend.
- Receipt images нельзя считать permanent public URLs; для просмотра нужен presigned URL от backend.
- Money values нельзя бездумно переводить в binary floating point на границе API; DTO decode должен быть decimal-safe.

