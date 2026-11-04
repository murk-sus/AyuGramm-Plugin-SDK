# VoidGram Plugin SDK

Всё для разработчиков плагинов [VoidGram для iOS](https://github.com/neosay-dev/VoidGram):
полный справочник API, документация, примеры, SDK для семи языков, инструменты и исходники всех
плагинов из [каталога](https://github.com/murk-sus/VoidGram-plugins).

**Начать: [API.md](API.md)** — каждый вызов `ayu.*` с описанием, разрешения, события, лимиты.

## Что где

| Папка | Что внутри |
|---|---|
| [`API.md`](API.md) | Полный справочник API (27.6) и всё для разработчиков |
| [`docs/`](docs) | Документация: код-плагины, JSON-плагины, конвертер, Python-рантайм, каталог, облачные сборки |
| [`examples/`](examples) | Примеры на JavaScript, Python, Lua и Rust |
| [`examples/code-plugins/`](examples/code-plugins) | Бывшие встроенные функции, теперь плагины: статистика чата, «Год в обзоре», стикер из фото, описание фото, скачать все медиа, закладки |
| [`template/`](template) | Заготовка JS-плагина |
| [`sdk/`](sdk) | SDK и типы: TypeScript, Python, Lua, Rust, Zig, Go (TinyGo), AssemblyScript |
| [`plugins/`](plugins) | Исходники всех плагинов каталога: в папке каждого файл, README и скриншот |
| [`plugins/json/`](plugins/json) | Декларативные `.plugin` (JSON), схема и примеры конвертации плагинов с Android |
| [`plugins/native-cards/`](plugins/native-cards) | Карточки `.iosplug` нативных плагинов |
| [`plugins-src/`](plugins-src) | Исходники плагинов, которые собираются (Rust → WebAssembly) |
| [`tools/`](tools) | `ayu-cli`, mock-runner, конвертер и анализатор плагинов, инструменты каталога |
| [`prelude/`](prelude) | JS-прелюдия, которую приложение запускает перед каждым плагином (для mock-runner) |
| [`converter-runtime/`](converter-runtime) | Python-рантайм конвертера плагинов exteraGram / Android |

## Быстрый старт

Плагин — один файл. Установка: VoidGram → Плагины → **+**, или нажмите на файл в чате.
Подходит любое написание расширения: `.ayujs` / `.ayu.js`, `.ayupy` / `.ayu.py`, `.ayulua` / `.ayu.lua`, `.ayuwasm` / `.ayu.wasm`.
Имена `ayu.*` и `==AyuPlugin==` остались прежними, см. конец [API.md](API.md).

**JavaScript** (`.ayujs` / `.ayu.js`):
```js
// ==AyuPlugin==
// @id shout
// @name Shout
// @author @your_nick
// @version 1.0
// @description Adds "!" to outgoing messages.
// ==/AyuPlugin==
ayu.hooks.before(ayu.hooks.points.outgoingText, (text) => text + '!');
```

**Python** (`.ayupy` / `.ayu.py`) — см. [`examples/python`](examples/python).
**Lua** (`.ayulua` / `.ayu.lua`) — см. [`examples/lua`](examples/lua).
**Rust** (`.wasm`) — см. [`examples/rust`](examples/rust) и [`sdk/rust`](sdk/rust):
`cargo build --release --target wasm32-unknown-unknown`.
**TypeScript** — подключите [`sdk/typescript/ayu.d.ts`](sdk/typescript/ayu.d.ts) и соберите в JS.

## Проверка без телефона

```sh
# JS-плагин на настоящей прелюдии приложения: отправить текст, вызвать событие, открыть ссылку
node tools/mock-runner/cli.ts --prelude prelude/prelude.swift examples/smart-quotes.ayu.js --send 'он сказал "привет"'

# Проверка заголовка, разрешений и размера; горячая перезагрузка на телефоне
cd tools/ayu-cli && go build -o ayu . && ./ayu check ../../examples/smart-quotes.ayu.js
./ayu dev my-plugin.ayu.js            # горячая перезагрузка по WebSocket при каждом сохранении

# Тесты API на прелюдии
cd tools/mock-runner && PRELUDE=../../prelude/prelude.swift node --test prelude.test.ts fuzz.test.ts api276.test.ts

# Та же проверка, что в CI каталога
node tools/catalog/test_plugins.js my-plugin.ayu.js
```

## Публикация в каталог

- Pull request в [murk-sus/VoidGram-plugins](https://github.com/murk-sus/VoidGram-plugins): `plugins/<id>/plugin.ayu.js` (или `.ayu.py`, `.ayu.lua`, `.wasm`, `.iosplug`).
- Или через команду VoidGram: бот проверит файл, запишет автора, описание и скриншот, а каталог и README соберутся сами.
- Плагины с `@inject` в каталоге подписываются ключом VoidGram (Ed25519) и отмечаются «✓ официальный».

Подробности: [`docs/CODE_PLUGINS.md`](docs/CODE_PLUGINS.md), [`docs/catalog/`](docs/catalog).

## Документация

- [API.md](API.md) — полный справочник API.
- [docs/CODE_PLUGINS.md](docs/CODE_PLUGINS.md) — код-плагины: изоляция, заголовок, хуки, безопасная зона, Python и Rust.
- [docs/PLUGINS.md](docs/PLUGINS.md) — декларативные `.plugin` (JSON) и их схема.
- [docs/PLUGIN_CONVERSION.md](docs/PLUGIN_CONVERSION.md), [docs/AST_CONVERTER.md](docs/AST_CONVERTER.md) — автоматическая конвертация плагинов с Android.
- [docs/ANDROID_PLUGIN_BRIDGES.md](docs/ANDROID_PLUGIN_BRIDGES.md) — нативные адаптеры для плагинов Android.
- [docs/PYTHON_RUNTIME.md](docs/PYTHON_RUNTIME.md), [docs/PYTHON_RUNTIME_COMPAT.md](docs/PYTHON_RUNTIME_COMPAT.md) — Python-рантайм и совместимость с exteraGram.
- [docs/IOSPLUG_BATCH.md](docs/IOSPLUG_BATCH.md), [docs/PLUGIN_BATCH_STATUS_RU.md](docs/PLUGIN_BATCH_STATUS_RU.md) — карточки `.iosplug`.
- [docs/PLUGIN_ENGINE8_RU.md](docs/PLUGIN_ENGINE8_RU.md), [docs/PLUGIN_ENGINE9_RU.md](docs/PLUGIN_ENGINE9_RU.md) — история движка плагинов.
- [docs/PLUGIN_CATALOG_OTA.md](docs/PLUGIN_CATALOG_OTA.md) — каталог с обновлениями по воздуху.
- [docs/catalog/](docs/catalog) — README каталога и облачные сборки для разработчиков.

Документы в `docs/` перенесены из репозиториев приложения и каталога. Где они расходятся с
[API.md](API.md), верен API.md: он собран по коду версии 27.6.
