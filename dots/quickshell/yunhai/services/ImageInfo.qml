pragma Singleton

import Quickshell
import Yunhai as Native

Singleton {
    function dimensions(path: string): size {
        return Native.ImageInfo.dimensions(path);
    }
}
