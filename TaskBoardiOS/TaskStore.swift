import Foundation
import SwiftUI

@MainActor
final class TaskStore: ObservableObject {
  @Published private(set) var tasks: [TaskItem]
  @Published private(set) var projects: [ProjectItem]

  private let storage: UserDefaults
  private let storageKey = "task-board-items-v1-ios"
  private let projectsStorageKey = "task-board-projects-v1-ios"
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  init(storage: UserDefaults = .standard) {
    self.storage = storage

    let initialProjects: [ProjectItem]
    if let data = storage.data(forKey: projectsStorageKey),
      let savedProjects = try? decoder.decode([ProjectItem].self, from: data)
    {
      initialProjects = savedProjects
    } else {
      initialProjects = TaskBoardLogic.seedProjects()
    }
    projects = initialProjects

    if let data = storage.data(forKey: storageKey),
      let savedTasks = try? decoder.decode([TaskItem].self, from: data)
    {
      tasks = savedTasks
    } else {
      var seededTasks = TaskBoardLogic.seedTasks()
      if initialProjects.count >= 2 {
        seededTasks[0].projectID = initialProjects[0].id
        seededTasks[1].projectID = initialProjects[1].id
        seededTasks[2].projectID = initialProjects[0].id
      }
      tasks = seededTasks
    }
    save()
  }

  func addTask(
    title: String,
    notes: String,
    status: TaskStatus = .todo,
    priority: TaskPriority,
    dueDate: Date,
    projectID: UUID?
  ) {
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedTitle.isEmpty else { return }

    tasks.insert(
      TaskItem(
        title: trimmedTitle,
        notes: notes,
        status: status,
        priority: priority,
        dueDate: dueDate,
        completedAt: status == .done ? Date() : nil,
        projectID: projectID
      ),
      at: 0
    )
    save()
  }

  func replaceTask(_ task: TaskItem) {
    let trimmedTitle = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedTitle.isEmpty else { return }

    guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }

    var updatedTask = task
    updatedTask.title = trimmedTitle
    updatedTask.notes = task.notes.trimmingCharacters(in: .whitespacesAndNewlines)
    if updatedTask.status == .done {
      updatedTask.completedAt =
        tasks[index].status == .done
        ? tasks[index].completedAt
        : Date()
    } else {
      updatedTask.completedAt = nil
    }
    tasks[index] = updatedTask
    save()
  }

  func setStatus(_ status: TaskStatus, for task: TaskItem) {
    update(task) { item in
      apply(status, to: &item)
    }
  }

  func toggleComplete(_ task: TaskItem) {
    update(task) { item in
      apply(item.status == .done ? .todo : .done, to: &item)
    }
  }

  func delete(_ task: TaskItem) {
    tasks.removeAll { $0.id == task.id }
    save()
  }

  func addProject(name: String, color: ProjectColor) {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else { return }
    guard !projects.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame }) else {
      return
    }

    projects.append(ProjectItem(name: trimmedName, color: color))
    projects.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    save()
  }

  func deleteProject(_ project: ProjectItem) {
    projects.removeAll { $0.id == project.id }
    for index in tasks.indices where tasks[index].projectID == project.id {
      tasks[index].projectID = nil
    }
    save()
  }

  private func update(_ task: TaskItem, changes: (inout TaskItem) -> Void) {
    guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
    changes(&tasks[index])
    save()
  }

  private func apply(_ status: TaskStatus, to task: inout TaskItem) {
    if status == .done && task.status != .done {
      task.completedAt = Date()
    } else {
      if status != .done {
        task.completedAt = nil
      }
    }
    task.status = status
  }

  private func save() {
    if let data = try? encoder.encode(tasks) {
      storage.set(data, forKey: storageKey)
    }
    if let data = try? encoder.encode(projects) {
      storage.set(data, forKey: projectsStorageKey)
    }
  }
}
