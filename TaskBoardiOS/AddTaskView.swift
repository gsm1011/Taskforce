import SwiftUI

struct AddTaskView: View {
  var initialPriority: TaskPriority = .medium
  let projects: [ProjectItem]
  let onAdd: (String, String, TaskStatus, TaskPriority, Date, UUID?) -> Void

  var body: some View {
    TaskFormView(
      navigationTitle: "New Task",
      confirmationTitle: "Add",
      initialStatus: .todo,
      initialPriority: initialPriority,
      projects: projects,
      showsStatusPicker: false
    ) { title, notes, status, priority, dueDate, projectID in
      onAdd(title, notes, status, priority, dueDate, projectID)
    }
  }
}

struct EditTaskView: View {
  let task: TaskItem
  let projects: [ProjectItem]
  let onSave: (TaskItem) -> Void

  var body: some View {
    TaskFormView(
      navigationTitle: "Edit Task",
      confirmationTitle: "Save",
      initialTitle: task.title,
      initialNotes: task.notes,
      initialStatus: task.status,
      initialPriority: task.priority,
      initialDueDate: task.dueDate,
      initialProjectID: task.projectID,
      projects: projects
    ) { title, notes, status, priority, dueDate, projectID in
      var updatedTask = task
      updatedTask.title = title
      updatedTask.notes = notes
      updatedTask.status = status
      updatedTask.priority = priority
      updatedTask.dueDate = dueDate
      updatedTask.projectID = projectID
      onSave(updatedTask)
    }
  }
}

private struct TaskFormView: View {
  @Environment(\.dismiss) private var dismiss
  @FocusState private var isTitleFocused: Bool

  @State private var taskTitle: String
  @State private var notes: String
  @State private var status: TaskStatus
  @State private var priority: TaskPriority
  @State private var dueDate: Date
  @State private var projectID: UUID?

  let navigationTitle: String
  let confirmationTitle: String
  let projects: [ProjectItem]
  let showsStatusPicker: Bool
  let onSave: (String, String, TaskStatus, TaskPriority, Date, UUID?) -> Void

  init(
    navigationTitle: String,
    confirmationTitle: String,
    initialTitle: String = "",
    initialNotes: String = "",
    initialStatus: TaskStatus,
    initialPriority: TaskPriority = .medium,
    initialDueDate: Date = TaskBoardLogic.dateOffset(2),
    initialProjectID: UUID? = nil,
    projects: [ProjectItem],
    showsStatusPicker: Bool = true,
    onSave: @escaping (String, String, TaskStatus, TaskPriority, Date, UUID?) -> Void
  ) {
    self.navigationTitle = navigationTitle
    self.confirmationTitle = confirmationTitle
    self.projects = projects
    self.showsStatusPicker = showsStatusPicker
    self.onSave = onSave
    _taskTitle = State(initialValue: initialTitle)
    _notes = State(initialValue: initialNotes)
    _status = State(initialValue: initialStatus)
    _priority = State(initialValue: initialPriority)
    _dueDate = State(initialValue: initialDueDate)
    _projectID = State(initialValue: initialProjectID)
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("What needs to be done?", text: $taskTitle)
            .focused($isTitleFocused)
            .submitLabel(.done)
          TextField("Optional details", text: $notes, axis: .vertical)
            .lineLimit(2...4)
        } header: {
          Label("Task", systemImage: "square.and.pencil")
        }

        Section {
          Picker(selection: $projectID) {
            Text("None").tag(UUID?.none)
            ForEach(projects) { project in
              Text(project.name).tag(Optional(project.id))
            }
          } label: {
            Label("Project", systemImage: "folder")
          }

          if showsStatusPicker {
            Picker(selection: $status) {
              ForEach(TaskStatus.allCases) { status in
                Text(status.label).tag(status)
              }
            } label: {
              Label("Status", systemImage: "circle.dotted")
            }
          }

          Picker(selection: $priority) {
            ForEach(TaskPriority.allCases) { priority in
              Text(priority.label).tag(priority)
            }
          } label: {
            Label("Priority", systemImage: "flag")
          }

          DatePicker(
            selection: $dueDate,
            displayedComponents: .date
          ) {
            Label("Due", systemImage: "calendar")
          }
        } header: {
          Label("Organize", systemImage: "slider.horizontal.3")
        }
      }
      .scrollContentBackground(.hidden)
      .background(Color(uiColor: .systemGroupedBackground))
      .navigationTitle(navigationTitle)
      .navigationBarTitleDisplayMode(.inline)
      .tint(.indigo)
      .onAppear {
        if taskTitle.isEmpty {
          isTitleFocused = true
        }
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button(confirmationTitle) {
            onSave(taskTitle, notes, status, priority, dueDate, projectID)
            dismiss()
          }
          .fontWeight(.semibold)
          .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
  }
}

#Preview("Add") {
  AddTaskView(projects: TaskBoardLogic.seedProjects()) { _, _, _, _, _, _ in }
}

#Preview("Edit") {
  EditTaskView(
    task: TaskBoardLogic.seedTasks().first!,
    projects: TaskBoardLogic.seedProjects()
  ) { _ in }
}
