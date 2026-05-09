# MacClock — convenience targets.
#
# The Xcode project (`MacClock.xcodeproj`) is generated from `project.yml`
# via XcodeGen and is not checked in (it's in .gitignore). Run `make
# xcodeproj` after a fresh clone, or whenever `project.yml` changes, to
# (re)generate it.
#
# Prerequisites:
#   brew install xcodegen

.PHONY: xcodeproj test test-ui build clean

xcodeproj: project.yml
	xcodegen generate

build: xcodeproj
	xcodebuild -project MacClock.xcodeproj -scheme MacClock -destination 'platform=macOS' -configuration Debug build

test:
	swift test

test-ui: xcodeproj
	xcodebuild -project MacClock.xcodeproj -scheme MacClock -destination 'platform=macOS' -configuration Debug test

clean:
	rm -rf MacClock.xcodeproj
	swift package clean
