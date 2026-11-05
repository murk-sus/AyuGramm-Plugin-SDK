# VoidGram для iOS — полный справочник API плагинов (27.6)

Всё, что плагин может вызвать, и всё, что есть для разработчиков. Справочник собран по коду
приложения 27.6: JS-прелюдии, операциям хоста, SDK и инструментам. На устройстве вызовы по одному
не проверялись: если поведение расходится с описанием, напишите нам.

Обозначения:
- `[разрешение]` — вызов работает, только если в заголовке плагина есть `@permissions разрешение`.
- `[официальный]` — только для доверенных плагинов: с подписью VoidGram или инжект-плагинов, которые пользователь сам разрешил.
- Удаление и очистка своего (`remove`, `clear`, `reset`, `hide`, `unsubscribe`) разрешения не требуют, кроме отмеченных.
- `[инжект]` — нужен `@inject true`, работает только у доверенного плагина (см. «Безопасная зона»).
- «→ Promise» — вызов асинхронный и возвращает Promise.

Плагины пишутся на JavaScript, Python, Lua и Rust (WebAssembly). Названия везде одинаковые;
в Python они записываются в snake_case (`scroll_to`, `add_button`), в Lua и Rust есть
универсальный вызов `call(op, args)` (раздел «Низкоуровневые операции»).

### `void` и старые плагины

API теперь называется `void`. В JavaScript `void` — зарезервированное слово, поэтому в JS-плагинах
пишите `voidgram.…` (или `globalThis.void.…`); в Python, Lua и Rust — `void.…`. `ayu.…` остался тем же
объектом, так что все плагины прежнего вида работают без изменений, и оба имени можно смешивать.

- Расширения: `.voidjs`, `.void.js`, `.voidpy`, `.void.py`, `.voidlua`, `.void.lua`, `.voidwasm`, `.void.wasm`
  рядом со старыми `.ayujs`/`.ayu.js` и обычными `.js`, `.py`, `.lua`, `.wasm`.
- Заголовок: `==VoidPlugin==` или `==AyuPlugin==`.
- Wasm: импорт `void.host` или `ayu.host`, экспорты `void_alloc`/`void_dispatch` или `ayu_alloc`/`ayu_dispatch`,
  секция `void.manifest` или `ayu.manifest`.
- Перевод файла: `python3 sdk/tools/convert_void.py plugin.ayu.js`.

Ниже сохранены имена `ayu.*`, чтобы существующие описания и примеры оставались верными. Замените
`ayu` на `voidgram` в JS или на `void` в Python/Lua/Rust, чтобы получить новый вид.

---

## 1. Основное

- `ayu.pluginId` — id текущего плагина.
- `ayu.log(...)` — пишет строку в консоль плагинов (уровень info).
- `ayu.warn(...)` — пишет предупреждение в консоль.
- `ayu.error(...)` — пишет ошибку в консоль.
- `ayu.toast(text)` — короткое всплывающее сообщение внизу экрана.
- `ayu.on(event, fn)` — подписка на событие приложения (полный список в разделе 22).
- `console.log / info / debug / warn / error` — то же, что `ayu.log/warn/error`.
- `print(...)` — то же, что `ayu.log`.
- `setTimeout(fn, ms)` — разовый таймер в очереди плагина.
- `setInterval(fn, ms)` — повторяющийся таймер (не чаще раза в 100 мс).
- `clearTimeout(id)` / `clearInterval(id)` — отменяют таймер.
- `ayu.events.off(event, fn)` — снимает подписку, сделанную через `ayu.on(event, fn)`; без `fn` снимает все подписки на событие.
- `ayu.sdk.capabilities()` — список методов, которые реально отвечают в этой сборке.
- `ayu.plugin.resources()` — `{ id, thermalState, lowPowerMode, uptime, storageLimit }` текущего плагина.
- `ayu.debug.inspect()` — то же для отладки: состояние, нагрев, режим энергосбережения.

## 2. Хуки (перехват и замена поведения)

- `ayu.hooks.before(point, fn)` — `fn(text, ctx)` выполняется до встроенного обработчика. Возвращает новый текст или ничего, чтобы оставить как есть.
- `ayu.hooks.after(point, fn)` — то же, но после встроенного обработчика.
- `ayu.hooks.replace(point, fn)` — полностью заменяет встроенный обработчик. Заменить точку может только один плагин, остальные становятся `after`.
- `ayu.hooks.points.outgoingText` = `message.outgoing.text` — текст исходящего сообщения перед отправкой (облачные чаты, без медиа; секретные чаты не затрагиваются).
- `ayu.hooks.points.lyricsText` = `lyrics.text` — текст песни перед показом, построчно `[инжект]`. Пустая строка убирает строку, тайминги сохраняются.
- `ayu.hooks.points.linkOpen` = `link.open` — переписать ссылку прямо перед открытием `[links]`.
- `ayu.hooks.points.messageRender` = `message.render` — изменить, как текст сообщения показывается в чате; сохранённые данные не меняются.
- `ayu.hooks.points.notificationBeforeShow` = `notification.beforeShow` — изменить текст локального уведомления VoidGram, пустая строка его отменяет `[notifications]`.
- `ctx` — контекст хука: `{ peerId, messageId?, isSecret }`.

## 3. Отключение встроенных функций

- `ayu.features.disable(name)` — выключает функцию приложения, пока плагин работает.
- `ayu.features.enable(name)` — возвращает её.

Имена функций:
- `fastShare` — кнопка быстрой пересылки у сообщений.
- `messageShot` — снимок сообщения (MessageShot).
- `reactionPicker` — панель реакций в меню сообщения.
- `readSummary` — сводка «кто прочитал».
- `editedInfo` — сведения об изменении.
- `messageDetails` — «Подробности сообщения».
- `stories` — истории.
- `similarChannels` — похожие каналы.
- `premiumStatuses` — Premium-статусы у имён.
- `unreadCounters` — счётчики непрочитанного.
- `greetingSticker` — приветственный стикер в пустом чате.
- `openLinkWarning` — предупреждение перед открытием ссылки.
- `doubleTapToEdit` — редактирование двойным нажатием.
- `formattingToolbar` — панель форматирования.
- `keyboardHideOnScroll` — скрытие клавиатуры при прокрутке.

Переопределения не записываются в настройки пользователя и исчезают, когда плагин останавливается.

## 4. Настройки и хранилище

- `ayu.settings.declare(items)` — описывает страницу настроек плагина; приложение рисует её само.
- Типы настроек:
  - `toggle` — переключатель;
  - `text` — поле ввода;
  - `slider` — ползунок (`min`, `max`, `step`);
  - `color` — цвет `#RRGGBB`;
  - `select` — выбор из `options: [{ value, title }]`;
  - `preview` — текст только для чтения.
