# AyuGram для iOS — полный справочник API плагинов (27.5)

Всё, что плагин может вызвать, и всё, что есть для разработчиков. Справочник собран по коду
приложения 27.5: JS-прелюдии, операциям хоста, SDK и инструментам.

Обозначения:
- `[разрешение]` — вызов работает, только если в заголовке плагина есть `@permissions разрешение`.
- `[официальный]` — только для доверенных плагинов: с подписью AyuGram или инжект-плагинов, которые пользователь сам разрешил.
- Удаление и очистка своего (`remove`, `clear`, `reset`, `hide`, `unsubscribe`) разрешения не требуют, кроме отмеченных.
- `[инжект]` — нужен `@inject true`, работает только у доверенного плагина (см. «Безопасная зона»).
- «→ Promise» — вызов асинхронный и возвращает Promise.

Плагины пишутся на JavaScript, Python, Lua и Rust (WebAssembly). Названия везде одинаковые;
в Python они записываются в snake_case (`scroll_to`, `add_button`), в Lua и Rust есть
универсальный вызов `call(op, args)` (раздел «Низкоуровневые операции»).

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

## 2. Хуки (перехват и замена поведения)

- `ayu.hooks.before(point, fn)` — `fn(text, ctx)` выполняется до встроенного обработчика. Возвращает новый текст или ничего, чтобы оставить как есть.
- `ayu.hooks.after(point, fn)` — то же, но после встроенного обработчика.
- `ayu.hooks.replace(point, fn)` — полностью заменяет встроенный обработчик. Заменить точку может только один плагин, остальные становятся `after`.
- `ayu.hooks.points.outgoingText` = `message.outgoing.text` — текст исходящего сообщения перед отправкой (облачные чаты, без медиа; секретные чаты не затрагиваются).
- `ayu.hooks.points.lyricsText` = `lyrics.text` — текст песни перед показом, построчно `[инжект]`. Пустая строка убирает строку, тайминги сохраняются.
- `ayu.hooks.points.linkOpen` = `link.open` — переписать ссылку прямо перед открытием `[links]`.
- `ayu.hooks.points.messageRender` = `message.render` — изменить, как текст сообщения показывается в чате; сохранённые данные не меняются.
- `ayu.hooks.points.notificationBeforeShow` = `notification.beforeShow` — изменить текст локального уведомления AyuGram, пустая строка его отменяет `[notifications]`.
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

- `ayu.screens.show({ id, title, sections })` — полноценная страница, которую рисует AyuGram. Секции: `{ title, footer, rows }`; виды строк: `text`, `button`, `toggle`, `link`, `value`. Нажатия приходят событием `screenAction` `[screens]`.
- `ayu.ui.tabs.add({ id, title, icon, screen })` — вкладка в нижней панели со страницей плагина (не больше двух вкладок от плагинов) `[screens]`.
- `ayu.ui.tabs.remove(id)` — убирает вкладку.
- `ayu.ui.sidebar.show(screen)` — панель со страницей плагина, выезжает слева `[screens]`.
- `ayu.ui.searchBar.show({ id, title, placeholder }, onQuery)` — экран поиска; каждый запрос приходит в `onQuery(query)` `[screens]`.
- `ayu.ui.searchBar.setResults(id, rows)` — показывает результаты `[{ id, title, subtitle }]`; нажатие присылает `searchResult` `[screens]`.

## 9. Чат

- `ayu.chat.scrollTo(messageId)` — прокручивает открытый чат к сообщению `[ui]`.
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
- `ayu.ai.complete(prompt, { system, maxTokens })` → Promise — запрос к OpenAI-совместимому сервису, который пользователь указал в AyuGram → Инструменты; возвращает текст `[ai]`.

## 16. Устройство и система

- `ayu.clipboard.write(text)` — копирует текст в буфер обмена `[clipboard]`.
- `ayu.device.info()` — `{ battery, charging, orientation, reduceMotion, lowPowerMode, locale }` `[device]`.
- `ayu.haptics.play(style)` — вибрация: `light`, `medium`, `heavy`, `soft`, `rigid`, `selection`, `success`, `warning`, `error`. Не работает, если в настройках включено «Без вибрации» `[haptics]`.
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

## 20. Реестр команды AyuGram

- `ayu.registry.developers.isVerified(peerId)` — есть ли у человека плашка «подтверждено командой AyuGram для iOS».
- `ayu.registry.developers.info(peerId)` — `{ verified, kind, text }` плашки.

## 21. TL-хуки (официальные плагины)

- `ayu.tl.block(method)` — не отправлять на сервер вызовы присутствия и прочтения с этим методом (pre_request) `[официальный]`.
- `ayu.tl.unblock(method)` — снимает блокировку `[официальный]`.
- `ayu.tl.onRequest(fn)` — `fn(method, errorCode)` после каждого запроса к серверу: только имя метода, без содержимого (post_request) `[официальный]`.
- `ayu.tl.onUpdate(fn)` — `fn(constructor)` для каждого входящего обновления: только имя конструктора (on_update) `[официальный]`.

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

