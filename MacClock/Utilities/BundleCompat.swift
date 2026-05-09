// BundleCompat.swift
//
// Bridge so that code referencing `Bundle.module` continues to compile
// when the project is built via Xcode (`xcodebuild`) instead of Swift
// Package Manager.
//
// SPM auto-synthesises `Bundle.module` pointing at a generated resource
// bundle. Under Xcode, no such property exists — bundled resources live
// inside `Bundle.main` directly. This file provides that fallback.
//
// `SWIFT_PACKAGE` is defined automatically by SwiftPM. When the file is
// compiled outside SPM (e.g. via the `MacClock.xcodeproj` target) the
// extension below is active.

import Foundation

#if !SWIFT_PACKAGE
extension Foundation.Bundle {
    static var module: Bundle { .main }
}
#endif