- `ayu.settings.get(key)` — текущее значение настройки (для переключателей `"1"` или `"0"`).
- `ayu.storage.get(key)` — читает строку из хранилища плагина.
- `ayu.storage.set(key, value)` — пишет строку; `null` удаляет. Всего до 64 КБ на плагин.
- `ayu.storage.remove(key)` — удаляет значение.
- `ayu.storage.has(key)` — есть ли значение.
- `ayu.storage.getJSON(key, fallback)` — читает значение как JSON; если его нет, возвращает `fallback`.
- `ayu.storage.setJSON(key, value)` — сохраняет значение как JSON.
- `ayu.storage.increment(key, by)` — увеличивает число на `by` (по умолчанию 1) и возвращает результат.
- `ayu.storage.transaction(values)` — записывает несколько ключей за один вызов: `{ key: 'value' }`, `null` удаляет.
- `ayu.secrets.get(key)` — читает секрет из Keychain `[secrets]`.
- `ayu.secrets.set(key, value)` — сохраняет секрет в Keychain, `null` удаляет `[secrets]`.

## 5. Окна и меню (`ayu.ui`)

- `ayu.ui.alert({ title, message, buttons: [{ id, title, style }] }, fn)` — диалог; `fn(id нажатой кнопки)`. `style`: `default` или `destructive` `[ui]`.
- `ayu.ui.sheet({ title, message, items: [{ id, title }] }, fn)` — меню действий снизу; `fn(id или null)` `[ui]`.
- `ayu.ui.menu.add({ id, title, icon })` — пункт в меню сообщения (до 5 на плагин, `icon` — имя SF Symbol). Нажатие присылает событие `menuAction` `[menu]`.
- `ayu.ui.menu.remove(id)` — убирает пункт.
- `ayu.ui.profile.addBlock({ id, peerId?, title?, text })` — текстовый блок в профиле: у всех или только у `peerId` `[profile]`.
- `ayu.ui.profile.removeBlock(id)` — убирает блок.
- `ayu.ui.profile.addButton({ id, peerId?, title })` — кнопка в профиле; нажатие присылает `profileButton` `[profile]`.
- `ayu.ui.profile.removeButton(id)` — убирает кнопку.
- `ayu.ui.badge.add({ peerId, badge: { text } })` — бейдж рядом с именем чата в списке `[badges]`.
- `ayu.ui.badge.remove({ peerId })` — убирает бейдж.
- `ayu.ui.avatar.decorate(peerId, emoji)` — эмодзи в углу аватарки чата в списке `[badges]`.
- `ayu.ui.avatar.clear(peerId)` — убирает его `[badges]`.
- `ayu.ui.gifts.catalog.list(fn)` → Promise — каталог подарков Telegram (только чтение): `[{ giftId, title, stars, fileId, limited, remains, total, soldOut }]`.

## 6. Эффекты поверх приложения (`ayu.ui.overlay` и другие)

- `ayu.ui.overlay.create({ id, effect, amount, speed, color, fps })` — частицы поверх всего приложения. `effect`: `snow`, `leaves`, `rain`, `stars`, `confetti`; `amount` и `speed` — 0.1–3. Нажатия не перехватывает, на паузе при «Уменьшении движения» `[overlay]`.
- `ayu.ui.overlay.update(id, options)` — меняет эффект, количество, скорость, цвет или fps `[overlay]`.
- `ayu.ui.overlay.addText({ id, text, anchor, color, size })` — текст, закреплённый в углу или по центру: `topLeft`, `topRight`, `bottomLeft`, `bottomRight`, `center` `[overlay]`.
- `ayu.ui.overlay.addClock({ id, format, anchor, color, size })` — живые часы поверх приложения, например `"HH:mm:ss"` `[overlay]`.
- `ayu.ui.overlay.showFPS({ id, anchor, color, size })` — счётчик FPS `[overlay]`.
- `ayu.ui.overlay.remove(id)` — убирает эффект, текст, часы или FPS.
- `ayu.ui.animation.play(name, seconds)` — короткая анимация на весь экран: `confetti`, `snow`, `stars`, `leaves`, `rain` `[overlay]`.
- `ayu.ui.floatingButton.add({ id, icon, title, anchor, color }, onTap)` — плавающая кнопка поверх приложения; `onTap` вызывается по нажатию `[overlay]`.
- `ayu.ui.floatingButton.remove(id)` — убирает кнопку.
- `ayu.ui.progress.show({ id, title, value, anchor })` — индикатор прогресса поверх приложения, `value` — 0…1 `[overlay]`.
- `ayu.ui.progress.hide(id)` — скрывает индикатор `[overlay]`.
- `ayu.ui.chatBackground.set({ colors, alpha })` — цвет или градиент из двух цветов поверх обоев чата, под сообщениями `[overlay]`.
- `ayu.ui.chatBackground.reset()` — убирает его `[overlay]`.

## 7. Шрифты

- `ayu.ui.font.set({ element, size })` — размер текста `messages` (сообщения) или `lists` (списки), 12–30 pt `[fonts]`.
- `ayu.ui.font.set({ weight, style })` — насыщенность (`light`, `regular`, `medium`, `semibold`, `bold`) и стиль (`normal`, `rounded`, `monospaced`, `italic`) обычного текста во всём приложении `[fonts]`.
- `ayu.ui.font.reset(element)` — возвращает исходный шрифт.

## 8. Свои экраны, вкладки, боковая панель, поиск

- `ayu.screens.show({ id, title, sections })` — полноценная страница, которую рисует VoidGram. Секции: `{ title, footer, rows }`; виды строк: `text`, `button`, `toggle`, `link`, `value`. Нажатия приходят событием `screenAction` `[screens]`.
- `ayu.ui.tabs.add({ id, title, icon, screen })` — вкладка в нижней панели со страницей плагина (не больше двух вкладок от плагинов) `[screens]`.
- `ayu.ui.tabs.remove(id)` — убирает вкладку.
- `ayu.ui.sidebar.show(screen)` — панель со страницей плагина, выезжает слева `[screens]`.
- `ayu.ui.searchBar.show({ id, title, placeholder }, onQuery)` — экран поиска; каждый запрос приходит в `onQuery(query)` `[screens]`.
- `ayu.ui.searchBar.setResults(id, rows)` — показывает результаты `[{ id, title, subtitle }]`; нажатие присылает `searchResult` `[screens]`.

## 9. Чат

- `ayu.chat.scrollTo(messageId)` — прокручивает открытый чат к сообщению `[ui]`.
- `ayu.chat.draft.insert(text)` — дописывает текст в поле ввода открытого чата, не отправляя его `[composer]`.
- `ayu.chat.draft.clear()` — очищает поле ввода `[composer]`.
- `ayu.chat.toolbar.add({ id, title, icon }, onTap)` — кнопка в панели чата над клавиатурой; `onTap(peerId)` получает открытый чат `[ui]`.
- `ayu.chat.toolbar.remove(id)` — убирает кнопку.
- `ayu.chat.toolbar.filter({ words, authors })` — фильтр сообщений открытого чата по словам и авторам `[messages.read]`.
- `ayu.chat.filter.set({ words, authors })` — скрывает сообщения по словам и авторам во всех чатах `[messages.read]`.

## 10. Поле ввода и команды

