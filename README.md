# Taskforce

A concise native SwiftUI task and project organizer for iPhone.

## What it includes

- Add tasks with notes, priority, due date, status, and an optional project
- Scan color-coded deadline urgency from overdue through upcoming
- Search, sort, and filter by status, priority, or project
- Edit, complete, change status, and delete tasks
- Review deadline, completion, and project-progress insights
- Keep tasks on-device with `UserDefaults`

## Open in Xcode

Open `TaskBoardiOS.xcodeproj`, select an iPhone simulator, and run the
`TaskBoardiOS` scheme.

## Quality checks

Run the complete local quality gate from the repository root:

```sh
sh scripts/verify.sh
```

This runs strict Swift formatting checks, the XCTest suite, core smoke checks,
and an unsigned iOS simulator build.

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
