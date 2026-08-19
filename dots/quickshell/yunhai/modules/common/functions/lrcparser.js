.pragma library

function parseLrc(text) {
    if (!text)
        return [];
    const lines = text.split("\n");
    const timeRegex = /\[(\d+):(\d+(?:\.\d+)?)\]/g;
    const result = [];
    for (const line of lines) {
        timeRegex.lastIndex = 0;
        const stamps = [];
        let m;
        while ((m = timeRegex.exec(line)) !== null)
            stamps.push(m);
        if (stamps.length === 0)
            continue;
        const lyric = line.replace(timeRegex, "").trim();
        for (const s of stamps)
            result.push({ time: parseInt(s[1]) * 60 + parseFloat(s[2]), text: lyric });
    }
    result.sort((a, b) => a.time - b.time);
    return result;
}
