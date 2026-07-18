# TaskBoard iOS

Native SwiftUI version of the task tracker.

## What it includes

- Add tasks with notes, priority, and due date
- Search and filter by status or priority
- Edit task details after creation
- Mark tasks done, change status, and delete tasks
- Summary counts for open, done, overdue, and total tasks
- On-device persistence with `UserDefaults`

## Open in Xcode

Open `TaskBoardiOS.xcodeproj`, select an iPhone simulator, and run the
`TaskBoardiOS` scheme.

## Quality checks

Run the complete local quality gate from the `TaskBoardiOS` directory:

```sh
sh scripts/verify.sh
```

It runs Apple `swift-format` in strict lint mode, executes the XCTest suite,
runs the lightweight core smoke checks, and compiles the iOS app for the
simulator without code signing.

Run individual checks when iterating:

```sh
swift test
swift run TaskBoardCoreSmokeTests
xcrun swift-format lint --strict --recursive \
  TaskBoardCore TaskBoardCoreTests TaskBoardCoreSmokeTests TaskBoardiOS
```

Apply the configured formatter with:

```sh
sh scripts/format.sh
```
