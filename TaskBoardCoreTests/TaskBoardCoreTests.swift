import Foundation
import XCTest

@testable import TaskBoardCore

final class TaskBoardCoreTests: XCTestCase {
  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }

  private func date(
    _ day: Int,
    year: Int = 2026,
    month: Int = 7,
    hour: Int = 12
  ) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
  }

  func testTaskAndProjectNamesAreTrimmed() {
    let task = TaskItem(title: "  Plan launch  ", notes: "  Include QA  ")
    let project = ProjectItem(name: "  Work  ", color: .purple)

    XCTAssertEqual(task.title, "Plan launch")
    XCTAssertEqual(task.notes, "Include QA")
    XCTAssertEqual(project.name, "Work")
  }

  func testOverdueUsesCalendarDaysAndIgnoresCompletedTasks() {
    let referenceDate = date(18, hour: 16)
    let yesterday = TaskItem(title: "Yesterday", dueDate: date(17))
    let today = TaskItem(title: "Today", dueDate: date(18, hour: 1))
    let completed = TaskItem(title: "Completed", status: .done, dueDate: date(16))

    XCTAssertTrue(yesterday.isOverdue(referenceDate: referenceDate, calendar: calendar))
    XCTAssertFalse(today.isOverdue(referenceDate: referenceDate, calendar: calendar))
    XCTAssertFalse(completed.isOverdue(referenceDate: referenceDate, calendar: calendar))
  }

  func testStatsCountOpenDoneAndOverdueTasks() {
    let referenceDate = date(18)
    let tasks = [
      TaskItem(title: "Late", status: .todo, dueDate: date(17)),
      TaskItem(title: "Active", status: .doing, dueDate: date(19)),
      TaskItem(title: "Complete", status: .done, dueDate: date(16)),
    ]

    let stats = TaskBoardLogic.stats(
      for: tasks,
      referenceDate: referenceDate,
      calendar: calendar
    )

    XCTAssertEqual(stats, TaskStats(total: 3, open: 2, done: 1, overdue: 1))
  }

  func testFilteringSearchesTitlesAndNotesCaseInsensitively() {
    let tasks = [
      TaskItem(title: "Review LAUNCH plan", notes: ""),
      TaskItem(title: "Prepare notes", notes: "Launch checklist"),
      TaskItem(title: "Pay invoice", notes: "Accounting"),
    ]

    let results = TaskBoardLogic.filteredTasks(
      tasks,
      query: "  launch ",
      status: nil,
      priority: nil
    )

    XCTAssertEqual(Set(results.map(\.title)), ["Review LAUNCH plan", "Prepare notes"])
  }

  func testFilteringCombinesStatusAndPriority() {
    let matching = TaskItem(title: "Matching", status: .doing, priority: .high)
    let wrongStatus = TaskItem(title: "Wrong status", status: .todo, priority: .high)
    let wrongPriority = TaskItem(title: "Wrong priority", status: .doing, priority: .low)

    let results = TaskBoardLogic.filteredTasks(
      [matching, wrongStatus, wrongPriority],
      query: "",
      status: .doing,
      priority: .high
    )

    XCTAssertEqual(results, [matching])
  }

  func testFilteringSortsOpenTasksThenDueDateThenCreationDate() {
    let dueSoonNewest = TaskItem(
      title: "Due soon newest",
      status: .todo,
      dueDate: date(18),
      createdAt: date(15)
    )
    let dueSoonOlder = TaskItem(
      title: "Due soon older",
      status: .doing,
      dueDate: date(18),
      createdAt: date(14)
    )
    let dueLater = TaskItem(title: "Due later", status: .todo, dueDate: date(20))
    let completed = TaskItem(title: "Completed", status: .done, dueDate: date(10))

    let results = TaskBoardLogic.filteredTasks(
      [completed, dueLater, dueSoonOlder, dueSoonNewest],
      query: "",
      status: nil,
      priority: nil
    )

    XCTAssertEqual(
      results.map(\.title),
      ["Due soon newest", "Due soon older", "Due later", "Completed"]
    )
  }

  func testReplacingTaskChangesOnlyTheMatchingIdentifier() {
    let first = TaskItem(title: "First", priority: .low)
    let second = TaskItem(title: "Second", priority: .medium)
    var updated = first
    updated.title = "Updated"
    updated.priority = .high

    let results = TaskBoardLogic.replacingTask(updated, in: [first, second])

    XCTAssertEqual(results, [updated, second])
  }

  func testReplacingUnknownTaskLeavesCollectionUnchanged() {
    let original = [TaskItem(title: "Existing")]
    let unknown = TaskItem(title: "Unknown")

    XCTAssertEqual(TaskBoardLogic.replacingTask(unknown, in: original), original)
  }

  func testDateOffsetReturnsStartOfRequestedDay() {
    let start = date(18, hour: 22)
    let result = TaskBoardLogic.dateOffset(2, from: start, calendar: calendar)
    let components = calendar.dateComponents([.year, .month, .day, .hour], from: result)

    XCTAssertEqual(components.year, 2026)
    XCTAssertEqual(components.month, 7)
    XCTAssertEqual(components.day, 20)
    XCTAssertEqual(components.hour, 0)
  }

  func testCodableRoundTripPreservesProjectAndCompletionMetadata() throws {
    let project = ProjectItem(name: "Launch", color: .orange, createdAt: date(10))
    let task = TaskItem(
      title: "Ship release",
      notes: "Verify rollout",
      status: .done,
      priority: .high,
      dueDate: date(20),
      createdAt: date(11),
      completedAt: date(19),
      projectID: project.id
    )

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    XCTAssertEqual(try decoder.decode(ProjectItem.self, from: encoder.encode(project)), project)
    XCTAssertEqual(try decoder.decode(TaskItem.self, from: encoder.encode(task)), task)
  }
}