- `ui` — диалоги и меню действий, кнопки в панели чата, прокрутка чата.
- `menu` — пункты в меню сообщений.
- `profile` — блоки и кнопки в профиле.
- `overlay` — эффекты поверх приложения, плавающие кнопки, фон чата, спектр, визуализатор и холст плеера.
- `fonts` — шрифты.
- `badges` — бейджи и украшения аватарок у чатов.
- `clipboard` — запись в буфер обмена.
- `device` — сведения об устройстве.
- `haptics` — вибрация.
- `network` — интернет, только домены из `@connect`.
- `messages` — отправка, правка и реакции от имени пользователя; запись закладок, заметок и никнеймов.
- `messages.read` — ⚠️ чтение сообщений, закладок, заметок и никнеймов, картинок из сообщений; фильтры сообщений.
- `ai` — запросы к ИИ пользователя.
- `secrets` — секреты в Keychain.
- `composer` — кнопки над клавиатурой и текст в поле ввода.
- `notifications` — текст уведомлений.
- `links` — переписывание ссылок.
- `screens` — свои страницы, вкладки, боковая панель, поиск.
- `commands` — команды через точку.

Вызов без нужного разрешения не выполняется и пишет ошибку в консоль. Пользователь может отозвать
каждое разрешение: Плагин → Разрешения и приватность.

## Безопасная зона и подписи

- Обычные плагины (текст, отключение функций, хранилище, настройки, интерфейс) можно ставить откуда угодно.
- Плагины с `@inject` ставятся только с подписью AyuGram (Ed25519, в каталоге отмечены «✓ официальный»).
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
  - `ayu new <имя> [-lang js]` — заготовка плагина;
  - `ayu check <файл>` — проверка заголовка, разрешений и размера;
  - `ayu pack <in.wasm> <manifest.json> <out.wasm>` — вшивает манифест в WebAssembly;
  - `ayu sha <файл>` — SHA-256 для каталога;
  - `ayu dev <файл> [-port 8765]` — горячая перезагрузка: плагин обновляется на телефоне по WebSocket при каждом сохранении.
- **mock-runner** (`tools/mock-runner`) — запуск JS-плагина в Node на настоящей прелюдии приложения, без телефона: `--send "текст"`, `--event имя '{json}'`, `--link https://…`. Там же тесты прелюдии и фаззинг Plugin API (`node --test prelude.test.ts fuzz.test.ts`), фаззинг прогоняется в CI.
- **Типы**: TypeScript (`sdk/typescript/ayu.d.ts`) и Python (`sdk/python/ayu.pyi`) — для автодополнения в редакторе.

## В приложении (Настройки → AyuGram → Для разработчиков)

Раздел открывается пятью нажатиями на версию AyuGram, подтверждением и перезапуском.
- **Консоль плагинов** — `print`, ошибки и активность хуков, REPL (выполнить код внутри плагина), расход памяти приложения.
- **Профайлер** — сообщает о медленных плагинах.
- **Мягкие лимиты плагинов** — тайм-аут хука до 2 с, ошибки скриптов показываются всплывающими сообщениями.
- **Подробный лог** — пишет всё в файл, которым можно поделиться.
- **Инжект-плагины из неофициальных источников** — снимает ограничение безопасной зоны (с предупреждением).
- **Облачная сборка** — сборка плагина на GitHub для разработчиков из списка `developers/` в репозитории каталога (ветка `beta`).

## Каталог плагинов и шрифтов

- Репозиторий: [murk-sus/AyuGramm-Plugins](https://github.com/murk-sus/AyuGramm-Plugins). Плагины лежат в `plugins/<id>/`, шрифты — в `fonts/<id>/`. В папке: сам файл, `screenshot.png|jpg|webp` и `README.md` с описанием.
- В приложении: Плагины → значок сумки. Там поиск, разделы «Плагины» и «Шрифты», установка в одно нажатие с проверкой SHA-256 и кнопка «Обновить», когда вышла новая версия.
- Поля записи каталога: `id`, `name`, `author`, `version`, `description`, `tags`, `kind`, `url`, `sha256`, `size`, `signature`, `injects`, `changelog`, `category`, `screenshots`.
- При обновлении предыдущая версия сохраняется, и на неё можно откатиться.
- Автообновление плагинов при запуске включается в «Приватность и мелочи». Инжект-плагины автоматически не обновляются.
- Публикация: pull request в репозиторий или бот команды @ayugram_dev_settings_bot. Бот проверяет файл, записывает автора (ник в Telegram), описание и скриншот, а каталог и README пересобираются автоматически.
- Шрифты: `.ttf` или `.otf` до 15 МБ, с PostScript-именем. Выбранный шрифт становится шрифтом приложения после перезапуска.

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
