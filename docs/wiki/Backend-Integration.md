# Интеграция с backend API

## Источник правды

Главный backend-контракт: [SplitAppBackend/openapi.yaml](https://github.com/Strongf-bob/SplitAppBackend/blob/main/openapi.yaml).

Человекочитаемая backend Wiki:

- [API Reference](https://github.com/Strongf-bob/SplitAppBackend/blob/main/docs/wiki/API-Reference.md)
- [iOS Frontend Integration](https://github.com/Strongf-bob/SplitAppBackend/blob/main/docs/wiki/iOS-Frontend-Integration.md)
- [Domain Flows](https://github.com/Strongf-bob/SplitAppBackend/blob/main/docs/wiki/Domain-Flows.md)

## Network layer во frontend

- Client: [APIClient.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Network/APIClient.swift)
- Endpoint protocol: [Endpoint.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Network/Endpoint.swift)
- Endpoint structs: [SplitApp/Data/Network/Endpoints](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Data/Network/Endpoints)
- DTO: [SplitApp/Data/DTOs](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Data/DTOs)
- Mappers: [SplitApp/Data/Mappers](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Data/Mappers)
- Repositories: [SplitApp/Data/Repositories](https://github.com/Strongf-bob/SplitApp/tree/main/SplitApp/Data/Repositories)

## Endpoint mapping

| Frontend endpoint | Backend path | Файл |
| --- | --- | --- |
| `AuthUserEndpoint` | `POST /api/login` | [UserEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/UserEndpoints.swift) |
| `RefreshTokenEndpoint` | `POST /api/refresh` | [UserEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/UserEndpoints.swift) |
| `ListUsersEndpoint` | `GET /api/users` | [UserEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/UserEndpoints.swift) |
| `CreateEventEndpoint` | `POST /api/events` | [EventEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/EventEndpoints.swift) |
| `ListEventsEndpoint` | `GET /api/events` | [EventEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/EventEndpoints.swift) |
| `GetEventEndpoint` | `GET /api/events/{id}` | [EventEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/EventEndpoints.swift) |
| `UpdateEventEndpoint` | `PATCH /api/events/{id}` | [EventEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/EventEndpoints.swift) |
| `DeleteEventEndpoint` | `DELETE /api/events/{id}` | [EventEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/EventEndpoints.swift) |
| `AddParticipantsEndpoint` | `POST /api/events/{id}/participants` | [EventEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/EventEndpoints.swift) |
| `RemoveParticipantEndpoint` | `DELETE /api/events/{id}/participants/{user_id}` | [EventEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/EventEndpoints.swift) |
| `CreateReceiptEndpoint` | `POST /api/events/{id}/receipts` | [ReceiptEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/ReceiptEndpoints.swift) |
| `ListReceiptsEndpoint` | `GET /api/events/{id}/receipts` | [ReceiptEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/ReceiptEndpoints.swift) |
| `UpdateReceiptEndpoint` | `PATCH /api/receipts/{id}` | [ReceiptEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/ReceiptEndpoints.swift) |
| `DeleteReceiptEndpoint` | `DELETE /api/receipts/{id}` | [ReceiptEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/ReceiptEndpoints.swift) |
| `UploadReceiptImageEndpoint` | `POST /api/receipts/{id}/image` | [ReceiptEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/ReceiptEndpoints.swift) |
| `ReceiptImagePresignedURLEndpoint` | `GET /api/receipts/{id}/image/presigned-url` | [ReceiptEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/ReceiptEndpoints.swift) |
| `GetBalancesEndpoint` | `GET /api/events/{id}/balances` | [BalanceEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/BalanceEndpoints.swift) |
| `CreatePaymentEndpoint` | `POST /api/events/{id}/payments` | [PaymentEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/PaymentEndpoints.swift) |
| `ListPaymentsEndpoint` | `GET /api/events/{id}/payments` | [PaymentEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/PaymentEndpoints.swift) |
| `UpdatePaymentEndpoint` | `PATCH /api/payments/{id}` | [PaymentEndpoints.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Network/Endpoints/PaymentEndpoints.swift) |

## Правила синхронизации frontend и backend

При любом изменении API в одном PR или в связанной серии PR нужно обновить:

- backend route/service/schema code в [SplitAppBackend](https://github.com/Strongf-bob/SplitAppBackend);
- [openapi.yaml](https://github.com/Strongf-bob/SplitAppBackend/blob/main/openapi.yaml);
- frontend endpoint struct;
- frontend DTO;
- mapper DTO -> domain;
- repository contract и implementation;
- user-facing error handling, если меняются status codes или error shape;
- эту Wiki и backend Wiki.

## Текущие follow-ups

Актуальный список frontend/backend gaps находится в [FRONTEND_BACKEND_TODO.md](https://github.com/Strongf-bob/SplitApp/blob/main/FRONTEND_BACKEND_TODO.md).

Самые важные направления:

- dedicated payment flow;
- event participants management screen;
- event rename UI;
- receipt photo upload/delete UX;
- friends/search/invites product contract;
- profile financial stats после backend metric contract;
- уход от `Double` для money domain/UI models;
- pagination после backend pagination contract.

