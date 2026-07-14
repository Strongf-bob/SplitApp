# Тесты и качество

Проверки должны подтверждать не только сборку, но и совместимость с backend и безопасность пользовательского сценария. Тесты находятся в [`SplitAppTests`](https://github.com/Strongf-bob/SplitApp/tree/main/SplitAppTests); исходная точка CI — проект Xcode.

## Перед merge или релизом

| Проверка | Что даёт |
| --- | --- |
| `Cmd+U` в Xcode или `xcodebuild test` для scheme | unit tests приложения |
| Сборка `SplitApp` на целевом simulator | компиляция и ресурсная целостность |
| Ручной auth smoke | login → restart → logout |
| Ручной receipt smoke | создать чек, проверить ошибку image upload и повторный вход в экран |
| Сверка с OpenAPI | endpoint/method/request/response совпадают с [контрактом](https://github.com/Strongf-bob/SplitAppBackend/blob/main/openapi.yaml) |
| `git diff --check` | нет whitespace-ошибок в документации и коде |

## Набор критичных тестов

| Риск | Тесты | Что защищают |
| --- | --- | --- |
| Сессия | [BootstrapAuthUseCaseTests](https://github.com/Strongf-bob/SplitApp/blob/main/SplitAppTests/BootstrapAuthUseCaseTests.swift), [LogoutUseCaseTests](https://github.com/Strongf-bob/SplitApp/blob/main/SplitAppTests/LogoutUseCaseTests.swift) | refresh и очистку после ошибки |
| Конфигурация | [APIConfigurationTests](https://github.com/Strongf-bob/SplitApp/blob/main/SplitAppTests/APIConfigurationTests.swift), [YandexOAuthConfigurationTests](https://github.com/Strongf-bob/SplitApp/blob/main/SplitAppTests/YandexOAuthConfigurationTests.swift) | корректные runtime settings |
| Чеки | [EventsHomeViewModelTests](https://github.com/Strongf-bob/SplitApp/blob/main/SplitAppTests/EventsHomeViewModelTests.swift) и [ReceiptsDataRepository](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Data/Repositories/ReceiptsRepository.swift) | загрузка событий и путь сохранения чека |
| Навигация | [EventsNavigationTests](https://github.com/Strongf-bob/SplitApp/blob/main/SplitAppTests/EventsNavigationTests.swift), [BottomTabPresentationTests](https://github.com/Strongf-bob/SplitApp/blob/main/SplitAppTests/BottomTabPresentationTests.swift) | доступные маршруты и tab state |
| Контракт DTO | [EventDTOContractTests](https://github.com/Strongf-bob/SplitApp/blob/main/SplitAppTests/EventDTOContractTests.swift) | decode и mapping |

## Definition of Done для backend-facing изменения

- Endpoint struct, DTO и mapper соответствуют актуальному OpenAPI.
- Repository не маскирует `401`, `403`, validation и business errors как offline fallback.
- View показывает понятный результат: loaded, cached, empty или error.
- Если меняется интеграционный маршрут, обновлены эта Wiki и соответствующая backend Wiki страница.
- Никакие токены и signed URL не попадают в test output или release logs.

Дальше: [Интеграция с backend](Backend-Integration), [Релиз](Operations-And-Release).
