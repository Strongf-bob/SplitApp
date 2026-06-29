# Авторизация и безопасность

## Общая схема

1. Пользователь проходит Yandex OAuth в iOS-приложении.
2. iOS получает Yandex token через Yandex Login SDK.
3. Frontend отправляет token на backend endpoint `POST /api/login`.
4. Backend возвращает app access token и refresh token.
5. Access token используется в `Authorization: Bearer <access_token>`.
6. Refresh token хранится в Keychain и используется для `POST /api/refresh`.

Связанные файлы:

- App bootstrap: [SplitAppApp.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/App/SplitAppApp.swift)
- Auth ViewModel: [AuthViewModel.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Features/Authorization/ViewModels/AuthViewModel.swift)
- Backend auth service: [AuthServiceBackend.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Auth/AuthServiceBackend.swift)
- Token state: [TokenStore.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Auth/TokenStore.swift)
- Secure storage: [KeychainStorage.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Auth/KeychainStorage.swift)
- Yandex provider: [YandexAuthProviderImpl.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Auth/Provider/YandexAuthProviderImpl.swift)

## Token storage

- Access token живет в runtime state через `TokenStore`.
- Refresh token хранится в Keychain.
- При неуспешном bootstrap refresh token удаляется, `TokenStore` очищается, пользователь возвращается на login screen.
- Refresh token нельзя переносить в UserDefaults, логи, analytics или crash reports.

## Поведение APIClient

[APIClient.swift](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Core/Network/APIClient.swift):

- добавляет Bearer token для protected endpoints;
- перед запросом может обновить access token, если он отсутствует или истек;
- на `401` делает один refresh и повторяет исходный request;
- не должен бесконечно retry-ить unauthorized requests;
- public endpoints: `POST /api/login`, `POST /api/refresh`.

## Authorization rules

Frontend может скрывать недоступные actions для UX, но backend остается источником правды:

- event membership проверяется backend-ом;
- creator-only действия проверяются backend-ом;
- closed event financial mutations блокируются backend-ом;
- payment confirmation restricted to receiver на backend-стороне;
- client-supplied user IDs не дают прав сами по себе.

Backend security reference:

- [Backend Authentication And Security Wiki](https://github.com/Strongf-bob/SplitAppBackend/blob/main/docs/wiki/Authentication-And-Security.md)
- [Backend security baseline](https://github.com/Strongf-bob/SplitAppBackend/blob/main/docs/security-baseline.md)

## Client-side правила

- Не логировать access token, refresh token, Yandex token и персональные данные.
- Не хранить секреты в репозитории.
- Не доверять local cache при принятии security decisions.
- При `403` показывать ошибку доступа, а не делать refresh/retry.
- При `401` сделать один refresh и один retry.
- При logout очищать token state и локальный current-user state.

