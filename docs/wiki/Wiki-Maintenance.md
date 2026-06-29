# Поддержка Wiki

## Где лежит Wiki

Frontend Wiki source хранится в [docs/wiki](https://github.com/Strongf-bob/SplitApp/tree/main/docs/wiki).

Backend Wiki source хранится в [SplitAppBackend/docs/wiki](https://github.com/Strongf-bob/SplitAppBackend/tree/main/docs/wiki).

## Когда обновлять

Обновляйте Wiki в том же изменении, если меняется:

- API endpoint, request или response;
- auth flow;
- token storage;
- Core Data model или repository behavior;
- event/receipt/payment business flow;
- local setup;
- testing or CI workflow;
- ссылка на важный GitHub-файл или внешний контракт.

## Как писать

- Писать по-русски.
- Ссылаться на GitHub-файлы через постоянные repository URLs.
- Не дублировать весь backend OpenAPI; ссылаться на [openapi.yaml](https://github.com/Strongf-bob/SplitAppBackend/blob/main/openapi.yaml).
- Для frontend/backend связки давать ссылки на оба репозитория.
- Если есть технический долг, ссылаться на [FRONTEND_BACKEND_TODO.md](https://github.com/Strongf-bob/SplitApp/blob/main/FRONTEND_BACKEND_TODO.md), а не прятать проблему в тексте.

## Синхронизация с GitHub Wiki

Эти Markdown-файлы можно вручную или скриптом зеркалировать в GitHub Wiki. Для GitHub Wiki обычно нужны имена страниц без `.md` в ссылках, например `Project-Overview`, а для repository source удобнее использовать обычные относительные ссылки `Project-Overview.md`.

Если включена отдельная GitHub Wiki repository, source pages должны оставаться в `docs/wiki`, чтобы изменения проходили code review и не терялись при force-push или ручном редактировании Wiki.

