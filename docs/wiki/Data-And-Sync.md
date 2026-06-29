# Локальные данные и синхронизация

## Core Data

Локальное хранение завязано на [CoreDataStore.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Database/CoreDataStore.swift) и модель [SplitApp.xcdatamodeld](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/SplitApp.xcdatamodeld).

Core Data используется как cache для данных, которые приходят из backend:

- events;
- receipts;
- users;
- payments.

## Repositories

| Repository | Файл | Назначение |
| --- | --- | --- |
| Events | [EventsRepository.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Repositories/EventsRepository.swift) | События и event lifecycle. |
| Receipts | [ReceiptsRepository.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Repositories/ReceiptsRepository.swift) | Чеки, позиции, изображения. |
| Users | [UsersRepository.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Repositories/UsersRepository.swift) | Пользователи, видимые текущему actor. |
| Friends | [FriendsDataRepository.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Repositories/FriendsDataRepository.swift) | Friend-facing представление поверх backend users/balances. |
| Balances | [BalancesDataRepository.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Repositories/BalancesDataRepository.swift) | Backend-calculated debts. |
| Payments | [PaymentsRepository.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Repositories/PaymentsRepository.swift) | Payment declarations and confirmation state. |
| Active event | [ActiveEventSelectionDataRepository.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Repositories/ActiveEventSelectionDataRepository.swift) | Выбранное активное событие. |

## DTO и mapping

DTO отражают backend JSON shape и находятся в [SplitApp/Data/DTOs](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Data/DTOs). Domain models находятся в [SplitApp/Domain/Models](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Domain/Models).

Mapping DTO -> domain вынесен в [SplitApp/Data/Mappers](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Data/Mappers). Это позволяет не протаскивать backend-specific поля прямо в UI.

## Money values

Backend должен отдавать денежные значения в decimal-safe формате. Frontend DTO decode поддерживает числа и decimal strings через [LosslessDoubleDecoding.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Shared/Decoding/LosslessDoubleDecoding.swift).

Текущий технический долг: часть domain/UI моделей все еще использует `Double`. Более надежный вариант - перейти на `Decimal` или minor-unit `Int` end to end. Этот пункт зафиксирован в [FRONTEND_BACKEND_TODO.md](https://github.com/Strongf-bob/SplitApp/blob/main/FRONTEND_BACKEND_TODO.md).

## Receipt images

Правило: сохраненный `image_url` не должен считаться permanent public URL. Для просмотра private images frontend должен получать временный URL через backend:

- endpoint: `GET /api/receipts/{id}/image/presigned-url`;
- frontend endpoint: `ReceiptImagePresignedURLEndpoint`;
- backend reference: [API Reference / Receipts](https://github.com/Strongf-bob/SplitAppBackend/blob/main/docs/wiki/API-Reference.md#receipts).

## Offline и cache expectations

- Local cache может улучшать UX, но не заменяет backend.
- При сетевых ошибках UI должен показывать понятные сообщения.
- При восстановлении сети repository/view model layer должен подтягивать свежие данные.
- Если local cache конфликтует с backend, backend побеждает.

