import Foundation
import TaskBoardCore

let referenceDate = Date(timeIntervalSince1970: 1_720_000_000)

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
  if !condition() {
    fputs("FAIL: \(message)\n", stderr)
    exit(1)
  }
}

func testStatsCountsOpenDoneAndOverdueTasks() {
  let tasks = [
    TaskItem(
      title: "Overdue",
      status: .todo,
      dueDate: TaskBoardLogic.dateOffset(-1, from: referenceDate)
    ),
    TaskItem(
      title: "Doing",
      status: .doing,
      dueDate: TaskBoardLogic.dateOffset(1, from: referenceDate)
    ),
    TaskItem(
      title: "Done",
      status: .done,
      dueDate: TaskBoardLogic.dateOffset(-2, from: referenceDate)
    ),
  ]

  let stats = TaskBoardLogic.stats(for: tasks, referenceDate: referenceDate)

  expect(stats.total == 3, "counts total tasks")
  expect(stats.open == 2, "counts open tasks")
  expect(stats.done == 1, "counts done tasks")
  expect(stats.overdue == 1, "counts overdue tasks")
}

func testFilteringMatchesSearchStatusAndPriority() {
  let tasks = [
    TaskItem(title: "Review launch plan", notes: "Backend notes", status: .doing, priority: .high),
    TaskItem(title: "Pay invoices", notes: "", status: .todo, priority: .low),
    TaskItem(title: "Archive notes", notes: "Launch cleanup", status: .done, priority: .medium),
  ]

  let filtered = TaskBoardLogic.filteredTasks(
    tasks,
    query: "launch",
    status: .doing,
    priority: .high
  )

  expect(filtered.map(\.title) == ["Review launch plan"], "filters by query, status, and priority")
}

func testDoneTasksSortAfterOpenTasks() {
  let done = TaskItem(
    title: "Done first",
    status: .done,
    dueDate: TaskBoardLogic.dateOffset(-10, from: referenceDate)
  )
  let open = TaskItem(
    title: "Open later",
    status: .todo,
    dueDate: TaskBoardLogic.dateOffset(10, from: referenceDate)
  )

  let filtered = TaskBoardLogic.filteredTasks(
    [done, open],
    query: "",
    status: nil,
    priority: nil
  )

  expect(filtered.map(\.title) == ["Open later", "Done first"], "sorts done tasks after open tasks")
}

func testTaskTitlesAndNotesAreTrimmed() {
  let task = TaskItem(title: "  Trim me  ", notes: "  Notes  ")

  expect(task.title == "Trim me", "trims task titles")
  expect(task.notes == "Notes", "trims task notes")
}

func testCodableRoundTripPreservesEditableFields() {
  let original = TaskItem(
    title: "Round trip",
    notes: "Keep details",
    status: .doing,
    priority: .high,
    dueDate: TaskBoardLogic.dateOffset(5, from: referenceDate),
    createdAt: referenceDate
  )
  let encoder = JSONEncoder()
  let decoder = JSONDecoder()

  guard
    let data = try? encoder.encode(original),
    let decoded = try? decoder.decode(TaskItem.self, from: data)
  else {
    expect(false, "encodes and decodes task data")
    return
  }

  expect(decoded == original, "preserves task fields through encoding")
}

func testDateOffsetUsesStartOfDay() {
  let calendar = Calendar(identifier: .gregorian)
  let date = Date(timeIntervalSince1970: 1_720_055_321)
  let result = TaskBoardLogic.dateOffset(2, from: date, calendar: calendar)
  let components = calendar.dateComponents([.hour, .minute, .second], from: result)

  expect(components.hour == 0, "date offset starts at midnight hour")
  expect(components.minute == 0, "date offset starts at midnight minute")
  expect(components.second == 0, "date offset starts at midnight second")
}

func testReplacingTaskUpdatesMatchingTaskOnly() {
  let first = TaskItem(title: "First", priority: .low)
  let second = TaskItem(title: "Second", priority: .medium)
  var updatedFirst = first
  updatedFirst.title = "Updated first"
  updatedFirst.priority = .high

  let result = TaskBoardLogic.replacingTask(updatedFirst, in: [first, second])

  expect(result.count == 2, "keeps task count when replacing")
  expect(result[0].title == "Updated first", "replaces matching task title")
  expect(result[0].priority == .high, "replaces matching task priority")
  expect(result[1] == second, "leaves non-matching task unchanged")
}

func testOptionalProjectAssignmentRoundTrips() {
  let project = ProjectItem(name: "Launch", color: .purple)
  let task = TaskItem(title: "Prepare release", projectID: project.id)
  let encoder = JSONEncoder()
  let decoder = JSONDecoder()

  guard
    let projectData = try? encoder.encode(project),
    let taskData = try? encoder.encode(task),
    let decodedProject = try? decoder.decode(ProjectItem.self, from: projectData),
    let decodedTask = try? decoder.decode(TaskItem.self, from: taskData)
  else {
    expect(false, "encodes and decodes project assignments")
    return
  }

  expect(decodedProject == project, "preserves project details")
  expect(decodedTask.projectID == project.id, "preserves optional task project assignment")
}

testStatsCountsOpenDoneAndOverdueTasks()
testFilteringMatchesSearchStatusAndPriority()
testDoneTasksSortAfterOpenTasks()
testTaskTitlesAndNotesAreTrimmed()
testCodableRoundTripPreservesEditableFields()
testDateOffsetUsesStartOfDay()
testReplacingTaskUpdatesMatchingTaskOnly()
testOptionalProjectAssignmentRoundTrips()

print("TaskBoardCoreSmokeTests passed")