- `ayu.composer.addButton({ id, title, icon })` — кнопка над клавиатурой; нажатие присылает `composerButton` `{ id, text, selection, selectionStart, selectionEnd }` `[composer]`.
- `ayu.composer.removeButton(id)` — убирает кнопку.
- `ayu.composer.setText(text)` — заменяет текст в поле ввода `[composer]`.
- `ayu.composer.replaceSelection(text)` — заменяет выделенный текст `[composer]`.
- `ayu.commands.register(name, description, fn)` — команда через точку в поле ввода (`.calc 2+2`). `fn(args, ctx)` возвращает текст для отправки или `null`, чтобы отменить отправку. Подсказки команд видны над клавиатурой `[commands]`.

## 11. Сообщения

- `ayu.messages.send({ peerId, text, replyTo })` → Promise — отправляет сообщение от имени пользователя `[messages]`.
- `ayu.messages.edit({ peerId, messageId, text })` → Promise — редактирует своё сообщение `[messages]`.
- `ayu.messages.react({ peerId, messageId, emoji })` → Promise — ставит реакцию `[messages]`.
- `ayu.messages.get({ peerId, limit })` → Promise — последние сообщения чата `[{ id, peerId, text, outgoing, date, authorId }]` `[messages.read]`.
- `ayu.messages.bookmarks.list()` — локальные закладки (на этом устройстве) `[messages.read]`.
- `ayu.messages.bookmarks.add({ peerId, messageId, text, chat, tag })` — добавляет закладку `[messages]`.
- `ayu.messages.bookmarks.remove(peerId, messageId)` — удаляет закладку `[messages]`.

## 12. Профиль собеседника (локально)

- `ayu.profile.notes.get(peerId)` — локальная заметка о человеке `[messages.read]`.
- `ayu.profile.notes.set(peerId, value)` — сохраняет заметку, `null` удаляет `[messages]`.
- `ayu.profile.nickname.get(peerId)` — локальный никнейм человека `[messages.read]`.
- `ayu.profile.nickname.set(peerId, value)` — задаёт никнейм, `null` удаляет `[messages]`.

## 13. Медиа (обработка картинок на устройстве)

- `ayu.media.process(base64, ops, { format, quality })` → Promise — обрабатывает картинку и возвращает base64. Операции:
  - `filter` — фильтр, один из `mono`, `noir`, `chrome`, `fade`, `instant`, `sepia`, `invert`, `blur`, `sharpen`, `vignette`, `pixellate` (`amount` — сила);
  - `resize` — уменьшить до `maxSide`;
  - `cropSquare` — обрезать до квадрата;
  - `rotate` — повернуть на `degrees`;
  - `brightness`, `contrast`, `saturation` — яркость, контраст, насыщенность (`amount`).

  Формат результата: `jpeg` или `png`.
- `ayu.media.fromMessage(peerId, messageId)` → Promise — картинка из сообщения: `{ data, width, height }` `[messages.read]`.
- `ayu.media.sendImage(peerId, base64, caption)` → Promise — отправляет картинку в чат `[messages]`.
- `ayu.media.cutOutSticker(peerId, messageId)` → Promise — стикер из фото в сообщении с вырезанным фоном `[messages]`.
- `ayu.media.describePhoto(peerId, messageId)` → Promise — текстовое описание фото из сообщения, или `null` `[messages.read]`.

### Встроенные инструменты

- `ayu.tools.chatStats(peerId)` → Promise — статистика чата по всей истории `[messages.read]`.
- `ayu.tools.yearInReview(peerId)` → Promise — «Год в обзоре» для чата `[messages.read]`.
- `ayu.tools.downloadChatMedia(peerId)` → Promise — скачать все медиа чата `[messages.read]`.

## 14. Музыкальный плеер

- `ayu.player.state()` — `{ title, artist, duration, position, playing }` текущего трека `[инжект]`.
- `ayu.player.control(action)` — `play`, `pause`, `toggle`, `next`, `previous` `[инжект]`.
- `ayu.player.play()` / `pause()` / `next()` / `previous()` — короткие формы `control` `[инжект]`.
- `ayu.player.spectrum.get(bands)` — настоящий спектр того, что играет: полосы от 40 Гц до 16 кГц (логарифмическая шкала), каждая 0…1, плюс общий уровень `{ bands, level, active }` `[overlay]`.
- `ayu.player.spectrum.subscribe(fn, { bands, fps })` — спектр потоком, `fn(bands, level)` с заданной частотой `[overlay]`.
- `ayu.player.spectrum.unsubscribe()` — останавливает поток.
- `ayu.player.visualizer.set({ style, color, bands, opacity, gain })` — встроенный визуализатор в окне плеера: `bars`, `mirror`, `wave`, `circle`, `dots`. Рисуется приложением на частоте экрана, без JS на каждый кадр `[overlay]`.
- `ayu.player.visualizer.clear()` — убирает визуализатор.
- `ayu.player.canvas.draw(shapes)` — рисует фигуры прямо в окне плеера: `rect`, `circle`, `line`, `text`; координаты 0…1 от области контента, у фигур есть `color` и `alpha` `[overlay]`.
- `ayu.player.canvas.clear()` — очищает холст.

## 15. Сеть и ИИ

- `ayu.net.fetch(url, { method, headers, body })` → Promise — HTTPS-запрос только к доменам из `@connect`. Ответ: `{ status, headers, text, json() }` `[network]`.
- `ayu.ai.complete(prompt, { system, maxTokens })` → Promise — запрос к OpenAI-совместимому сервису, который пользователь указал в VoidGram → Инструменты; возвращает текст `[ai]`.

## 16. Устройство и система

