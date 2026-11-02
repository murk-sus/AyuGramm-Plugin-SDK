// The JavaScript prelude AyuGram for iOS 27.5 runs before every JS plugin (from AyuScriptRuntime.swift).
// Used by tools/mock-runner: node tools/mock-runner/cli.ts --prelude prelude/prelude.swift plugin.js
enum AyuScriptInstance {
    static let prelude = """
    (function (root) {
        'use strict';
        const host = root.__ayuHost;
        delete root.__ayuHost;
        // Only plain JSON reaches the app: BigInt becomes a string, functions and symbols are
        // dropped, and anything that cannot be serialised (cycles) is sent as {}.
        const nativeCall = host.call;
        host.call = function (op, args) {
            let clean;
            try { clean = JSON.parse(JSON.stringify(args === undefined ? {} : args, (key, value) => typeof value === 'bigint' ? String(value) : value)); } catch (e) { clean = {}; }
            if (clean === null || typeof clean !== 'object' || Array.isArray(clean)) clean = {};
            return nativeCall.call(host, String(op), clean);
        };
        const text = (value) => String(value === undefined || value === null ? '' : value);
        const fmt = (args) => Array.prototype.map.call(args, (v) => typeof v === 'string' ? v : (() => { try { return JSON.stringify(v); } catch (e) { return String(v); } })()).join(' ');
        const pending = {};
        let nextRequest = 1;
        // Alerts and sheets answer later through the "uiResult" event.
        function request(op, options, fn) {
            const requestId = 'r' + (nextRequest++);
            if (typeof fn === 'function') pending[requestId] = fn;
            return host.call(op, Object.assign({}, options, { requestId: requestId }));
        }
        host.on('uiResult', function (payload) {
            const fn = pending[payload && payload.requestId];
            if (fn) { delete pending[payload.requestId]; fn(payload.choice === undefined ? null : payload.choice); }
        });
        // Asynchronous host calls as promises; a refused call (missing permission) rejects at once.
        function requestAsync(op, options) {
            return new Promise(function (resolve, reject) {
                const accepted = request(op, options || {}, function (value) {
                    if (value && typeof value === 'object' && value.error) reject(new Error(value.error));
                    else resolve(value);
                });
                if (!accepted) reject(new Error(op + ' was refused (check @permissions)'));
            });
        }
        // Dot commands share one outgoing-text hook.
        const commandHandlers = {};
        let commandHookInstalled = false;
        function installCommandHook() {
            if (commandHookInstalled) return;
            commandHookInstalled = true;
            host.hook('message.outgoing.text', 'before', function (value, ctx) {
                const match = /^(\\.[A-Za-z0-9_]+)(?:\\s+([\\s\\S]*))?$/.exec(String(value));
                if (!match) return undefined;
                const fn = commandHandlers[match[1].toLowerCase()];
                if (!fn) return undefined;
                const result = fn(match[2] || '', ctx);
                return result === null || result === undefined || result === '' ? '\\u0000' : String(result);
            });
        }
        // Local schedules on top of the timers; they run while the app is open.
        const schedules = {};
        let nextSchedule = 1;
        function arm(id, at, fn, repeatDaily) {
            const delay = Math.max(0, at - Date.now());
            schedules[id] = setTimeout(function () {
                if (!schedules[id]) return;
                try { fn(); } finally {
                    if (repeatDaily) arm(id, at + 24 * 60 * 60 * 1000, fn, true);
                    else delete schedules[id];
                }
            }, Math.min(delay, 2147483647));
        }
        function register(point, mode, fn) {
            if (typeof fn !== 'function') throw new TypeError('Hook handler must be a function');
            return host.hook(text(point), mode, function (value, ctx) {
                const result = fn(value, ctx);
                return typeof result === 'string' ? result : undefined;
            });
        }
        const ayu = Object.freeze({
            pluginId: host.pluginId,
            log: function () { host.log('info', fmt(arguments)); },
            warn: function () { host.log('warning', fmt(arguments)); },
            error: function () { host.log('error', fmt(arguments)); },
            toast: (value) => host.toast(text(value)),
            on: (event, fn) => { if (typeof fn === 'function') host.on(text(event), fn); },
            hooks: Object.freeze({
                before: (point, fn) => register(point, 'before', fn),
                after: (point, fn) => register(point, 'after', fn),
                replace: (point, fn) => register(point, 'replace', fn),
                points: Object.freeze({ outgoingText: 'message.outgoing.text', lyricsText: 'lyrics.text', linkOpen: 'link.open', messageRender: 'message.render', notificationBeforeShow: 'notification.beforeShow' })
            }),
            settings: Object.freeze({
                declare: (items) => host.settingsDeclare(Array.isArray(items) ? items : []),
                get: (key) => { const v = host.settingGet(text(key)); return v === undefined ? null : v; }
            }),
            ui: Object.freeze({
                alert: (options, fn) => request('ui.alert', options || {}, fn),
                sheet: (options, fn) => request('ui.sheet', options || {}, fn),
                menu: Object.freeze({
                    add: (item) => host.call('ui.menu.add', item || {}),
                    remove: (id) => host.call('ui.menu.remove', { id: text(id) })
                }),
                profile: Object.freeze({
                    addBlock: (options) => host.call('ui.profile.addBlock', options || {}),
                    removeBlock: (id) => host.call('ui.profile.removeBlock', { id: text(id) }),
                    addButton: (options) => host.call('ui.profile.addButton', options || {}),
                    removeButton: (id) => host.call('ui.profile.removeButton', { id: text(id) })
                }),
                tabs: Object.freeze({
                    add: (options) => host.call('ui.tabs.add', options || {}),
                    remove: (id) => host.call('ui.tabs.remove', { id: text(id) })
                }),
                sidebar: Object.freeze({ show: (screen) => host.call('ui.sidebar.show', { screen: screen || {} }) }),
                searchBar: Object.freeze({
                    show: (options, onQuery) => {
                        const id = text((options || {}).id || 'search');
                        if (typeof onQuery === 'function') {
                            host.on('searchQuery', function (payload) { if (payload && payload.id === id) onQuery(payload.query); });
                        }
                        return host.call('ui.searchBar.show', Object.assign({}, options || {}, { id: id }));
                    },
                    setResults: (id, rows) => host.call('ui.searchBar.setResults', { id: text(id), rows: Array.isArray(rows) ? rows : [] })
                }),
                avatar: Object.freeze({
                    decorate: (peerId, emoji) => host.call('ui.avatar.decorate', { peerId: text(peerId), emoji: text(emoji) }),
                    clear: (peerId) => host.call('ui.avatar.clear', { peerId: text(peerId) })
                }),
                chatBackground: Object.freeze({
                    set: (options) => host.call('ui.chatBackground.set', options || {}),
                    reset: () => host.call('ui.chatBackground.reset', {})
                }),
                floatingButton: Object.freeze({
                    add: (options, fn) => {
                        const answer = host.call('ui.floatingButton.add', options || {});
                        if (answer && typeof fn === 'function') {
                            const id = text((options || {}).id);
                            host.on('floatingButton', function (payload) { if (payload && payload.id === id) fn(); });
                        }
                        return !!answer;
                    },
                    remove: (id) => host.call('ui.floatingButton.remove', { id: text(id) })
                }),
                progress: Object.freeze({
                    show: (options) => host.call('ui.progress.show', options || {}),
                    hide: (id) => host.call('ui.progress.hide', { id: text(id) })
                }),
                animation: Object.freeze({ play: (name, seconds) => host.call('ui.animation.play', { name: text(name || 'confetti'), seconds: Number(seconds || 3) }) }),
                overlay: Object.freeze({
                    create: (options) => host.call('ui.overlay.create', options || {}),
                    update: (id, options) => host.call('ui.overlay.update', Object.assign({}, options || {}, { id: text(id) })),
                    addText: (options) => host.call('ui.overlay.addText', options || {}),
                    addClock: (options) => host.call('ui.overlay.addClock', options || {}),
                    showFPS: (options) => host.call('ui.overlay.showFPS', options || {}),
                    remove: (id) => host.call('ui.overlay.remove', { id: text(id) })
                }),
                font: Object.freeze({
                    set: (options) => host.call('ui.font.set', options || {}),
                    reset: (element) => host.call('ui.font.reset', { element: text(element) })
                }),
                badge: Object.freeze({
                    add: (options) => host.call('ui.badge.add', options || {}),
                    remove: (options) => host.call('ui.badge.remove', options || {})
                }),
                // Telegram's gift catalog: [{ giftId, title, stars, fileId, limited, remains, total, soldOut }].
                gifts: Object.freeze({
                    catalog: Object.freeze({
                        list: (fn) => new Promise((resolve) => {
                            request('ui.gifts.catalog.list', {}, (value) => {
                                const list = Array.isArray(value) ? value : [];
                                if (typeof fn === 'function') fn(list);
                                resolve(list);
                            });
                        })
                    })
                })
            }),
            registry: Object.freeze({
                developers: Object.freeze({
                    isVerified: (peerId) => !!(host.call('registry.isVerified', { peerId: text(peerId) }) || {}).verified,
                    info: (peerId) => host.call('registry.isVerified', { peerId: text(peerId) }) || {}
                })
            }),
            clipboard: Object.freeze({ write: (value) => host.call('clipboard.write', { text: text(value) }) }),
            device: Object.freeze({ info: () => host.call('device.info', {}) || {} }),
            haptics: Object.freeze({ play: (style) => host.call('haptics.play', { style: text(style || 'medium') }) }),
            secrets: Object.freeze({
                get: (key) => { const answer = host.call('secrets.get', { key: text(key) }); return answer && typeof answer.value === 'string' ? answer.value : null; },
                set: (key, value) => host.call('secrets.set', { key: text(key), value: value === null || value === undefined ? null : text(value) })
            }),
            net: Object.freeze({
                fetch: (url, init) => requestAsync('net.fetch', Object.assign({}, init || {}, { url: text(url) })).then(function (answer) {
                    return { status: answer.status, headers: answer.headers || {}, text: answer.text || '', json: function () { return JSON.parse(answer.text || 'null'); } };
                })
            }),
            messages: Object.freeze({
                send: (options) => requestAsync('messages.send', options),
                edit: (options) => requestAsync('messages.edit', options),
                react: (options) => requestAsync('messages.react', options),
                get: (options) => requestAsync('messages.get', options),
                bookmarks: Object.freeze({
                    list: () => { const answer = host.call('messages.bookmarks.list', {}); return (answer && answer.items) || []; },
                    add: (options) => host.call('messages.bookmarks.add', Object.assign({}, options || {}, { peerId: text((options || {}).peerId) })),
                    remove: (peerId, messageId) => host.call('messages.bookmarks.remove', { peerId: text(peerId), messageId: Number(messageId) })
                })
            }),
            profile: Object.freeze({
                notes: Object.freeze({
                    get: (peerId) => { const answer = host.call('profile.notes.get', { peerId: text(peerId) }); return answer && typeof answer.value === 'string' ? answer.value : null; },
                    set: (peerId, value) => host.call('profile.notes.set', { peerId: text(peerId), value: value === null || value === undefined ? null : text(value) })
                }),
                nickname: Object.freeze({
                    get: (peerId) => { const answer = host.call('profile.nickname.get', { peerId: text(peerId) }); return answer && typeof answer.value === 'string' ? answer.value : null; },
                    set: (peerId, value) => host.call('profile.nickname.set', { peerId: text(peerId), value: value === null || value === undefined ? null : text(value) })
                })
            }),
            media: Object.freeze({
                process: (data, ops, options) => requestAsync('media.process', Object.assign({}, options || {}, { data: text(data), ops: Array.isArray(ops) ? ops : [] })).then((answer) => answer.data),
                fromMessage: (peerId, messageId) => requestAsync('media.fromMessage', { peerId: text(peerId), messageId: Number(messageId) }),
                sendImage: (peerId, data, caption) => requestAsync('media.sendImage', { peerId: text(peerId), data: text(data), caption: text(caption) })
            }),
            tl: Object.freeze({
                block: (method) => host.call('tl.block', { method: text(method) }),
                unblock: (method) => host.call('tl.unblock', { method: text(method) }),
                onRequest: (fn) => {
                    if (typeof fn !== 'function' || !host.call('tl.observe', {})) return false;
                    host.on('tlRequest', function (payload) { fn(payload.method, payload.error); });
                    return true;
                },
                onUpdate: (fn) => {
                    if (typeof fn !== 'function' || !host.call('tl.observe', {})) return false;
                    host.on('tlUpdate', function (payload) { (payload.updates || []).forEach(function (name) { fn(name); }); });
                    return true;
                }
            }),
            gestures: Object.freeze({
                on: (type, fn) => {
                    if (typeof fn !== 'function') return;
                    host.on('gesture', function (payload) { if (payload && payload.type === type) fn(payload); });
                }
            }),
            chat: Object.freeze({
                scrollTo: (messageId) => host.call('chat.scrollTo', { messageId: Number(messageId) }),
                toolbar: Object.freeze({
                    add: (button, fn) => {
                        const ok = host.call('chat.toolbar.add', button || {});
                        if (ok && typeof fn === 'function') {
                            const id = text((button || {}).id);
                            host.on('chatToolbar', function (payload) { if (payload && payload.id === id) fn(payload.peerId); });
                        }
                        return !!ok;
                    },
                    remove: (id) => host.call('chat.toolbar.remove', { id: text(id) }),
                    filter: (options) => host.call('chat.toolbar.filter', options || {})
                }),
                filter: Object.freeze({ set: (options) => host.call('chat.filter.set', options || {}) })
            }),
            commands: Object.freeze({
                register: (name, description, fn) => {
                    if (typeof fn !== 'function') throw new TypeError('Command handler must be a function');
                    const answer = host.call('commands.register', { name: text(name), description: text(description) });
                    if (!answer || !answer.name) return false;
                    commandHandlers[answer.name] = fn;
                    installCommandHook();
                    return true;
                }
            }),
            bus: Object.freeze({
                emit: (topic, data) => host.call('bus.emit', { topic: text(topic), data: data === undefined ? null : data }),
                on: (topic, fn) => {
                    if (typeof fn !== 'function') return;
                    host.on('busMessage', function (payload) {
                        if (payload && payload.topic === topic && payload.from !== host.pluginId) fn(payload.data, payload.from);
                    });
                }
            }),
            i18n: Object.freeze({
                get language() { const answer = host.call('i18n.language', {}); return (answer && answer.language) || 'en'; },
                t: function (strings) {
                    const answer = host.call('i18n.language', {});
                    const language = (answer && answer.language) || 'en';
                    if (!strings) return '';
                    return strings[language] !== undefined ? strings[language] : (strings.en !== undefined ? strings.en : String(strings[Object.keys(strings)[0]] || ''));
                }
            }),
            ai: Object.freeze({
                complete: (prompt, options) => requestAsync('ai.complete', Object.assign({}, options || {}, { prompt: text(prompt) })).then((answer) => answer.text || '')
            }),
            screens: Object.freeze({ show: (screen) => host.call('screens.show', screen || {}) }),
            composer: Object.freeze({
                addButton: (button) => host.call('composer.addButton', button || {}),
                removeButton: (id) => host.call('composer.removeButton', { id: text(id) }),
                setText: (value) => host.call('composer.setText', { text: text(value) }),
                replaceSelection: (value) => host.call('composer.replaceSelection', { text: text(value) })
            }),
            scheduler: Object.freeze({
                daily: (time, fn) => {
                    const parts = String(time).split(':').map(Number);
                    const at = new Date();
                    at.setHours(parts[0] || 0, parts[1] || 0, parts[2] || 0, 0);
                    if (at.getTime() <= Date.now()) at.setDate(at.getDate() + 1);
                    const id = nextSchedule++;
                    arm(id, at.getTime(), fn, true);
                    return id;
                },
                at: (date, fn) => { const id = nextSchedule++; arm(id, typeof date === 'number' ? date : new Date(date).getTime(), fn, false); return id; },
                cancel: (id) => { if (schedules[id]) { clearTimeout(schedules[id]); delete schedules[id]; } }
            }),
            files: Object.freeze({ export: (name, value) => host.call('files.export', { name: text(name), text: text(value) }) }),
            permissions: Object.freeze({
                has: (name) => !!(host.call('permissions.has', { name: text(name) }) || {}).has,
                request: (names, fn) => requestAsync('permissions.request', { names: Array.isArray(names) ? names : [names] }).then(function (granted) { if (typeof fn === 'function') fn(!!granted); return !!granted; })
            }),
            player: Object.freeze({
                state: () => host.playerState() || {},
                control: (action) => host.playerControl(text(action)),
                play: () => host.playerControl('play'),
                pause: () => host.playerControl('pause'),
                next: () => host.playerControl('next'),
                previous: () => host.playerControl('previous'),
                spectrum: Object.freeze({
                    get: (bands) => host.call('player.spectrum.get', { bands: Number(bands || 32) }) || { bands: [], level: 0 },
                    subscribe: (fn, options) => {
                        if (typeof fn !== 'function') return false;
                        host.on('playerSpectrum', function (payload) { fn(payload.bands || [], payload.level || 0); });
                        return !!host.call('player.spectrum.subscribe', options || {});
                    },
                    unsubscribe: () => host.call('player.spectrum.unsubscribe', {})
                }),
                visualizer: Object.freeze({
                    set: (options) => host.call('player.visualizer.set', options || {}),
                    clear: () => host.call('player.visualizer.clear', {})
                }),
                canvas: Object.freeze({
                    draw: (shapes) => host.call('player.canvas.draw', { shapes: Array.isArray(shapes) ? shapes : [] }),
                    clear: () => host.call('player.canvas.clear', {})
                })
            }),
            features: Object.freeze({
                disable: (name) => host.feature(text(name), true),
                enable: (name) => host.feature(text(name), false)
            }),
            storage: Object.freeze({
                get: (key) => { const v = host.storageGet(text(key)); return v === undefined ? null : v; },
                set: (key, value) => host.storageSet(text(key), value === null || value === undefined ? null : text(value))
            })
        });
        root.ayu = ayu;
        root.setTimeout = (fn, ms) => host.setTimer(fn, Number(ms) || 0, false);
        root.setInterval = (fn, ms) => host.setTimer(fn, Number(ms) || 0, true);
        root.clearTimeout = (id) => host.clearTimer(Number(id) || 0);
        root.clearInterval = root.clearTimeout;
        root.console = Object.freeze({ log: ayu.log, info: ayu.log, warn: ayu.warn, error: ayu.error, debug: ayu.log });
        root.print = ayu.log;
        class BasePlugin { onLoad() {} onUnload() {} }
        let registered = null;
        root.wg = Object.freeze({
            BasePlugin: BasePlugin,
            on: ayu.on,
            log: ayu.log,
            toast: ayu.toast,
            getStorage: ayu.storage.get,
            setStorage: ayu.storage.set,
            registerPlugin: (plugin) => {
                if (!plugin || registered) throw new Error('Only one plugin may be registered');
                registered = plugin;
                if (typeof plugin.onLoad === 'function') plugin.onLoad();
                if (typeof plugin.onUnload === 'function') ayu.on('unload', () => plugin.onUnload());
            },
            hooks: ayu.hooks,
            features: ayu.features
        });
    })(globalThis);
    """
}
