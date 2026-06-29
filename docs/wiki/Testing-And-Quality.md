# Тесты и проверки

## Что запускать перед merge

Минимальный набор:

- открыть проект в Xcode;
- собрать scheme `SplitApp`;
- запустить unit tests, если доступны в текущей Xcode-конфигурации;
- вручную проверить login/bootstrap, events list, receipt flow и friends/debts после backend-facing изменений.

## Текущие tests

В репозитории есть [SplitAppTests/EmojiLogicTests.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitAppTests/EmojiLogicTests.swift).

При расширении тестового покрытия приоритеты такие:

- DTO decoding для backend responses;
- mappers DTO -> domain;
- ViewModel behavior для events, receipts, friends и payments;
- error mapping;
- auth bootstrap/logout behavior;
- money parsing edge cases.

## Backend compatibility checks

Для изменений API нужно свериться с backend:

- [openapi.yaml](https://github.com/Strongf-bob/SplitAppBackend/blob/main/openapi.yaml)
- [Backend API Reference](https://github.com/Strongf-bob/SplitAppBackend/blob/main/docs/wiki/API-Reference.md)
- [Backend tests and CI](https://github.com/Strongf-bob/SplitAppBackend/blob/main/docs/wiki/Testing-And-CI.md)

## Рискованные зоны

- Auth refresh/retry loop.
- `403` vs `401` handling.
- Closed event read-only state.
- Creator-only event management.
- Payment confirmation permissions.
- Receipt image upload and presigned URL viewing.
- Money rounding and string/number decode differences.
- Core Data updates from background context.

## Definition of Done для backend-facing frontend changes

- Endpoint path/method совпадает с backend OpenAPI.
- Request DTO и response DTO покрывают реальные поля backend.
- Mapper не теряет обязательные поля.
- User-facing errors понятны и не раскрывают внутренние детали.
- UI не показывает actions, которые backend гарантированно отклонит.
- Wiki и `FRONTEND_BACKEND_TODO.md` обновлены, если изменился контракт или workflow.