- `ayu.clipboard.write(text)` — копирует текст в буфер обмена `[clipboard]`.
- `ayu.clipboard.read()` → Promise — читает текст из буфера, iOS покажет своё уведомление о вставке `[clipboard.read]`.
- `ayu.clipboard.hasText()` → Promise — есть ли текст в буфере, не читая его `[clipboard]`.
- `ayu.clipboard.clear()` — очищает буфер `[clipboard]`.
- `ayu.device.info()` — `{ battery, charging, orientation, reduceMotion, lowPowerMode, locale }` `[device]`.
- `ayu.device.battery()` — заряд 0…1 или `null` `[device]`.
- `ayu.device.isCharging()` — заряжается ли телефон `[device]`.
- `ayu.device.screen()` — `{ width, height, scale }` экрана или `null` `[device]`.
- `ayu.device.darkMode()` — включена ли тёмная тема `[device]`.
- `ayu.device.model()` — модель устройства `[device]`.
- `ayu.device.systemVersion()` — версия iOS `[device]`.
- `ayu.device.timezone()` — `{ id, offsetMinutes }` часового пояса `[device]`.
- `ayu.device.isLowPower()` — включён ли режим энергосбережения `[device]`.
- `ayu.device.freeDisk()` — свободное место в байтах или `null` `[device]`.
- `ayu.device.memory()` — объём оперативной памяти устройства в байтах `[device]`.
- `ayu.device.uptime()` — секунды с запуска системы `[device]`.
- `ayu.device.thermalState()` — нагрев: `nominal`, `fair`, `serious`, `critical` `[device]`.
- `ayu.accessibility.info()` — `{ voiceOver, reduceMotion, reduceTransparency, boldText, invertColors, switchControl, closedCaptioning, grayscale, dynamicType }`.
- `ayu.appearance.info()` — `{ dark, classicDesign, noGlass, blurGlass, glassStyle, slowMotion, throttled }`; `throttled` — включён режим энергосбережения или телефон горячий.
- Заряд, зарядка, экран и тёмная тема берутся из снимка, который обновляется после каждого чтения, поэтому первое чтение может вернуть пустое значение.
- `ayu.haptics.play(style)` — вибрация: `light`, `medium`, `heavy`, `soft`, `rigid`, `selection`, `success`, `warning`, `error`. Не работает, если в настройках включено «Без вибрации» `[haptics]`.
- `ayu.haptics.pattern(styles, interval)` — серия до 16 откликов с интервалом `interval` мс (30–1000, по умолчанию 120) `[haptics]`.
- `ayu.speech.speak(text, { language, rate })` — озвучивает текст на устройстве `[ui]`.
- `ayu.speech.stop()` — останавливает озвучку `[ui]`.
- `ayu.speech.isSpeaking()` — идёт ли озвучка `[ui]`.
- `ayu.speech.voices()` — доступные голоса `[ui]`.
- `ayu.notify.schedule({ id, title, body, seconds })` — локальное напоминание через `seconds` секунд, возвращает id `[notifications]`.
- `ayu.notify.cancel(id)` — отменяет напоминание; плагин видит только свои `[notifications]`.
- `ayu.notify.cancelAll()` — отменяет все напоминания плагина `[notifications]`.
- `ayu.app.version()` — версия приложения.
- `ayu.app.build()` — номер сборки.
- `ayu.app.name()` — название приложения.
- `ayu.app.plugins()` — установленные плагины `[{ id, name, enabled }]`.
- `ayu.gestures.on('shake' | 'screenshot', fn)` — реакция на встряхивание телефона или скриншот.
- `ayu.files.export(name, text)` — предлагает пользователю сохранить или поделиться текстовым файлом.
- `ayu.i18n.language` — язык интерфейса (`ru`, `en`, …).
- `ayu.i18n.t({ ru: '…', en: '…' })` — выбирает строку на языке интерфейса; если перевода нет, берёт английскую.

## 17. Планировщик

- `ayu.scheduler.daily("HH:MM[:SS]", fn)` — каждый день в указанное время (пока приложение открыто); возвращает id.
- `ayu.scheduler.at(date | timestamp, fn)` — один раз в указанный момент; возвращает id.
- `ayu.scheduler.cancel(id)` — отменяет расписание.

## 18. Плагины между собой

- `ayu.bus.emit(topic, data)` — отправляет сообщение другим плагинам.
- `ayu.bus.on(topic, fn)` — получает сообщения других плагинов, `fn(data, fromPluginId)`. Свои сообщения не приходят.

## 19. Разрешения во время работы

- `ayu.permissions.has(name)` — проверяет, выдано ли разрешение.
- `ayu.permissions.request(names, fn)` → Promise — просит пользователя выдать разрешения, `fn(granted)`.

## 20. Реестр команды VoidGram

- `ayu.registry.developers.isVerified(peerId)` — есть ли у человека плашка «подтверждено командой VoidGram для iOS».
- `ayu.registry.developers.info(peerId)` — `{ verified, kind, text }` плашки.

## 21. TL-хуки (официальные плагины)

- `ayu.tl.block(method)` — не отправлять на сервер вызовы присутствия и прочтения с этим методом (pre_request) `[официальный]`.
- `ayu.tl.unblock(method)` — снимает блокировку `[официальный]`.
- `ayu.tl.onRequest(fn)` — `fn(method, errorCode)` после каждого запроса к серверу: только имя метода, без содержимого (post_request) `[официальный]`.
- `ayu.tl.onUpdate(fn)` — `fn(constructor)` для каждого входящего обновления: только имя конструктора (on_update) `[официальный]`.

## 21а. Встроенные помощники (27.6)

Разрешения не нужны. `crypto` и `encoding` выполняет приложение, поэтому они доступны из всех
языков через `ayu.call`. Остальные работают внутри JS-плагина: **только JavaScript и TypeScript**.

**`ayu.crypto`**
- `ayu.crypto.sha256(text)` — SHA-256 текста в hex.
- `ayu.crypto.sha1(text)` — SHA-1 в hex.
- `ayu.crypto.sha512(text)` — SHA-512 в hex.
- `ayu.crypto.md5(text)` — MD5 в hex.
- `ayu.crypto.hmac(key, text)` — HMAC в hex.
- `ayu.crypto.randomBytes(count)` — случайные байты в base64.
- `ayu.crypto.uuid()` — случайный UUID.

**`ayu.encoding`**
- `ayu.encoding.base64Encode(text)` — текст в base64.
- `ayu.encoding.base64Decode(base64)` — base64 в текст, или `null`.
- `ayu.encoding.hexEncode(text)` — текст в hex.
- `ayu.encoding.hexDecode(hex)` — hex в текст, или `null`.

**`ayu.text`**
- `ayu.text.capitalize(text)` — первая буква заглавная.
- `ayu.text.titleCase(text)` — каждое слово с заглавной.
- `ayu.text.reverse(text)` — текст задом наперёд.
- `ayu.text.truncate(text, length, ellipsis)` — обрезает до длины с многоточием.
- `ayu.text.slugify(text)` — делает из текста адресную строку.
- `ayu.text.wordCount(text)` — число слов.
- `ayu.text.charCount(text)` — число символов.
- `ayu.text.stripEmoji(text)` — убирает эмодзи.
- `ayu.text.escapeHtml(text)` / `unescapeHtml(text)` — экранирует HTML и обратно.
- `ayu.text.translit(text)` — транслитерация.
- `ayu.text.swapLayout(text)` — меняет раскладку: `ghbdtn` ⇄ `привет`.
- `ayu.text.mock(text)` — чЕрЕдУеТ рЕгИсТр.
- `ayu.text.between(text, start, end)` — текст между двумя строками, или `null`.
- `ayu.text.template(text, vars)` — подставляет значения в шаблон.
- `ayu.text.normalizeSpaces(text)` — убирает лишние пробелы.
- `ayu.text.removeUrls(text)` — убирает ссылки.
- `ayu.text.removeMentions(text)` — убирает упоминания.
- `ayu.text.detectScript(text)` — алфавит: `cyrillic`, `latin`, `mixed`, `other`.
- `ayu.text.wrap(text, width)` — переносит строки по ширине.
- `ayu.text.occurrences(text, part)` — сколько раз встречается подстрока.
- `ayu.text.randomString(length, alphabet)` — случайная строка, до 10000 символов.
- `ayu.text.isEmojiOnly(text)` — состоит ли текст только из эмодзи.
- `ayu.text.firstLine(text)` — первая строка.

