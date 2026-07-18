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

## Local model checks

The shared task model is also a Swift package so it can be checked without an
iOS simulator or full Xcode install:

```sh
swift run TaskBoardCoreSmokeTests
```
