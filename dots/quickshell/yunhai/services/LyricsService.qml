pragma Singleton
pragma ComponentBehavior: Bound

import "../modules/common/functions/lrcparser.js" as Lrc
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.services

Singleton {
    id: root

    readonly property var player: MprisController.activePlayer
    readonly property var track: MprisController.activeTrack

    readonly property bool enabled: Config.options.media.lyrics.enable
    readonly property bool allowOnline: Config.options.media.lyrics.online
    property real offset: Config.options.media.lyrics.offset

    readonly property string userAgent: "User-Agent: illogical-impulse-akebono (https://github.com/end-4/dots-hyprland)"

    readonly property alias model: lyricsModel
    readonly property bool hasLyrics: lyricsModel.count > 0
    property bool loading: false
    property bool instrumental: false
    property string source: ""
    property int currentIndex: -1
    property string currentLine: ""

    property string _key: ""
    property var _memo: ({})

    property var _consumers: new Set()
    property int _demand: 0
    readonly property bool wanted: root.enabled && root._demand > 0

    function setWant(obj, on) {
        if (on)
            root._consumers.add(obj);
        else
            root._consumers.delete(obj);
        root._demand = root._consumers.size;
    }

    ListModel { id: lyricsModel }

    Component.onCompleted: reload()
    onWantedChanged: reload()
    onCurrentIndexChanged: currentLine = (currentIndex >= 0 && currentIndex < lyricsModel.count) ? lyricsModel.get(currentIndex).lyricLine : ""

    Connections {
        target: MprisController
        function onActiveTrackChanged() { root.reload() }
    }

    Timer {
        interval: 250
        repeat: true
        running: root.wanted && root.hasLyrics && (root.player?.isPlaying ?? false)
        onTriggered: {
            root.player?.positionChanged();
            root._sync();
        }
    }

    function reload() {
        if (!root.wanted)
            return;
        const t = root.track;
        const key = _keyFor(t);
        if (key === root._key && (hasLyrics || instrumental || loading))
            return;
        root._key = key;
        _reset();
        if (!root.enabled || !t || !t.title)
            return;
        if (root._memo[key] !== undefined) {
            _applyMemo(root._memo[key]);
            return;
        }
        root.loading = true;
        _findLocal(t);
    }

    function refresh() {
        delete root._memo[root._key];
        root._key = "";
        reload();
    }

    function _reset() {
        lyricsModel.clear();
        currentIndex = -1;
        currentLine = "";
        instrumental = false;
        source = "";
        loading = false;
    }

    function _keyFor(t) {
        return ((t?.artist ?? "") + "" + (t?.title ?? "")).toLowerCase().trim();
    }
    function _shq(s) { return String(s ?? "").replace(/'/g, "'\\''"); }
    function _glob(s) { return String(s ?? "").replace(/[\[\]\*\?]/g, "").replace(/'/g, "'\\''").trim(); }

    function _apply(parsed, src, memo) {
        lyricsModel.clear();
        for (const l of parsed)
            lyricsModel.append({ time: l.time, lyricLine: l.text });
        root.source = src;
        root.instrumental = false;
        root.loading = false;
        root.currentIndex = -1;
        if (memo !== false)
            root._memo[root._key] = { parsed: parsed, src: src, instrumental: false };
        _sync();
    }

    function _applyMemo(entry) {
        if (entry.instrumental) {
            root.instrumental = true;
            root.source = entry.src;
            root.loading = false;
            return;
        }
        _apply(entry.parsed, entry.src, false);
    }

    function _markInstrumental(src) {
        root.instrumental = true;
        root.source = src;
        root.loading = false;
        root._memo[root._key] = { parsed: [], src: src, instrumental: true };
    }

    function _findLocal(t) {
        const a = _glob(t.artist);
        const b = _glob(t.title);
        if (!b) { _goOnline(); return; }
        localFindProc.forKey = root._key;
        localFindProc.command = ["bash", "-c",
            `find '${_shq(Directories.lyricsDir)}' -maxdepth 1 -type f -iname '*${a}*${b}*.lrc' 2>/dev/null | head -n1`];
        localFindProc.running = true;
    }

    function _readLocal(path) {
        localReadProc.forKey = root._key;
        localReadProc.command = ["cat", path];
        localReadProc.running = true;
    }

    function _goOnline() {
        if (!root.allowOnline) { root.loading = false; return; }
        const t = root.track;
        const dur = Math.round(root.player?.length ?? 0);
        let url = "https://lrclib.net/api/get?artist_name=" + encodeURIComponent(t.artist ?? "")
            + "&track_name=" + encodeURIComponent(t.title ?? "")
            + "&album_name=" + encodeURIComponent(t.album ?? "");
        if (dur > 0)
            url += "&duration=" + dur;
        getProc.forKey = root._key;
        getProc.command = ["curl", "-s", "--max-time", "10", "-H", root.userAgent, url];
        getProc.running = true;
    }

    function _search() {
        if (!root.allowOnline) { root.loading = false; return; }
        const t = root.track;
        const url = "https://lrclib.net/api/search?track_name=" + encodeURIComponent(t.title ?? "")
            + "&artist_name=" + encodeURIComponent(t.artist ?? "");
        searchProc.forKey = root._key;
        searchProc.command = ["curl", "-s", "--max-time", "10", "-H", root.userAgent, url];
        searchProc.running = true;
    }

    function _ingest(syncedText, src) {
        const parsed = Lrc.parseLrc(syncedText);
        if (parsed.length > 0) {
            _apply(parsed, src);
            return true;
        }
        return false;
    }

    function _sync() {
        const p = root.player;
        if (!p || lyricsModel.count === 0)
            return;
        const pos = (p.position ?? 0) - root.offset;
        let idx = -1;
        for (let i = lyricsModel.count - 1; i >= 0; i--) {
            if (pos >= lyricsModel.get(i).time - 0.1) { idx = i; break; }
        }
        if (idx !== root.currentIndex)
            root.currentIndex = idx;
    }

    function jumpTo(index) {
        if (index < 0 || index >= lyricsModel.count || !root.player)
            return;
        root.player.position = lyricsModel.get(index).time + root.offset + 0.01;
        root.currentIndex = index;
    }

    Process {
        id: localFindProc
        property string forKey: ""
        stdout: StdioCollector {
            onStreamFinished: {
                if (localFindProc.forKey !== root._key) return;
                const path = text.trim();
                if (path) root._readLocal(path);
                else root._goOnline();
            }
        }
    }

    Process {
        id: localReadProc
        property string forKey: ""
        stdout: StdioCollector {
            onStreamFinished: {
                if (localReadProc.forKey !== root._key) return;
                if (!root._ingest(text, "local"))
                    root._goOnline();
            }
        }
    }

    Process {
        id: getProc
        property string forKey: ""
        stdout: StdioCollector {
            onStreamFinished: {
                if (getProc.forKey !== root._key) return;
                let data = null;
                try { data = JSON.parse(text); } catch (e) {}
                if (data && data.instrumental) { root._markInstrumental("lrclib"); return; }
                if (data && data.syncedLyrics && root._ingest(data.syncedLyrics, "lrclib")) return;
                root._search();
            }
        }
    }

    Process {
        id: searchProc
        property string forKey: ""
        stdout: StdioCollector {
            onStreamFinished: {
                if (searchProc.forKey !== root._key) return;
                let arr = null;
                try { arr = JSON.parse(text); } catch (e) {}
                const hit = Array.isArray(arr) ? arr.find(x => x && x.syncedLyrics) : null;
                if (hit && root._ingest(hit.syncedLyrics, "lrclib")) return;
                root._apply([], "");
            }
        }
    }
}