**`ayu.date`**
- `ayu.date.format(date, pattern)` — форматирует дату, например `DD.MM.YYYY HH:mm`.
- `ayu.date.relative(date, language)` — «5 минут назад».
- `ayu.date.addDays(date, days)` — прибавляет дни.
- `ayu.date.diffDays(from, to)` — разница в днях.
- `ayu.date.isToday(date)` — сегодня ли это.
- `ayu.date.startOfDay(date)` — начало дня.
- `ayu.date.parseDuration(text)` — `"1h 30m"` в миллисекунды, единицы `ms s m h d w`; или `null`.
- `ayu.date.formatDuration(ms, language)` — миллисекунды в читаемый вид.
- `ayu.date.weekday(date, language)` — день недели.
- `ayu.date.monthName(date, language)` — название месяца.
- `ayu.date.isWeekend(date)` — выходной ли это.
- `ayu.date.daysInMonth(date)` — дней в месяце.
- `ayu.date.age(birth, at)` — возраст в годах.
- `ayu.date.unix(date)` — секунды Unix.
- `ayu.date.fromUnix(seconds)` — дата из секунд Unix.
- `ayu.date.countdown(target)` — `{ days, hours, minutes, seconds }` до даты.

**`ayu.color`**
- `ayu.color.hexToRgb(hex)` — `{ r, g, b }` или `null`.
- `ayu.color.rgbToHex(r, g, b)` — цвет в `#RRGGBB`.
- `ayu.color.lighten(hex, amount)` — светлее.
- `ayu.color.darken(hex, amount)` — темнее.
- `ayu.color.mix(a, b, amount)` — смешивает два цвета.
- `ayu.color.contrastText(hex)` — чёрный или белый текст на этом фоне.
- `ayu.color.random()` — случайный цвет.
- `ayu.color.toHsl(hex)` — `{ h, s, l }` или `null`.
- `ayu.color.fromHsl(h, s, l)` — цвет из HSL.
- `ayu.color.invert(hex)` — обратный цвет.
- `ayu.color.grayscale(hex)` — оттенок серого.
- `ayu.color.rgba(hex, alpha)` — строка `rgba(...)`.

**`ayu.math`**
- `ayu.math.clamp(value, min, max)` — ограничивает диапазоном.
- `ayu.math.lerp(a, b, t)` — линейная интерполяция.
- `ayu.math.random(min, max)` — случайное число.
- `ayu.math.randomInt(min, max)` — случайное целое.
- `ayu.math.round(value, digits)` — округляет до знаков.
- `ayu.math.sum(list)` — сумма.
- `ayu.math.average(list)` — среднее.
- `ayu.math.median(list)` — медиана.
- `ayu.math.percent(part, total)` — процент.
- `ayu.math.factorial(n)` — факториал.
- `ayu.math.gcd(a, b)` — наибольший общий делитель.
- `ayu.math.lcm(a, b)` — наименьшее общее кратное.
- `ayu.math.isPrime(n)` — простое ли число; `null` выше 10¹².
- `ayu.math.fibonacci(n)` — число Фибоначчи.
- `ayu.math.mod(a, b)` — остаток, всегда неотрицательный при положительном `b`.
- `ayu.math.roundTo(value, step)` — округляет до кратного шага.
- `ayu.math.range(start, end, step)` — последовательность, до 100000 чисел.

**`ayu.url`**
- `ayu.url.parse(url)` — `{ protocol, host, port, path, query, hash }` или `null`.
- `ayu.url.build(base, params)` — собирает ссылку с параметрами.
- `ayu.url.param(url, name)` — значение параметра.
- `ayu.url.isUrl(text)` — ссылка ли это.
- `ayu.url.extract(text)` — все ссылки из текста.
- `ayu.url.domain(url)` — домен.

**`ayu.array`**
- `ayu.array.chunk(list, size)` — делит на части.
- `ayu.array.unique(list, key)` — убирает повторы.
- `ayu.array.shuffle(list)` — перемешивает.
- `ayu.array.sample(list)` — случайный элемент.
- `ayu.array.groupBy(list, key)` — группирует.
- `ayu.array.sortBy(list, key, descending)` — сортирует по ключу.
- `ayu.array.flatten(list, depth)` — разворачивает вложенные массивы.
- `ayu.array.zip(...lists)` — соединяет массивы попарно.
- `ayu.array.countBy(list, key)` — считает по ключу.
- `ayu.array.partition(list, fn)` — делит на подходящие и остальные.
- `ayu.array.last(list)` — последний элемент.
- `ayu.array.compact(list)` — убирает `null`, `undefined`, `false`, пустые строки и `NaN`, ноль оставляет.
- `ayu.array.intersect(a, b)` — общие элементы.
- `ayu.array.difference(a, b)` — элементы `a`, которых нет в `b`.

**`ayu.object`**
- `ayu.object.pick(value, keys)` — только указанные ключи.
- `ayu.object.omit(value, keys)` — всё, кроме указанных ключей.
- `ayu.object.merge(target, source)` — глубокое слияние.
- `ayu.object.get(value, path, fallback)` — значение по пути `a.b.0`.
- `ayu.object.set(value, path, item)` — записывает по пути.

**`ayu.validate`**
- `ayu.validate.email(text)` — похоже ли на почту.
- `ayu.validate.phone(text)` — похоже ли на телефон.
- `ayu.validate.username(text)` — подходит ли как юзернейм.
- `ayu.validate.hexColor(text)` — цвет ли это в hex.

**`ayu.async`**
- `ayu.async.sleep(ms)` — пауза, возвращает Promise.
- `ayu.async.debounce(fn, ms)` — вызывает `fn` после паузы в вызовах.
- `ayu.async.throttle(fn, ms)` — вызывает `fn` не чаще раза в `ms`.
- `ayu.async.retry(fn, times, delay)` — повторяет при ошибке.
- `ayu.async.timeout(promise, ms)` — ошибка, если не успели за `ms`.

**`ayu.format`**
- `ayu.format.bytes(value, digits)` — размер: `1.5 MB`.
- `ayu.format.number(value, digits)` — число с разделителями.
- `ayu.format.plural(count, forms)` — склонение: `['яблоко', 'яблока', 'яблок']`.

**`ayu.extract`**
- `ayu.extract.mentions(text)` — все упоминания.
- `ayu.extract.hashtags(text)` — все хештеги.
- `ayu.extract.emails(text)` — все адреса почты.

## 22. События (`ayu.on`)

