# Онбординг

## Первые 30 минут разработчика

| Время | Действие | Результат |
| --- | --- | --- |
| 0–5 мин | Прочитать [Обзор продукта](Project-Overview) и [Доменные сценарии](Domain-Flows) | понимаете, что считает backend и что показывает iOS |
| 5–10 мин | Открыть проект и запустить приложение по [Local Setup](Local-Setup) | есть рабочий simulator |
| 10–15 мин | Прочитать [SplitAppApp](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/App/SplitAppApp.swift) и [AppDependencies](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/App/AppDependencies.swift) | понятны старт и DI |
| 15–20 мин | Пройти [EventsNavigationView](https://github.com/Strongf-bob/SplitApp/blob/main/SplitApp/Features/Navigation/Views/EventsNavigationView.swift) → `BillViewModel` → `ReceiptsDataRepository` | понятен один вертикальный сценарий |
| 20–30 мин | Сверить `ReceiptEndpoints` с [OpenAPI](https://github.com/Strongf-bob/SplitAppBackend/blob/main/openapi.yaml) и запустить tests | понимаете границу frontend/backend |

## Как изменить одну фичу безопасно

1. Опишите пользовательское действие и выясните, существует ли backend capability.
2. Если контракт меняется — сначала согласуйте backend route/schema/OpenAPI.
3. В iOS добавьте endpoint, DTO, mapper и repository contract, затем пробросьте dependency в view model.
4. Добавьте тест на ошибку, success path или mapping — в зависимости от изменения.
5. Обновите связанные Wiki-страницы в обоих репозиториях.

## Словарь

| Термин | Значение |
| --- | --- |
| Событие | Контейнер общей поездки, ужина или другого набора расходов |
| Чек | Расход с плательщиком, позициями и долями участников |
| Доля | Часть позиции чека, назначенная участнику |
| Баланс | Расчёт того, кто кому должен в событии |
| Repository | граница, через которую feature получает данные, не зная HTTP/DTO |
| DTO | форма данных API до преобразования в domain model |
| Idempotency key | ключ, защищающий создание от повторной отправки |
| Draft Сплитика | предложение действия, которое пользователь должен подтвердить |

Дальше: [Архитектура iOS](iOS-Architecture) и [Поддержка Wiki](Wiki-Maintenance).
