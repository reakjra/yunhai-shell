import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Process {
    id: root

    signal done(string path, int width, int height);
    required property string filePath;
    required property string sourceUrl;
    property string fallbackUrl: ""

    function processFilePath() {
        return StringUtils.shellSingleQuoteEscape(FileUtils.trimFileProtocol(filePath));
    }

    property string curlFlags: `-fsSL --compressed -H 'Accept: */*' -A 'Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0'`
    running: true
    command: ["bash", "-c",
        `mkdir -p $(dirname '${processFilePath()}'); [ -f '${processFilePath()}' ] || curl ${curlFlags} '${sourceUrl}' -o '${processFilePath()}'${fallbackUrl ? ` || curl ${curlFlags} '${fallbackUrl}' -o '${processFilePath()}'` : ""}; [ -f '${processFilePath()}' ] && file '${processFilePath()}'`
    ]
    stdout: StdioCollector {
        id: outputCollector
        onStreamFinished: {
            const output = outputCollector.text.trim();
            if (output.length === 0) return
            const match = output.match(/(\d+)\s*x\s*(\d+)/);
            const width = match ? Number(match[1]) : 0;
            const height = match ? Number(match[2]) : 0;
            root.done(root.filePath, width, height);
        }
    }
}