- `load` — плагин запущен.
- `unload` — плагин останавливается.
- `chatOpen` / `chatClose` — открыт или закрыт чат, `{ peerId }`.
- `profileOpen` / `profileClose` — открыт или закрыт профиль, `{ peerId }`.
- `screenChange` — сменился экран приложения.
- `appForeground` / `appBackground` — приложение на экране или свёрнуто.
- `accountChange` — переключён аккаунт, `{ accountId }`.
- `settingsChange` — пользователь изменил настройку плагина, `{ key, value }`.
- `menuAction` — нажат пункт в меню сообщения, `{ itemId, messageId, peerId, text }`.
- `profileButton` — нажата кнопка в профиле, `{ buttonId, peerId }`.
- `uiResult` — ответ диалога или меню (обычно приходит в колбэк `alert` или `sheet`).
- `screenAction` — нажатие на своей странице, `{ screenId, rowId, value }`.
- `composerButton` — нажата кнопка над клавиатурой, `{ id, text, selection, selectionStart, selectionEnd }`.
- `chatToolbar` — нажата кнопка в панели чата, `{ id, peerId }`.
- `floatingButton` — нажата плавающая кнопка, `{ id }`.
- `searchQuery` — новый запрос в поиске плагина, `{ id, query }`.
- `searchResult` — нажат результат поиска, `{ id, rowId }`.
- `messageSent` / `messageEdited` / `messageDeleted` — сообщение отправлено, изменено или удалено.
- `intent` — вызов из «Быстрых команд» или Siri.
- `busMessage` — сообщение от другого плагина, `{ topic, data, from }`.
- `gesture` — встряхивание или скриншот, `{ type }`.
- `playerSpectrum` — кадр спектра после `spectrum.subscribe`, `{ bands, level }`.
- `trackChange` — начался новый трек, `{ title, artist, duration }` `[инжект]`.
- `tlRequest` / `tlUpdate` — запросы и обновления после `tl.onRequest` / `tl.onUpdate` `[официальный]`.

## 23. Низкоуровневые операции (для Python, Lua и Rust)

Любую операцию можно вызвать напрямую: в Python — `ayu.call('op', **args)`, в Lua —
`ayu.call('op', args)` или `ayu.api('op')(args)`, в Rust — `ayugram_plugin::call(op, json)`.
Асинхронные операции: в Lua — `ayu.request(op, args, fn)`, в Rust — `ayugram_plugin::request`.

- `ui.alert`, `ui.sheet` — диалог и меню действий.
- `ui.menu.add`, `ui.menu.remove` — пункты меню сообщения.
- `ui.profile.addBlock`, `ui.profile.removeBlock`, `ui.profile.addButton`, `ui.profile.removeButton` — блоки и кнопки в профиле.
- `ui.badge.add`, `ui.badge.remove` — бейджи у чатов.
- `ui.avatar.decorate`, `ui.avatar.clear` — эмодзи на аватарке.
- `ui.overlay.create`, `ui.overlay.update`, `ui.overlay.addText`, `ui.overlay.addClock`, `ui.overlay.showFPS`, `ui.overlay.remove` — эффекты и надписи поверх приложения.
- `ui.animation.play` — анимация на весь экран.
- `ui.floatingButton.add`, `ui.floatingButton.remove` — плавающая кнопка.
- `ui.progress.show`, `ui.progress.hide` — индикатор прогресса.
- `ui.chatBackground.set`, `ui.chatBackground.reset` — цвет поверх обоев чата.
- `ui.font.set`, `ui.font.reset` — шрифты.
- `ui.tabs.add`, `ui.tabs.remove` — вкладки.
- `ui.sidebar.show` — боковая панель.
- `ui.searchBar.show`, `ui.searchBar.setResults` — поиск.
- `ui.gifts.catalog.list` — каталог подарков.
- `screens.show` — своя страница.
- `chat.scrollTo`, `chat.toolbar.add`, `chat.toolbar.remove`, `chat.toolbar.filter`, `chat.filter.set` — чат.
- `composer.addButton`, `composer.removeButton`, `composer.setText`, `composer.replaceSelection` — поле ввода.
- `commands.register` — команды через точку.
- `messages.send`, `messages.edit`, `messages.react`, `messages.get` — сообщения.
- `messages.bookmarks.list`, `messages.bookmarks.add`, `messages.bookmarks.remove` — закладки.
- `profile.notes.get`, `profile.notes.set`, `profile.nickname.get`, `profile.nickname.set` — заметки и никнеймы.
- `media.process`, `media.fromMessage`, `media.sendImage` — картинки.
- `player.spectrum.get`, `player.spectrum.subscribe`, `player.spectrum.unsubscribe` — спектр.
- `player.visualizer.set`, `player.visualizer.clear` — визуализатор.
- `player.canvas.draw`, `player.canvas.clear` — холст в плеере.
- `net.fetch` — HTTPS-запрос.
- `ai.complete` — запрос к ИИ.
- `secrets.get`, `secrets.set` — Keychain.
- `clipboard.write` — буфер обмена.
- `device.info` — сведения об устройстве.
- `haptics.play` — вибрация.
- `files.export` — сохранить файл.
- `bus.emit` — сообщение другим плагинам.
- `permissions.has`, `permissions.request` — разрешения.
- `registry.isVerified` — плашка команды.
- `tl.block`, `tl.unblock`, `tl.observe` — TL-хуки.
- `tools.chatStats`, `tools.yearInReview`, `tools.downloadChatMedia` — встроенные инструменты.
- `media.cutOutSticker`, `media.describePhoto` — стикер из фото и описание фото.
- `crypto.sha256`, `crypto.sha1`, `crypto.sha512`, `crypto.md5`, `crypto.hmac`, `crypto.randomBytes`, `crypto.uuid` — хеши и случайные значения.
- `encoding.base64Encode`, `encoding.base64Decode`, `encoding.hexEncode`, `encoding.hexDecode` — кодировки.
- `app.version`, `app.build`, `app.name`, `app.plugins` — приложение.
- `device.battery`, `device.isCharging`, `device.screen`, `device.darkMode`, `device.model`, `device.systemVersion`, `device.timezone`, `device.isLowPower`, `device.freeDisk`, `device.memory`, `device.uptime`, `device.thermalState` — устройство.
- `clipboard.read`, `clipboard.hasText`, `clipboard.clear` — буфер обмена.
- `haptics.pattern` — серия откликов.
- `speech.speak`, `speech.stop`, `speech.isSpeaking`, `speech.voices` — озвучка.
- `notify.schedule`, `notify.cancel`, `notify.cancelAll` — напоминания.

Имена аргументов те же, что в JS-обёртках: смотрите `prelude/prelude.swift`.

---

# Для разработчиков

## Форматы плагинов

- JavaScript — `.ayujs`, `.ayu.js`, `.js`. JavaScriptCore, у каждого плагина своя виртуальная машина и своя очередь.
- TypeScript — компилируется в JS; типы лежат в `sdk/typescript/ayu.d.ts`.
- Python — `.ayupy`, `.ayu.py`, `.py`. PocketPy 2.1.8 без `os`/`io`: нет файлов, сокетов, `system()` и `dlopen`.
- Lua — `.ayulua`, `.ayu.lua`, `.lua`. Lua 5.4.7 с библиотеками base, coroutine, string, table, math и utf8; нет `io`, `os`, `load` и файлов.
- Rust / WebAssembly — `.wasm`, `.ayuwasm`. Интерпретатор WAMR без JIT; единственный импорт — `ayu.host`.
- Zig, Go (TinyGo), AssemblyScript — тоже собираются в WebAssembly, SDK лежат в `sdk/`.
- `.plugin` (бандл) — zip с `plugin.json` (`{ "main": "main.lua" }`) и файлами на том же языке. Модули подключаются через `require`: `require("./util")` в JS, `require("util")` в Lua; в Python файлы склеиваются.
- `.iosplug` — JSON-карточка нативного плагина (форматы `ayu-iosplug-1` и `ayu-iosplug-2`), кода в ней нет.
- Плагины exteraGram на Python запускаются через слой совместимости (см. ниже).

