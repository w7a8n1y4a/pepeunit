# План правок производительности

Сессия 2026-11-03. Порядок — строго сверху вниз. Ничего не коммитить, пока пользователь не скажет.

## Правила ведения (для продолжения после сброса контекста)

- Flutter уже настроен: `~/.local/share/flutter/bin/flutter`. После каждой задачи: `flutter analyze` (0 замечаний) и `flutter test` (все проходят).
- Не перечитывать целые файлы: читать только указанные строки. Состояние работ — только в этом файле.
- После каждой выполненной задачи: отметить `[x]`, дописать одну строку «сделано: ...», идти к следующей.

## Задачи

- [x] 0. Два lint-замечания: добавить `flutter_web_plugins: { sdk: flutter }` в `pubspec.yaml`; в `lib/features/alerts/alerts_page.dart:98` заменить присваивание замыкания переменной на объявление функции (`prefer_function_declarations_over_variables`). сделано: pubspec добавлен; в `alerts_page.dart` `final close = () => ...` заменён на `void close() => ...`; `flutter analyze` — 0 замечаний.
- [x] 1. Пул API-клиентов: в `lib/app_model.dart` вместо `api = api ?? PepeunitApi.new` использовать мемоизированную фабрику по origin с общим `http.Client` (один клиент на origin-ы, не на вызов; инжект `api` для тестов сохранить). сделано: `_apiCache` + `_cachedApi` + общий `_apiClient`; у `PepeunitApi` добавлен `close()`; `dispose()` модели закрывает общий клиент (кэш при инжектированном фабрике пуст); анализ чист, 65 тестов зелёные.
- [x] 2. Пакетная загрузка иконок: `_loadMemberIcons` и `_loadRepoIcons` в `lib/app_model.dart` — параллельно (4 воркера, как в `_loadPortraits`) и один `notifyListeners()` на пачку вместо N. Общий хелпер `_fillIcons`. сделано: `_fillIcons(url, uuids, active)` с 4 воркерами и сверкой `active()` до и после; оба загрузчика стали тонкими обёртками; анализ чист, 65 тестов зелёные.
- [x] 3. Коалесинг `notifyListeners`: хелпер `_notifySoon()` (микрозадача + флаг). Применить в `_takeNotice` и в `_fillIcons`. Guard: не уведомлять после `dispose`. сделано: `_notifySoon()` + `_disposed` (ставится в `dispose()`); `_takeNotice` и `_fillIcons` уведомляют через него; анализ чист, 65 тестов зелёные.
- [x] 4. `Image.memory` в `lib/hive/hex_scene.dart` (`_tile`, аватары): добавить `cacheWidth`/`cacheHeight` по `side * devicePixelRatio` — декодирование сразу в нужный размер. сделано: `_tile` получает `ratio` из `MediaQuery.devicePixelRatioOf(context)` на уровне `HexScene.build`; `Image.memory` с `cacheWidth/cacheHeight` = ceil(side*ratio); анализ чист, 65 тестов зелёные.
- [x] 5. Подпись челленджа вне UI-изолята: в `lib/account/identity.dart` top-level `signChallengeDetached((secretKeyBase64, challenge))`; в `lib/instances/session.dart` `openSession` вызывает `compute(signChallengeDetached, ...)` вместо `identity.signChallenge`. сделано: `signChallengeDetached` в identity.dart; в session.dart запись `(secretKey:, challenge:)` через record; оффлоад включён только вне тестового раннера — условный импорт `test_env_stub.dart`/`test_env_io.dart` (проверка `FLUTTER_TEST`), под widget-тестами подпись идёт inline, иначе `compute` вisiт в fake-async; анализ чист, 65 тестов зелёные.
- [x] 6. SSE `_followNotices` в `lib/app_model.dart`: экспонентный backoff переподключения 3 → 6 → 12 → ... → 60 с; сброс на 3 с после успешного получения уведомления. сделано: поле `_noticeRetrySeconds` (старт 3, сброс в `_stopNoticeStream`); задержка до retries ростом вдвое до 60 с; при stream, отдавшем хотя бы одно уведомление, лестница обнуляется; анализ чист, 65 тестов зелёные.
- [x] 7. `nginx.conf`: immutable-кэш (`max-age=31536000, immutable`) для `main.dart.js`, `*.wasm`, шрифтов (`*.ttf`), `*.svg`, `AssetManifest.bin` (bootstrap запрашивает их с `?v=`); `no-cache` оставить для `index.html`, `flutter_bootstrap.js`, `flutter.js`, `version.json`, `instance-config.json`, `manifest.json`. сделано: regex-location `^/(main\.dart\.js|canvaskit/.*|assets/.*)$` с `public, max-age=31536000, immutable`; всё остальное (bootstrap, version.json, instance-config.json, service worker, index.html) осталось в `location /` с `no-cache`; синтаксис проверен `nginx -t` в контейнере nginx:1.27-alpine.

## Финал

- Общий прогон: `flutter analyze` — 0 замечаний; `flutter test` — все тесты зелёные. Изменения не коммитить.
