# Поддержка Wiki

## Единственный источник

Версионируемый источник — [`docs/wiki/`](https://github.com/Strongf-bob/SplitApp/tree/main/docs/wiki). GitHub Wiki — опубликованное зеркало: [SplitApp Wiki](https://github.com/Strongf-bob/SplitApp/wiki). Не редактируйте опубликованную Wiki так, чтобы эти две версии расходились.

## Когда обновлять

Wiki обновляется в том же изменении, если меняется:

- пользовательский сценарий, экран или доступное действие;
- endpoint, DTO, mapper, repository или auth flow;
- local-cache/offline поведение;
- base URL, OAuth настройка, тестовый или release workflow;
- backend capability, на которую ссылается iOS.

## Правила написания

- Пишите по-русски; команды, identifiers и имена API оставляйте как в коде.
- Ссылайтесь на конкретные файлы iOS и на [backend OpenAPI](https://github.com/Strongf-bob/SplitAppBackend/blob/main/openapi.yaml).
- Разделяйте «реализовано в iOS» и «есть в backend-контракте».
- Используйте Wiki-ссылки без расширения: `[Архитектура](iOS-Architecture)`.
- Не добавляйте YAML frontmatter: GitHub Wiki показывает его как обычный текст.

## Публикация

1. Проверьте локальные Markdown-ссылки и Mermaid-блоки.
2. Скопируйте только `docs/wiki/*.md` в чистый clone `https://github.com/Strongf-bob/SplitApp.wiki.git`.
3. Проверьте `git diff`, создайте осмысленный commit в Wiki-репозитории и push в `master`/default branch Wiki.
4. Откройте [Home](https://github.com/Strongf-bob/SplitApp/wiki/Home) и несколько связанных страниц в браузере.

При публикации не переносите `README.md`, планы `docs/superpowers` и локальные инструменты: Wiki должна состоять только из читательских страниц.