## Заголовок плагина

```js
// ==AyuPlugin==
// @id my-plugin
// @name My plugin
// @name:ru Мой плагин
// @author @telegram_nick
// @version 1.0
// @description What it does.
// @description:ru Что делает.
// @permissions ui, menu, network
// @connect api.example.com
// @requires other-plugin
// @inject true
// @tags text, privacy
// ==/AyuPlugin==
```

- `@id` — a–z, 0–9, `-`, `_`; по умолчанию берётся из имени файла.
- `@name`, `@description` — название и описание; `@name:<язык>` и `@description:<язык>` подставляются для этого языка интерфейса.
- `@author`, `@version` — автор и версия; в каталоге по версии определяется, есть ли обновление.
- `@permissions` — какие разрешения нужны; их видно при установке, и каждое можно отозвать.
- `@connect` — домены, к которым разрешён `ayu.net.fetch`.
- `@requires` — плагины, без которых этот не запустится.
- `@inject true` — плагин встраивается в приложение (плеер, тексты песен).
- `@tags` — метки для каталога.
- В Python заголовок пишется через `#`, в Lua через `--`, в Rust это JSON-секция `ayu.manifest` (`manifest!` в SDK).

## Разрешения

- `ui` — диалоги и меню действий, кнопки в панели чата, прокрутка чата, озвучка.
- `menu` — пункты в меню сообщений.
- `profile` — блоки и кнопки в профиле.
- `overlay` — эффекты поверх приложения, плавающие кнопки, фон чата, спектр, визуализатор и холст плеера.
- `fonts` — шрифты.
- `badges` — бейджи и украшения аватарок у чатов.
- `clipboard` — запись и очистка буфера обмена.
- `clipboard.read` — ⚠️ чтение буфера обмена.
- `device` — сведения об устройстве.
- `haptics` — вибрация.
- `network` — интернет, только домены из `@connect`.
- `messages` — отправка, правка и реакции от имени пользователя; запись закладок, заметок и никнеймов.
- `messages.read` — ⚠️ чтение сообщений, закладок, заметок и никнеймов, картинок из сообщений; фильтры сообщений; статистика и инструменты чата.
- `ai` — запросы к ИИ пользователя.
- `secrets` — секреты в Keychain.
- `composer` — кнопки над клавиатурой и текст в поле ввода.
- `notifications` — текст уведомлений и локальные напоминания.
- `links` — переписывание ссылок.
- `screens` — свои страницы, вкладки, боковая панель, поиск.
- `commands` — команды через точку.

Вызов без нужного разрешения не выполняется и пишет ошибку в консоль. Пользователь может отозвать
каждое разрешение: Плагин → Разрешения и приватность.

## Безопасная зона и подписи

- Обычные плагины (текст, отключение функций, хранилище, настройки, интерфейс) можно ставить откуда угодно.
- Плагины с `@inject` ставятся только с подписью VoidGram (Ed25519, в каталоге отмечены «✓ официальный»).
- Неподписанный инжект-плагин можно разрешить в настройках разработчика: «Инжект-плагины из неофициальных источников». После предупреждения вся ответственность на пользователе.
- Инжект-API проверяется и во время работы: недоверенный плагин получает ошибку в консоли.
- TL-хуки работают только у доверенных плагинов (официальных или разрешённых пользователем).
- Список отзыва (`registry/revoked.json`, подписан): отозванный плагин отключается у всех.

## Лимиты

- Хук должен ответить за 250 мс (2 с с «Мягкими лимитами плагинов»), иначе плагин отключается, а все его хуки снимаются.
- Хранилище — 64 КБ на плагин.
- Размер файла: код до 512 КБ, WebAssembly до 2 МБ, `.iosplug` до 64 КБ, бандл `.plugin` до 4 МБ.
- Lua — общая куча до 32 МБ, защищённый вызов и ограничение по числу инструкций.
- Таймеры — не чаще раза в 100 мс.
- До 5 пунктов меню сообщения на плагин; не больше 2 вкладок от плагинов.
- В приложение уходит только чистый JSON: BigInt становится строкой, функции и символы отбрасываются, циклические структуры превращаются в `{}`.
- Когда плагин останавливается, всё, что он добавил (меню, кнопки, эффекты, вкладки, хуки), убирается.

## Python: совместимость с exteraGram

- `BasePlugin` — `on_plugin_load`, `on_plugin_unload`, `create_settings`, `get_setting`, `log`, `add_on_send_message_hook`, `on_send_message_hook`, `add_menu_item`, `remove_menu_item`.
- `HookStrategy` — `DEFAULT`, `CANCEL`, `MODIFY`, `MODIFY_FINAL`.
- `HookResult(strategy, params, request, update, updates)` — результат хука отправки.
- `MenuItemType` — `MESSAGE_CONTEXT_MENU`, `DRAWER_MENU`, `CHAT_ACTION_MENU`, `PROFILE_ACTION_MENU`.
- `MenuItemData(menu_type, text, on_click, icon, item_id, priority, condition, subtext)` — пункт меню.
- Элементы настроек: `Header`, `Switch`, `Input`, `Selector`, `Text`, `Divider`.
- Объект `ayu` в Python содержит те же разделы, что в JS (`hooks`, `storage`, `settings`, `ui`, `net`, `messages`, `secrets`, `profile`, `chat`, `gestures`, `player`, `tl`, `media`, `bus`, `i18n`, `ai`, `screens`, `composer`, `files`, `permissions`, `commands`), плюс `ayu.call(op, **args)` и `ayu.is_verified(peer_id)`. Хуки можно вешать декоратором: `@ayu.hooks.before(ayu.hooks.points.outgoing_text)`.

## Совместимость с WhiteGram (JavaScript)

- `wg.registerPlugin(plugin)` — регистрирует плагин (`onLoad` / `onUnload`).
- `wg.BasePlugin` — базовый класс.
- `wg.on`, `wg.log`, `wg.toast`, `wg.getStorage`, `wg.setStorage` — соответствуют `ayu.*`.
- `wg.hooks`, `wg.features` — то же, что `ayu.hooks` и `ayu.features`.

## Lua

- `ayu.call(op, args)` — любая операция из раздела 23.
- `ayu.api(op)(args)` — то же в виде функции.
- `ayu.request(op, args, fn)` — асинхронная операция с колбэком.
- `ayu.hooks.before / after / replace(point, fn)` — хуки; точки — `ayu.points.outgoing_text`, `lyrics_text`, `link_open`, `message_render`, `notification`.
- `ayu.on(event, fn)`, `ayu.log / warn / error`, `ayu.toast`, `ayu.storage.get / set`, `ayu.json` — как в JS.

## Rust (`sdk/rust`, крейт `ayugram_plugin`)

