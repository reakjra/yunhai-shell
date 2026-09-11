#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qsize.h");
        type QSize = cxx_qt_lib::QSize;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        type ImageInfo = super::ImageInfoRust;
    }

    unsafe extern "RustQt" {
        #[qinvokable]
        fn dimensions(self: &ImageInfo, path: &QString) -> QSize;
    }
}

use cxx_qt_lib::{QSize, QString};

#[derive(Default)]
pub struct ImageInfoRust;

impl qobject::ImageInfo {
    fn dimensions(&self, path: &QString) -> QSize {
        let path = path.to_string();
        let path = path.strip_prefix("file://").unwrap_or(&path);
        imagesize::size(path)
            .map(|size| QSize::new(size.width as i32, size.height as i32))
            .unwrap_or_else(|_| QSize::new(0, 0))
    }
}
