// The JavaScript prelude VoidGram for iOS 27.6 runs before every JS plugin (from AyuScriptRuntime.swift).
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
        // Helpers behind the 27.6 utility namespaces.
        function hostValue(op, args) {
            const answer = host.call(op, args || {});
            return answer && typeof answer === 'object' && answer.value !== undefined ? answer.value : null;
        }
        const helpers = (function () {
            const ruLat = { 'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo', 'ж': 'zh', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm', 'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u', 'ф': 'f', 'х': 'kh', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'shch', 'ъ': '', 'ы': 'y', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya', 'і': 'i', 'ї': 'yi', 'є': 'ye', 'ґ': 'g' };
            const ruKeys = 'йцукенгшщзхъфывапролджэячсмитьбю.ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,';
            const enKeys = "qwertyuiop[]asdfghjkl;'zxcvbnm,./QWERTYUIOP{}ASDFGHJKL:\\"ZXCVBNM<>?";
            const layout = {};
            for (let i = 0; i < ruKeys.length; i++) { layout[ruKeys[i]] = enKeys[i]; if (layout[enKeys[i]] === undefined) layout[enKeys[i]] = ruKeys[i]; }
            function translit(s) {
                return Array.from(s).map((c) => {
                    const lower = c.toLowerCase(); const t = ruLat[lower];
                    if (t === undefined) return c;
                    return c === lower ? t : (t.charAt(0).toUpperCase() + t.slice(1));
                }).join('');
            }
            function plural(n, forms) {
                if (forms.length < 3) return forms[n === 1 ? 0 : 1] || forms[0] || '';
                const a = Math.abs(n) % 100; const b = a % 10;
                if (a > 10 && a < 20) return forms[2];
                if (b > 1 && b < 5) return forms[1];
                return b === 1 ? forms[0] : forms[2];
            }
            function toDate(value) { return value instanceof Date ? new Date(value.getTime()) : new Date(typeof value === 'number' ? value : (value === undefined ? Date.now() : String(value))); }
            function startOfDay(d) { const c = new Date(d.getTime()); c.setHours(0, 0, 0, 0); return c.getTime(); }
            function rgb(hex) {
                const m = /^#?([0-9a-f]{3}|[0-9a-f]{6})$/i.exec(String(hex || '').trim());
                if (!m) return null;
                const h = m[1].length === 3 ? m[1].split('').map((c) => c + c).join('') : m[1];
                return { r: parseInt(h.slice(0, 2), 16), g: parseInt(h.slice(2, 4), 16), b: parseInt(h.slice(4, 6), 16) };
            }
            function mixHex(a, b, t) {
                const x = rgb(a); const y = rgb(b); if (!x || !y) return null;
                const k = Math.max(0, Math.min(1, t));
                return '#' + ['r', 'g', 'b'].map((c) => Math.round(x[c] + (y[c] - x[c]) * k).toString(16).padStart(2, '0')).join('').toUpperCase();
            }
            function parseUrl(s) {
                const m = /^([a-z][a-z0-9+.-]*):\\/\\/([^\\/?#:]+)(?::(\\d+))?([^?#]*)(?:\\?([^#]*))?(?:#(.*))?$/i.exec(s.trim());
                if (!m) return null;
                const query = {};
                (m[5] || '').split('&').filter(Boolean).forEach((pair) => {
                    const i = pair.indexOf('='); const key = i < 0 ? pair : pair.slice(0, i); const v = i < 0 ? '' : pair.slice(i + 1);
                    try { query[decodeURIComponent(key.replace(/\\+/g, ' '))] = decodeURIComponent(v.replace(/\\+/g, ' ')); } catch (e) { query[key] = v; }
                });
                return { protocol: m[1].toLowerCase(), host: m[2].toLowerCase(), port: m[3] ? Number(m[3]) : null, path: m[4] || '/', query: query, hash: m[6] || '' };
            }
            function language() { const answer = host.call('i18n.language', {}); return (answer && answer.language) || 'en'; }
            return { translit: translit, layout: layout, plural: plural, toDate: toDate, startOfDay: startOfDay, rgb: rgb, mixHex: mixHex, parseUrl: parseUrl, language: language };
        })();
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
            clipboard: Object.freeze({
                write: (value) => host.call('clipboard.write', { text: text(value) }),
                read: () => requestAsync('clipboard.read', {}).then((answer) => answer && typeof answer.value === 'string' ? answer.value : null),
                hasText: () => requestAsync('clipboard.hasText', {}).then((answer) => !!(answer && answer.value)),
                clear: () => !!host.call('clipboard.clear', {})
            }),
            device: Object.freeze({
                info: () => host.call('device.info', {}) || {},
                battery: () => hostValue('device.battery', {}),
                isCharging: () => !!hostValue('device.isCharging', {}),
                screen: () => hostValue('device.screen', {}),
                darkMode: () => !!hostValue('device.darkMode', {}),
                model: () => hostValue('device.model', {}),
                systemVersion: () => hostValue('device.systemVersion', {}),
                timezone: () => hostValue('device.timezone', {}),
                isLowPower: () => !!hostValue('device.isLowPower', {}),
                freeDisk: () => hostValue('device.freeDisk', {}),
                memory: () => hostValue('device.memory', {}),
                uptime: () => hostValue('device.uptime', {}),
                thermalState: () => hostValue('device.thermalState', {})
            }),
            haptics: Object.freeze({
                play: (style) => host.call('haptics.play', { style: text(style || 'medium') }),
                pattern: (styles, interval) => !!host.call('haptics.pattern', { styles: (Array.isArray(styles) ? styles : [styles]).map(text), interval: Number(interval || 120) })
            }),
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
                sendImage: (peerId, data, caption) => requestAsync('media.sendImage', { peerId: text(peerId), data: text(data), caption: text(caption) }),
                cutOutSticker: (peerId, messageId) => requestAsync('media.cutOutSticker', { peerId: text(peerId), messageId: Number(messageId) }),
                describePhoto: (peerId, messageId) => requestAsync('media.describePhoto', { peerId: text(peerId), messageId: Number(messageId) }).then((answer) => (answer && answer.text) || null)
            }),
            tools: Object.freeze({
                chatStats: (peerId) => requestAsync('tools.chatStats', { peerId: text(peerId) }),
                yearInReview: (peerId) => requestAsync('tools.yearInReview', { peerId: text(peerId) }),
                downloadChatMedia: (peerId) => requestAsync('tools.downloadChatMedia', { peerId: text(peerId) })
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
            // 27.6: hashes, encodings, the app, speech, reminders, and helpers that run in the plugin.
            crypto: Object.freeze({
                sha256: (value) => hostValue('crypto.sha256', { text: text(value) }),
                sha1: (value) => hostValue('crypto.sha1', { text: text(value) }),
                sha512: (value) => hostValue('crypto.sha512', { text: text(value) }),
                md5: (value) => hostValue('crypto.md5', { text: text(value) }),
                hmac: (key, value) => hostValue('crypto.hmac', { key: text(key), text: text(value) }),
                randomBytes: (count) => hostValue('crypto.randomBytes', { count: Number(count || 16) }),
                uuid: () => hostValue('crypto.uuid', {})
            }),
            encoding: Object.freeze({
                base64Encode: (value) => hostValue('encoding.base64Encode', { text: text(value) }),
                base64Decode: (value) => hostValue('encoding.base64Decode', { text: text(value) }),
                hexEncode: (value) => hostValue('encoding.hexEncode', { text: text(value) }),
                hexDecode: (value) => hostValue('encoding.hexDecode', { text: text(value) })
            }),
            app: Object.freeze({
                version: () => hostValue('app.version', {}),
                build: () => hostValue('app.build', {}),
                name: () => hostValue('app.name', {}),
                plugins: () => hostValue('app.plugins', {}) || []
            }),
            speech: Object.freeze({
                speak: (value, options) => !!host.call('speech.speak', Object.assign({}, options || {}, { text: text(value) })),
                stop: () => !!host.call('speech.stop', {}),
                isSpeaking: () => !!hostValue('speech.isSpeaking', {}),
                voices: () => hostValue('speech.voices', {}) || []
            }),
            notify: Object.freeze({
                schedule: (options) => hostValue('notify.schedule', options || {}),
                cancel: (id) => !!host.call('notify.cancel', { id: text(id) }),
                cancelAll: () => !!host.call('notify.cancelAll', {})
            }),
            text: Object.freeze({
                capitalize: (value) => { const s = text(value); return s ? s.charAt(0).toUpperCase() + s.slice(1) : s; },
                titleCase: (value) => text(value).toLowerCase().replace(/(^|[\\s\\-«"(])(\\p{L})/gu, (m, p, c) => p + c.toUpperCase()),
                reverse: (value) => Array.from(text(value)).reverse().join(''),
                truncate: (value, length, ellipsis) => {
                    const chars = Array.from(text(value)); const max = Math.max(0, Number(length) || 0); const tail = ellipsis === undefined ? '…' : text(ellipsis);
                    return chars.length <= max ? chars.join('') : chars.slice(0, Math.max(0, max - Array.from(tail).length)).join('') + tail;
                },
                slugify: (value) => helpers.translit(text(value)).toLowerCase().normalize('NFKD').replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, ''),
                wordCount: (value) => (text(value).match(/[\\p{L}\\p{N}]+(?:['’-][\\p{L}\\p{N}]+)*/gu) || []).length,
                charCount: (value) => Array.from(text(value)).length,
                stripEmoji: (value) => text(value).replace(/(?:\\p{Extended_Pictographic}|\\p{Emoji_Modifier}|‍|️|[\\u{1F1E6}-\\u{1F1FF}])/gu, '').replace(/\\s{2,}/g, ' ').trim(),
                escapeHtml: (value) => text(value).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]),
                unescapeHtml: (value) => text(value).replace(/&(amp|lt|gt|quot|#39);/g, (m, e) => ({ amp: '&', lt: '<', gt: '>', quot: '"', '#39': "'" })[e]),
                translit: (value) => helpers.translit(text(value)),
                swapLayout: (value) => Array.from(text(value)).map((c) => helpers.layout[c] || c).join(''),
                mock: (value) => { let i = 0; return Array.from(text(value)).map((c) => /\\p{L}/u.test(c) ? ((i++ % 2) ? c.toUpperCase() : c.toLowerCase()) : c).join(''); },
                between: (value, start, end) => { const s = text(value); const a = s.indexOf(text(start)); if (a < 0) return null; const from = a + text(start).length; const b = end === undefined ? s.length : s.indexOf(text(end), from); return b < 0 ? null : s.slice(from, b); },
                template: (value, vars) => text(value).replace(/\\{(\\w+)\\}/g, (m, key) => vars && vars[key] !== undefined && vars[key] !== null ? String(vars[key]) : m),
                normalizeSpaces: (value) => text(value).replace(/[ \\t ]+/g, ' ').replace(/ *\\n */g, '\\n').replace(/\\n{3,}/g, '\\n\\n').trim(),
                removeUrls: (value) => text(value).replace(/\\b(?:https?:\\/\\/|www\\.|t\\.me\\/)[^\\s<>"']+/gi, '').replace(/[ \\t]{2,}/g, ' ').trim(),
                removeMentions: (value) => text(value).replace(/(^|[^\\w@])@[A-Za-z][A-Za-z0-9_]{3,31}\\b/g, '$1').replace(/[ \\t]{2,}/g, ' ').trim(),
                detectScript: (value) => { const s = text(value); const cyr = (s.match(/\\p{Script=Cyrillic}/gu) || []).length; const lat = (s.match(/\\p{Script=Latin}/gu) || []).length; return cyr && lat ? 'mixed' : (cyr ? 'cyrillic' : (lat ? 'latin' : 'other')); },
                wrap: (value, width) => { const max = Math.max(1, Number(width) || 40); return text(value).split('\\n').map((line) => { const out = []; let cur = ''; line.split(' ').forEach((word) => { if (cur && Array.from(cur + ' ' + word).length > max) { out.push(cur); cur = word; } else cur = cur ? cur + ' ' + word : word; }); out.push(cur); return out.join('\\n'); }).join('\\n'); },
                occurrences: (value, part) => { const s = text(value); const p = text(part); if (!p) return 0; let n = 0; let i = s.indexOf(p); while (i >= 0) { n++; i = s.indexOf(p, i + p.length); } return n; },
                randomString: (length, alphabet) => { const chars = Array.from(text(alphabet || 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')); let out = ''; for (let i = 0; i < Math.min(10000, Math.max(0, Number(length) || 8)); i++) out += chars[Math.floor(Math.random() * chars.length)]; return out; },
                isEmojiOnly: (value) => { const s = text(value).replace(/\\s/g, ''); return !!s && /^(?:\\p{Extended_Pictographic}|\\p{Emoji_Modifier}|‍|️|[\\u{1F1E6}-\\u{1F1FF}])+$/u.test(s); },
                firstLine: (value) => text(value).split('\\n')[0]
            }),
            date: Object.freeze({
                format: (value, pattern) => {
                    const d = helpers.toDate(value); const p = (n, w) => String(n).padStart(w || 2, '0');
                    const map = { YYYY: d.getFullYear(), YY: p(d.getFullYear() % 100), MM: p(d.getMonth() + 1), DD: p(d.getDate()), HH: p(d.getHours()), mm: p(d.getMinutes()), ss: p(d.getSeconds()) };
                    return text(pattern || 'YYYY-MM-DD HH:mm').replace(/YYYY|YY|MM|DD|HH|mm|ss/g, (t) => String(map[t]));
                },
                relative: (value, language) => {
                    const ru = text(language || helpers.language()).startsWith('ru') || text(language || helpers.language()).startsWith('uk');
                    const seconds = Math.round((helpers.toDate(value).getTime() - Date.now()) / 1000); const past = seconds <= 0; const abs = Math.abs(seconds);
                    const units = [[60, 'second', ['секунду', 'секунды', 'секунд']], [60, 'minute', ['минуту', 'минуты', 'минут']], [24, 'hour', ['час', 'часа', 'часов']], [30, 'day', ['день', 'дня', 'дней']], [12, 'month', ['месяц', 'месяца', 'месяцев']], [Infinity, 'year', ['год', 'года', 'лет']]];
                    let amount = abs; let i = 0;
                    while (i < units.length - 1 && amount >= units[i][0]) { amount = Math.floor(amount / units[i][0]); i++; }
                    if (abs < 10) return ru ? 'только что' : 'just now';
                    const word = ru ? helpers.plural(amount, units[i][2]) : units[i][1] + (amount === 1 ? '' : 's');
                    return ru ? (past ? amount + ' ' + word + ' назад' : 'через ' + amount + ' ' + word) : (past ? amount + ' ' + word + ' ago' : 'in ' + amount + ' ' + word);
                },
                addDays: (value, days) => { const d = helpers.toDate(value); d.setDate(d.getDate() + Number(days || 0)); return d; },
                diffDays: (a, b) => Math.round((helpers.startOfDay(helpers.toDate(b === undefined ? Date.now() : b)) - helpers.startOfDay(helpers.toDate(a))) / 86400000),
                isToday: (value) => helpers.startOfDay(helpers.toDate(value)) === helpers.startOfDay(new Date()),
                startOfDay: (value) => new Date(helpers.startOfDay(helpers.toDate(value === undefined ? Date.now() : value))),
                parseDuration: (value) => {
                    const s = text(value).trim().toLowerCase(); const sizes = { ms: 1, s: 1000, m: 60000, h: 3600000, d: 86400000, w: 604800000 };
                    let total = 0; let matched = false;
                    s.replace(/(\\d+(?:\\.\\d+)?)\\s*(ms|s|m|h|d|w)/g, (m, n, unit) => { matched = true; total += Number(n) * sizes[unit]; return m; });
                    return matched ? total : (/^\\d+$/.test(s) ? Number(s) * 1000 : null);
                },
                formatDuration: (ms, language) => {
                    const ru = text(language || helpers.language()).startsWith('ru') || text(language || helpers.language()).startsWith('uk');
                    let left = Math.max(0, Math.round(Number(ms || 0) / 1000)); const parts = [];
                    for (const [size, en, short] of [[86400, 'd', 'д'], [3600, 'h', 'ч'], [60, 'm', 'мин'], [1, 's', 'с']]) {
                        const n = Math.floor(left / size); left -= n * size; if (n) parts.push(n + (ru ? ' ' + short : en));
                    }
                    return parts.length ? parts.join(' ') : (ru ? '0 с' : '0s');
                },
                weekday: (value, language) => { const ru = text(language || helpers.language()).startsWith('ru') || text(language || helpers.language()).startsWith('uk'); const names = ru ? ['воскресенье', 'понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота'] : ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']; return names[helpers.toDate(value).getDay()]; },
                monthName: (value, language) => { const ru = text(language || helpers.language()).startsWith('ru') || text(language || helpers.language()).startsWith('uk'); const names = ru ? ['январь', 'февраль', 'март', 'апрель', 'май', 'июнь', 'июль', 'август', 'сентябрь', 'октябрь', 'ноябрь', 'декабрь'] : ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']; return names[helpers.toDate(value).getMonth()]; },
                isWeekend: (value) => { const d = helpers.toDate(value).getDay(); return d === 0 || d === 6; },
                daysInMonth: (value) => { const d = helpers.toDate(value); return new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate(); },
                age: (birth, at) => { const b = helpers.toDate(birth); const now = helpers.toDate(at === undefined ? Date.now() : at); let years = now.getFullYear() - b.getFullYear(); if (now.getMonth() < b.getMonth() || (now.getMonth() === b.getMonth() && now.getDate() < b.getDate())) years--; return years; },
                unix: (value) => Math.floor(helpers.toDate(value === undefined ? Date.now() : value).getTime() / 1000),
                fromUnix: (seconds) => new Date(Number(seconds) * 1000),
                countdown: (target) => { let ms = Math.max(0, helpers.toDate(target).getTime() - Date.now()); const days = Math.floor(ms / 86400000); ms -= days * 86400000; const hours = Math.floor(ms / 3600000); ms -= hours * 3600000; const minutes = Math.floor(ms / 60000); ms -= minutes * 60000; return { days: days, hours: hours, minutes: minutes, seconds: Math.floor(ms / 1000) }; }
            }),
            color: Object.freeze({
                hexToRgb: (hex) => helpers.rgb(hex),
                rgbToHex: (r, g, b) => '#' + [r, g, b].map((v) => Math.max(0, Math.min(255, Math.round(Number(v) || 0))).toString(16).padStart(2, '0')).join('').toUpperCase(),
                lighten: (hex, amount) => helpers.mixHex(hex, '#FFFFFF', amount === undefined ? 0.2 : Number(amount)),
                darken: (hex, amount) => helpers.mixHex(hex, '#000000', amount === undefined ? 0.2 : Number(amount)),
                mix: (a, b, amount) => helpers.mixHex(a, b, amount === undefined ? 0.5 : Number(amount)),
                contrastText: (hex) => { const c = helpers.rgb(hex); if (!c) return '#000000'; const lum = (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) / 255; return lum > 0.55 ? '#000000' : '#FFFFFF'; },
                random: () => '#' + Math.floor(Math.random() * 0x1000000).toString(16).padStart(6, '0').toUpperCase(),
                toHsl: (hex) => { const c = helpers.rgb(hex); if (!c) return null; const r = c.r / 255; const g = c.g / 255; const b = c.b / 255; const max = Math.max(r, g, b); const min = Math.min(r, g, b); const l = (max + min) / 2; let h = 0; let s = 0; if (max !== min) { const d = max - min; s = l > 0.5 ? d / (2 - max - min) : d / (max + min); h = max === r ? (g - b) / d + (g < b ? 6 : 0) : (max === g ? (b - r) / d + 2 : (r - g) / d + 4); h *= 60; } return { h: Math.round(h), s: Math.round(s * 100), l: Math.round(l * 100) }; },
                fromHsl: (h, s, l) => { const sat = Math.max(0, Math.min(100, Number(s))) / 100; const lig = Math.max(0, Math.min(100, Number(l))) / 100; const k = (n) => (n + Number(h) / 30) % 12; const a = sat * Math.min(lig, 1 - lig); const f = (n) => lig - a * Math.max(-1, Math.min(k(n) - 3, Math.min(9 - k(n), 1))); return '#' + [f(0), f(8), f(4)].map((v) => Math.round(v * 255).toString(16).padStart(2, '0')).join('').toUpperCase(); },
                invert: (hex) => { const c = helpers.rgb(hex); return c ? '#' + [255 - c.r, 255 - c.g, 255 - c.b].map((v) => v.toString(16).padStart(2, '0')).join('').toUpperCase() : null; },
                grayscale: (hex) => { const c = helpers.rgb(hex); if (!c) return null; const y = Math.round(0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b).toString(16).padStart(2, '0'); return ('#' + y + y + y).toUpperCase(); },
                rgba: (hex, alpha) => { const c = helpers.rgb(hex); return c ? 'rgba(' + c.r + ', ' + c.g + ', ' + c.b + ', ' + Math.max(0, Math.min(1, Number(alpha === undefined ? 1 : alpha))) + ')' : null; }
            }),
            math: Object.freeze({
                clamp: (value, min, max) => Math.min(Number(max), Math.max(Number(min), Number(value))),
                lerp: (a, b, t) => Number(a) + (Number(b) - Number(a)) * Number(t),
                random: (min, max) => Number(min || 0) + Math.random() * (Number(max === undefined ? 1 : max) - Number(min || 0)),
                randomInt: (min, max) => { const lo = Math.ceil(Number(min)); const hi = Math.floor(Number(max)); return lo + Math.floor(Math.random() * (hi - lo + 1)); },
                round: (value, digits) => { const f = Math.pow(10, Number(digits || 0)); return Math.round(Number(value) * f) / f; },
                sum: (list) => (Array.isArray(list) ? list : []).reduce((a, b) => a + (Number(b) || 0), 0),
                average: (list) => { const l = Array.isArray(list) ? list : []; return l.length ? l.reduce((a, b) => a + (Number(b) || 0), 0) / l.length : 0; },
                median: (list) => { const l = (Array.isArray(list) ? list : []).map(Number).filter((n) => !isNaN(n)).sort((a, b) => a - b); if (!l.length) return 0; const m = Math.floor(l.length / 2); return l.length % 2 ? l[m] : (l[m - 1] + l[m]) / 2; },
                percent: (part, total) => Number(total) ? Number(part) / Number(total) * 100 : 0,
                factorial: (n) => { let r = 1; for (let i = 2; i <= Math.min(170, Math.floor(Number(n) || 0)); i++) r *= i; return r; },
                gcd: (a, b) => { let x = Math.abs(Math.round(Number(a))); let y = Math.abs(Math.round(Number(b))); while (y) { const t = y; y = x % y; x = t; } return x; },
                lcm: (a, b) => { const x = Math.abs(Math.round(Number(a))); const y = Math.abs(Math.round(Number(b))); if (!x || !y) return 0; let g = x; let h = y; while (h) { const t = h; h = g % h; g = t; } return x / g * y; },
                isPrime: (n) => { const x = Math.floor(Number(n)); if (!(x >= 2) || x > 1e12) return x > 1e12 ? null : false; if (x % 2 === 0) return x === 2; for (let i = 3; i * i <= x; i += 2) if (x % i === 0) return false; return true; },
                fibonacci: (n) => { let a = 0; let b = 1; for (let i = 0; i < Math.min(1476, Math.floor(Number(n) || 0)); i++) { const t = a + b; a = b; b = t; } return a; },
                mod: (a, b) => ((Number(a) % Number(b)) + Number(b)) % Number(b),
                roundTo: (value, step) => { const s = Number(step) || 1; return Math.round(Number(value) / s) * s; },
                range: (start, end, step) => { const s = Number(step) || 1; const out = []; if (end === undefined) { end = start; start = 0; } for (let i = Number(start); s > 0 ? i < Number(end) : i > Number(end); i += s) { out.push(i); if (out.length >= 100000) break; } return out; }
            }),
            url: Object.freeze({
                parse: (value) => helpers.parseUrl(text(value)),
                build: (base, params) => {
                    const query = Object.keys(params || {}).filter((k) => params[k] !== undefined && params[k] !== null).map((k) => encodeURIComponent(k) + '=' + encodeURIComponent(String(params[k]))).join('&');
                    const s = text(base); return query ? s + (s.indexOf('?') < 0 ? '?' : (/[?&]$/.test(s) ? '' : '&')) + query : s;
                },
                param: (value, name) => { const parsed = helpers.parseUrl(text(value)); return parsed && Object.prototype.hasOwnProperty.call(parsed.query, text(name)) ? parsed.query[text(name)] : null; },
                isUrl: (value) => /^(https?|tg):\\/\\/[^\\s]+$/i.test(text(value).trim()),
                extract: (value) => text(value).match(/\\b(?:https?:\\/\\/|www\\.|t\\.me\\/)[^\\s<>"']+[^\\s<>"'.,;:!?)\\]]/gi) || [],
                domain: (value) => { const parsed = helpers.parseUrl(text(value)); return parsed ? parsed.host.replace(/^www\\./, '') : null; }
            }),
            array: Object.freeze({
                chunk: (list, size) => { const l = Array.isArray(list) ? list : []; const n = Math.max(1, Number(size) || 1); const out = []; for (let i = 0; i < l.length; i += n) out.push(l.slice(i, i + n)); return out; },
                unique: (list, key) => { const seen = new Set(); return (Array.isArray(list) ? list : []).filter((item) => { const k = typeof key === 'function' ? key(item) : (key ? item && item[key] : item); if (seen.has(k)) return false; seen.add(k); return true; }); },
                shuffle: (list) => { const l = (Array.isArray(list) ? list : []).slice(); for (let i = l.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); const t = l[i]; l[i] = l[j]; l[j] = t; } return l; },
                sample: (list) => { const l = Array.isArray(list) ? list : []; return l.length ? l[Math.floor(Math.random() * l.length)] : null; },
                groupBy: (list, key) => (Array.isArray(list) ? list : []).reduce((groups, item) => { const k = String(typeof key === 'function' ? key(item) : item && item[key]); (groups[k] = groups[k] || []).push(item); return groups; }, {}),
                sortBy: (list, key, descending) => (Array.isArray(list) ? list : []).slice().sort((a, b) => { const x = typeof key === 'function' ? key(a) : a && a[key]; const y = typeof key === 'function' ? key(b) : b && b[key]; const r = x < y ? -1 : (x > y ? 1 : 0); return descending ? -r : r; }),
                flatten: (list, depth) => (Array.isArray(list) ? list : []).flat(depth === undefined ? Infinity : Number(depth)),
                zip: function () { const lists = Array.prototype.map.call(arguments, (l) => Array.isArray(l) ? l : []); const n = lists.length ? Math.min.apply(null, lists.map((l) => l.length)) : 0; const out = []; for (let i = 0; i < n; i++) out.push(lists.map((l) => l[i])); return out; },
                countBy: (list, key) => (Array.isArray(list) ? list : []).reduce((counts, item) => { const k = String(typeof key === 'function' ? key(item) : (key ? item && item[key] : item)); counts[k] = (counts[k] || 0) + 1; return counts; }, {}),
                partition: (list, fn) => { const yes = []; const no = []; (Array.isArray(list) ? list : []).forEach((item) => (fn(item) ? yes : no).push(item)); return [yes, no]; },
                last: (list) => { const l = Array.isArray(list) ? list : []; return l.length ? l[l.length - 1] : null; },
                compact: (list) => (Array.isArray(list) ? list : []).filter((item) => item !== null && item !== undefined && item !== false && item !== '' && !(typeof item === 'number' && isNaN(item))),
                intersect: (a, b) => { const set = new Set(Array.isArray(b) ? b : []); return (Array.isArray(a) ? a : []).filter((item) => set.has(item)); },
                difference: (a, b) => { const set = new Set(Array.isArray(b) ? b : []); return (Array.isArray(a) ? a : []).filter((item) => !set.has(item)); }
            }),
            async: Object.freeze({
                sleep: (ms) => new Promise((resolve) => root.setTimeout(resolve, Number(ms) || 0)),
                debounce: (fn, ms) => { let timer = null; return function () { const args = arguments; if (timer !== null) root.clearTimeout(timer); timer = root.setTimeout(() => { timer = null; fn.apply(null, args); }, Number(ms) || 0); }; },
                throttle: (fn, ms) => { let last = 0; return function () { const now = Date.now(); if (now - last >= (Number(ms) || 0)) { last = now; return fn.apply(null, arguments); } }; },
                retry: (fn, times, delay) => new Promise((resolve, reject) => {
                    let left = Math.min(20, Math.max(1, Number(times) || 3));
                    const attempt = () => Promise.resolve().then(fn).then(resolve, (error) => { if (--left <= 0) reject(error); else root.setTimeout(attempt, Number(delay) || 0); });
                    attempt();
                }),
                timeout: (promise, ms) => new Promise((resolve, reject) => {
                    const timer = root.setTimeout(() => reject(new Error('Timed out after ' + ms + ' ms')), Number(ms) || 0);
                    Promise.resolve(promise).then((v) => { root.clearTimeout(timer); resolve(v); }, (e) => { root.clearTimeout(timer); reject(e); });
                })
            }),
            format: Object.freeze({
                bytes: (value, digits) => { let n = Math.max(0, Number(value) || 0); const units = ['B', 'KB', 'MB', 'GB', 'TB']; let i = 0; while (n >= 1024 && i < units.length - 1) { n /= 1024; i++; } return (i ? n.toFixed(digits === undefined ? 1 : Number(digits)) : String(Math.round(n))) + ' ' + units[i]; },
                number: (value, digits) => { const n = Number(value) || 0; const fixed = digits === undefined ? String(Math.round(n * 100) / 100) : n.toFixed(Number(digits)); const parts = fixed.split('.'); parts[0] = parts[0].replace(/\\B(?=(\\d{3})+(?!\\d))/g, ' '); return parts.join(','); },
                plural: (count, forms) => helpers.plural(Number(count) || 0, Array.isArray(forms) ? forms : [])
            }),
            extract: Object.freeze({
                mentions: (value) => (text(value).match(/(?:^|[^\\w@])@([A-Za-z][A-Za-z0-9_]{3,31})\\b/g) || []).map((m) => m.replace(/^[^@]*@/, '@')),
                hashtags: (value) => (text(value).match(/#[\\p{L}\\p{N}_]+/gu) || []),
                emails: (value) => (text(value).match(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}/g) || [])
            }),
            object: Object.freeze({
                pick: (value, keys) => { const out = {}; (Array.isArray(keys) ? keys : []).forEach((k) => { if (value && Object.prototype.hasOwnProperty.call(value, k)) out[k] = value[k]; }); return out; },
                omit: (value, keys) => { const drop = new Set(Array.isArray(keys) ? keys : []); const out = {}; Object.keys(value || {}).forEach((k) => { if (!drop.has(k)) out[k] = value[k]; }); return out; },
                merge: function merge(target, source) { const out = Object.assign({}, target || {}); Object.keys(source || {}).forEach((k) => { const a = out[k]; const b = source[k]; out[k] = a && b && typeof a === 'object' && typeof b === 'object' && !Array.isArray(a) && !Array.isArray(b) ? merge(a, b) : b; }); return out; },
                get: (value, path, fallback) => { let cur = value; for (const part of text(path).split('.').filter(Boolean)) { if (cur === null || cur === undefined) break; cur = cur[part]; } return cur === undefined ? (fallback === undefined ? null : fallback) : cur; },
                set: (value, path, item) => { const parts = text(path).split('.').filter(Boolean); const root = value && typeof value === 'object' ? value : {}; let cur = root; parts.forEach((part, i) => { if (i === parts.length - 1) cur[part] = item; else { if (!cur[part] || typeof cur[part] !== 'object') cur[part] = {}; cur = cur[part]; } }); return root; }
            }),
            validate: Object.freeze({
                email: (value) => /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$/.test(text(value).trim()),
                phone: (value) => { const digits = text(value).replace(/[\\s()\\-.]/g, ''); return /^\\+?\\d{7,15}$/.test(digits); },
                username: (value) => /^@?[A-Za-z](?!.*__)[A-Za-z0-9_]{3,30}[A-Za-z0-9]$/.test(text(value).trim()),
                hexColor: (value) => /^#?(?:[0-9a-f]{3}|[0-9a-f]{6})$/i.test(text(value).trim())
            }),
            storage: Object.freeze({
                get: (key) => { const v = host.storageGet(text(key)); return v === undefined ? null : v; },
                set: (key, value) => host.storageSet(text(key), value === null || value === undefined ? null : text(value)),
                remove: (key) => host.storageSet(text(key), null),
                has: (key) => { const v = host.storageGet(text(key)); return v !== undefined && v !== null; },
                getJSON: (key, fallback) => { const v = host.storageGet(text(key)); if (v === undefined || v === null) return fallback === undefined ? null : fallback; try { return JSON.parse(v); } catch (e) { return fallback === undefined ? null : fallback; } },
                setJSON: (key, value) => host.storageSet(text(key), value === undefined ? null : JSON.stringify(value)),
                increment: (key, by) => { const v = Number(host.storageGet(text(key))) || 0; const next = v + (by === undefined ? 1 : Number(by) || 0); host.storageSet(text(key), String(next)); return next; }
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
