# SplitApp iOS Wiki

Это Wiki frontend-репозитория SplitApp. Она объясняет, как устроено iOS-приложение, как оно связано с backend, где искать ключевые файлы и какие правила соблюдать при разработке.

## Быстрые ссылки

- [Обзор проекта](Project-Overview.md) - назначение приложения, основные сценарии и репозитории.
- [Локальный запуск](Local-Setup.md) - как открыть и запустить iOS-проект.
- [Архитектура iOS-приложения](iOS-Architecture.md) - слои, зависимости, feature-модули и shared-компоненты.
- [Интеграция с backend API](Backend-Integration.md) - endpoints, DTO, repositories и связь с backend OpenAPI.
- [Авторизация и безопасность](Authentication-And-Security.md) - Yandex OAuth, access/refresh tokens, Keychain и правила клиента.
- [Локальные данные и синхронизация](Data-And-Sync.md) - Core Data, offline/cache behavior, active event и money decoding.
- [Тесты и проверки](Testing-And-Quality.md) - какие проверки запускать перед merge.
- [Поддержка Wiki](Wiki-Maintenance.md) - как обновлять документацию вместе с кодом.

## Репозитории

- iOS frontend: [Strongf-bob/SplitApp](https://github.com/Strongf-bob/SplitApp)
- Backend: [Strongf-bob/SplitAppBackend](https://github.com/Strongf-bob/SplitAppBackend)
- Backend Wiki: [SplitAppBackend/docs/wiki](https://github.com/Strongf-bob/SplitAppBackend/tree/main/docs/wiki)
- Backend OpenAPI contract: [openapi.yaml](https://github.com/Strongf-bob/SplitAppBackend/blob/main/openapi.yaml)
- Frontend/backend backlog: [FRONTEND_BACKEND_TODO.md](https://github.com/Strongf-bob/SplitApp/blob/main/FRONTEND_BACKEND_TODO.md)

## Главный принцип

Backend - источник правды для пользователей, membership, прав на операции, балансов, платежей и состояния события. iOS-клиент отвечает за интерфейс, локальный cache, user-facing errors и корректное использование backend-контракта, но не должен заменять backend authorization локальными проверками.

## Что покрывает frontend

- Yandex OAuth login и bootstrap пользовательской сессии.
- Bottom tab navigation: события, друзья, профиль и связанные экраны.
- Создание, просмотр, редактирование и удаление событий и чеков.
- Работа с участниками, долями в чеке, балансами и платежами.
- Загрузка и просмотр изображений чеков через backend.
- Локальное сохранение данных через Core Data.
- Нормализация сетевых ошибок в понятные сообщения для пользователя.

