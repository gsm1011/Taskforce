import Foundation

public enum TaskStatus: String, CaseIterable, Codable, Identifiable {
  case todo
  case doing
  case done

  public var id: String { rawValue }

  public var label: String {
    switch self {
    case .todo:
      return "To do"
    case .doing:
      return "Doing"
    case .done:
      return "Done"
    }
  }

  public var symbolName: String {
    switch self {
    case .todo:
      return "circle"
    case .doing:
      return "clock"
    case .done:
      return "checkmark.circle.fill"
    }
  }
}

public enum TaskPriority: String, CaseIterable, Codable, Identifiable {
  case high
  case medium
  case low

  public var id: String { rawValue }

  public var label: String {
    switch self {
    case .high:
      return "High"
    case .medium:
      return "Medium"
    case .low:
      return "Low"
    }
  }
}

public enum ProjectColor: String, CaseIterable, Codable, Identifiable {
  case blue
  case teal
  case orange
  case purple
  case pink

  public var id: String { rawValue }

  public var label: String {
    rawValue.capitalized
  }
}

public struct ProjectItem: Identifiable, Codable, Equatable {
  public var id: UUID
  public var name: String
  public var color: ProjectColor
  public var createdAt: Date

  public init(
    id: UUID = UUID(),
    name: String,
    color: ProjectColor = .blue,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    self.color = color
    self.createdAt = createdAt
  }
}

public struct TaskItem: Identifiable, Codable, Equatable {
  public var id: UUID
  public var title: String
  public var notes: String
  public var status: TaskStatus
  public var priority: TaskPriority
  public var dueDate: Date
  public var createdAt: Date
  public var completedAt: Date?
  public var projectID: UUID?

  public init(
    id: UUID = UUID(),
    title: String,
    notes: String = "",
    status: TaskStatus = .todo,
    priority: TaskPriority = .medium,
    dueDate: Date = Date(),
    createdAt: Date = Date(),
    completedAt: Date? = nil,
    projectID: UUID? = nil
  ) {
    self.id = id
    self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    self.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
    self.status = status
    self.priority = priority
    self.dueDate = dueDate
    self.createdAt = createdAt
    self.completedAt = completedAt
    self.projectID = projectID
  }

  public var isComplete: Bool {
    status == .done
  }

  public func isOverdue(
    referenceDate: Date = Date(),
    calendar: Calendar = .current
  ) -> Bool {
    guard status != .done else { return false }
    return calendar.startOfDay(for: dueDate) < calendar.startOfDay(for: referenceDate)
  }
}

public struct TaskStats: Equatable {
  public var total: Int
  public var open: Int
  public var done: Int
  public var overdue: Int

  public init(total: Int, open: Int, done: Int, overdue: Int) {
    self.total = total
    self.open = open
    self.done = done
    self.overdue = overdue
  }
}

public enum TaskBoardLogic {
  public static func seedProjects() -> [ProjectItem] {
    [
      ProjectItem(name: "Personal", color: .teal),
      ProjectItem(name: "Work", color: .blue),
    ]
  }

  public static func dateOffset(
    _ days: Int,
    from date: Date = Date(),
    calendar: Calendar = .current
  ) -> Date {
    let start = calendar.startOfDay(for: date)
    return calendar.date(byAdding: .day, value: days, to: start) ?? start
  }

  public static func seedTasks(referenceDate: Date = Date()) -> [TaskItem] {
    [
      TaskItem(
        title: "Map out weekly priorities",
        notes: "Pick the top three outcomes for the week.",
        status: .todo,
        priority: .high,
        dueDate: dateOffset(1, from: referenceDate),
        createdAt: dateOffset(-2, from: referenceDate)
      ),
      TaskItem(
        title: "Review project backlog",
        notes: "Move stale items out of the active list.",
        status: .doing,
        priority: .medium,
        dueDate: dateOffset(3, from: referenceDate),
        createdAt: dateOffset(-3, from: referenceDate)
      ),
      TaskItem(
        title: "Plan Friday admin block",
        notes: "Collect low-energy tasks into one focused window.",
        status: .done,
        priority: .low,
        dueDate: dateOffset(-1, from: referenceDate),
        createdAt: dateOffset(-5, from: referenceDate),
        completedAt: dateOffset(-1, from: referenceDate)
      ),
    ]
  }

  public static func stats(
    for tasks: [TaskItem],
    referenceDate: Date = Date(),
    calendar: Calendar = .current
  ) -> TaskStats {
    let done = tasks.filter(\.isComplete).count
    let overdue = tasks.filter {
      $0.isOverdue(referenceDate: referenceDate, calendar: calendar)
    }.count

    return TaskStats(
      total: tasks.count,
      open: tasks.count - done,
      done: done,
      overdue: overdue
    )
  }

  public static func filteredTasks(
    _ tasks: [TaskItem],
    query: String,
    status: TaskStatus?,
    priority: TaskPriority?
  ) -> [TaskItem] {
    let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    return
      tasks
      .filter { task in
        let searchable = "\(task.title) \(task.notes)".lowercased()
        let matchesQuery = cleanedQuery.isEmpty || searchable.contains(cleanedQuery)
        let matchesStatus = status == nil || task.status == status
        let matchesPriority = priority == nil || task.priority == priority
        return matchesQuery && matchesStatus && matchesPriority
      }
      .sorted { first, second in
        if first.status == .done && second.status != .done {
          return false
        }

        if first.status != .done && second.status == .done {
          return true
        }

        if first.dueDate != second.dueDate {
          return first.dueDate < second.dueDate
        }

        return first.createdAt > second.createdAt
      }
  }

  public static func replacingTask(_ updatedTask: TaskItem, in tasks: [TaskItem]) -> [TaskItem] {
    tasks.map { task in
      task.id == updatedTask.id ? updatedTask : task
    }
  }
}