- `manifest!(json)` — манифест плагина (секция `ayu.manifest`).
- `hook!` — объявить хук макросом.
- `hooks::before / after / replace(point, handler)` — хуки; точки `OUTGOING_TEXT`, `LINK_OPEN`, `MESSAGE_RENDER`, `NOTIFICATION_BEFORE_SHOW`, `LYRICS_TEXT`.
- `on(event, handler)` — события.
- `log`, `warn`, `toast` — консоль и всплывающие сообщения.
- `storage::get / set` — хранилище.
- `features::disable / enable` — встроенные функции.
- `player::state / control` — плеер.
- `ui::alert`, `ui::menu_add`, `ui::menu_remove`, `ui::overlay`, `ui::overlay_remove`, `ui::badge` — интерфейс.
- `call(op, json)` и `request(message)` — любая операция.
- `json` — простой JSON без зависимостей.
- Модуль экспортирует `ayu_alloc`, `ayu_free`, `ayu_dispatch`, `ayu_init`.
- Сборка: `cargo build --release --target wasm32-unknown-unknown`.

## Zig, Go (TinyGo), AssemblyScript

- Общий набор во всех трёх: `before`, `after`, `replace`, `on`, `call`, `request`, `log`, `toast`.
- Go дополнительно: `StorageGet`, `StorageSet`.
- AssemblyScript экспортирует `ayu_alloc`, `ayu_free`, `ayu_dispatch`, `ayu_init`; есть помощники `quote` и `stringField` для JSON.
- Zig: помощники `quote`, `stringField`, `upper`, `release`.

## Инструменты

- **ayu-cli** (`tools/ayu-cli`):
  - `ayu new <имя> [-lang js|ts|py|rust|zig|as|go]` — заготовка плагина на 7 языках;
  - `ayu check <файл>` — проверка заголовка, разрешений и размера;
  - `ayu pack <in.wasm> <manifest.json> <out.wasm>` — вшивает манифест в WebAssembly;
  - `ayu sha <файл>` — SHA-256 для каталога;
  - `ayu dev <файл> [-port 8765]` — горячая перезагрузка: плагин обновляется на телефоне по WebSocket при каждом сохранении.
- **mock-runner** (`tools/mock-runner`) — запуск JS-плагина в Node на настоящей прелюдии приложения, без телефона: `--send "текст"`, `--event имя '{json}'`, `--link https://…`. Там же тесты прелюдии и API 27.6 и фаззинг Plugin API (`PRELUDE=prelude/prelude.swift node --test prelude.test.ts fuzz.test.ts api276.test.ts`), фаззинг прогоняется в CI.
- **Типы**: TypeScript (`sdk/typescript/ayu.d.ts`) и Python (`sdk/python/ayu.pyi`) — для автодополнения в редакторе.

## В приложении (Настройки → VoidGram → Для разработчиков)

Раздел открывается пятью нажатиями на версию VoidGram, подтверждением и перезапуском.
- **Консоль плагинов** — `print`, ошибки и активность хуков, REPL (выполнить код внутри плагина), расход памяти приложения.
- **Профайлер** — сообщает о медленных плагинах.
- **Мягкие лимиты плагинов** — тайм-аут хука до 2 с, ошибки скриптов показываются всплывающими сообщениями.
- **Подробный лог** — пишет всё в файл, которым можно поделиться.
- **Инжект-плагины из неофициальных источников** — снимает ограничение безопасной зоны (с предупреждением).
- **Облачная сборка** — сборка плагина на GitHub для разработчиков из списка `developers/` в репозитории каталога (ветка `beta`).

## Каталог плагинов и шрифтов

- Репозиторий: [murk-sus/VoidGram-plugins](https://github.com/murk-sus/VoidGram-plugins). Плагины лежат в `plugins/<id>/`, шрифты — в `fonts/<id>/`. В папке: сам файл, `screenshot.png|jpg|webp` и `README.md` с описанием.
- В приложении: Плагины → значок сумки. Там поиск, разделы «Плагины» и «Шрифты», установка в одно нажатие с проверкой SHA-256 и кнопка «Обновить», когда вышла новая версия.
- Поля записи каталога: `id`, `name`, `author`, `version`, `description`, `tags`, `kind`, `url`, `sha256`, `size`, `signature`, `injects`, `changelog`, `category`, `screenshots`.
- При обновлении предыдущая версия сохраняется, и на неё можно откатиться.
- Автообновление плагинов при запуске включается в «Приватность и мелочи». Инжект-плагины автоматически не обновляются.
- Публикация: pull request в репозиторий или бот команды @ayugram_dev_settings_bot. Бот проверяет файл, записывает автора (ник в Telegram), описание и скриншот, а каталог и README пересобираются автоматически.
- Шрифты: `.ttf` или `.otf` до 15 МБ, с PostScript-именем. Выбранный шрифт становится шрифтом приложения после перезапуска.

## Почему в API осталось `ayu`

Проект теперь называется VoidGram, но эти имена не менялись: на них написаны все плагины, и их
сверяют уже установленные версии приложения.

- Глобальный объект `ayu` и все `ayu.*`, `ayu_init`, `ayu_dispatch`, секция `ayu.manifest`.
- Заголовок `==AyuPlugin==`, расширения `.ayujs`, `.ayupy`, `.ayulua`, `.ayuwasm`, форматы `ayu-iosplug-1` и `ayu-iosplug-2`.
- Форматы каталога: `ayugram-plugin-catalog`, `ayugram-font-catalog`, `ayugram-verified`, `ayugram-revoked`, `ayugram-ios-plugin`, `ayugram/catalog-v1`.
- Крейт Rust `ayugram_plugin`, модуль Go `github.com/murk-sus/ayugram-sdk` и CLI `ayu`.
- Ник бота команды `@ayugram_dev_settings_bot`.

Встроенные функции приложения (статистика чата, «Год в обзоре», стикер из фото, описание фото,
скачать все медиа, закладки) теперь сами плагины. Их код — хорошие примеры: `examples/code-plugins/`.

## Минимальные примеры

JavaScript:
```js
// ==AyuPlugin==
// @id shout
// @name Shout
// @author @me
// @version 1.0
// @description Adds "!" to outgoing messages.
// ==/AyuPlugin==
ayu.hooks.before(ayu.hooks.points.outgoingText, (text) => text + '!');
```

Python:
```python
# ==AyuPlugin==
# @id shout-py
# @name Shout
# @author @me
# @version 1.0
# @description Adds "!" to outgoing messages.
# ==/AyuPlugin==
@ayu.hooks.before(ayu.hooks.points.outgoing_text)
def shout(text, ctx):
    return text + '!'
```

Lua:
```lua
-- @id shout-lua
-- @name Shout
-- @author @me
-- @version 1.0
-- @description Adds "!" to outgoing messages.
ayu.hooks.before(ayu.points.outgoing_text, function(text, ctx) return text .. "!" end)
```

Rust:
```rust
use ayugram_plugin::{hooks, manifest};
manifest!(br#"{"id":"shout-rs","name":"Shout","author":"@me","version":"1.0","description":"Adds !"}"#);
#[no_mangle]
pub extern "C" fn ayu_init() {
    hooks::before(hooks::OUTGOING_TEXT, |text, _ctx| Some(format!("{}!", text)));
}
```
