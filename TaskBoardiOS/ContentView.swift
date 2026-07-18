import Charts
import SwiftUI

private enum StatusFilter: String, CaseIterable, Identifiable {
  case all
  case todo
  case doing
  case done

  var id: String { rawValue }

  var label: String {
    switch self {
    case .all:
      return "All"
    case .todo:
      return TaskStatus.todo.label
    case .doing:
      return TaskStatus.doing.label
    case .done:
      return TaskStatus.done.label
    }
  }

  var status: TaskStatus? {
    switch self {
    case .all:
      return nil
    case .todo:
      return .todo
    case .doing:
      return .doing
    case .done:
      return .done
    }
  }
}

private enum PriorityFilter: String, CaseIterable, Identifiable {
  case all
  case high
  case medium
  case low

  var id: String { rawValue }

  var label: String {
    switch self {
    case .all:
      return "Any"
    case .high:
      return TaskPriority.high.label
    case .medium:
      return TaskPriority.medium.label
    case .low:
      return TaskPriority.low.label
    }
  }

  var priority: TaskPriority? {
    switch self {
    case .all:
      return nil
    case .high:
      return .high
    case .medium:
      return .medium
    case .low:
      return .low
    }
  }
}

private enum AppTab: CaseIterable, Hashable, Identifiable {
  case tasks
  case insights
  case settings

  var id: Self { self }

  var label: String {
    switch self {
    case .tasks:
      return "Tasks"
    case .insights:
      return "Insights"
    case .settings:
      return "Settings"
    }
  }

  var symbol: String {
    switch self {
    case .tasks:
      return "checklist"
    case .insights:
      return "chart.bar.xaxis"
    case .settings:
      return "gearshape"
    }
  }

  var selectedSymbol: String {
    switch self {
    case .tasks:
      return "checklist"
    case .insights:
      return "chart.bar.fill"
    case .settings:
      return "gearshape.fill"
    }
  }
}

private enum AppTheme {
  static let accent = Color.indigo
  static let canvas = Color(uiColor: .systemGroupedBackground)
  static let card = Color(uiColor: .secondarySystemGroupedBackground)
  static let border = Color.primary.opacity(0.06)
  static let cardRadius: CGFloat = 16
}

private enum TaskSort: String, CaseIterable, Identifiable {
  case dueSoon
  case newest
  case priority

  var id: String { rawValue }

  var label: String {
    switch self {
    case .dueSoon:
      return "Due soon"
    case .newest:
      return "Newest"
    case .priority:
      return "Priority"
    }
  }
}

struct ContentView: View {
  @StateObject private var store = TaskStore()
  @State private var selectedTab: AppTab = .tasks
  @State private var searchText = ""
  @State private var statusFilter: StatusFilter = .all
  @State private var priorityFilter: PriorityFilter = .all
  @State private var projectFilterID: UUID?
  @State private var sortOrder: TaskSort = .dueSoon
  @State private var isAddingTask = false
  @State private var taskBeingEdited: TaskItem?
  @AppStorage("default-task-priority") private var defaultPriority: TaskPriority = .medium

  private var stats: TaskStats {
    TaskBoardLogic.stats(for: store.tasks)
  }

  private var visibleTasks: [TaskItem] {
    let filtered = TaskBoardLogic.filteredTasks(
      store.tasks,
      query: searchText,
      status: statusFilter.status,
      priority: priorityFilter.priority
    ).filter { task in
      projectFilterID == nil || task.projectID == projectFilterID
    }

    switch sortOrder {
    case .dueSoon:
      return filtered
    case .newest:
      return filtered.sorted { (first: TaskItem, second: TaskItem) -> Bool in
        first.createdAt > second.createdAt
      }
    case .priority:
      return filtered.sorted { (first: TaskItem, second: TaskItem) -> Bool in
        if first.priority.sortRank != second.priority.sortRank {
          return first.priority.sortRank < second.priority.sortRank
        }
        return first.dueDate < second.dueDate
      }
    }
  }

  private var hasActiveFilters: Bool {
    statusFilter != .all || priorityFilter != .all || projectFilterID != nil
  }

  var body: some View {
    Group {
      switch selectedTab {
      case .tasks:
        TaskListScreen(
          tasks: visibleTasks,
          projects: store.projects,
          totalTaskCount: store.tasks.count,
          searchText: $searchText,
          hasActiveFilters: hasActiveFilters,
          onAdd: { isAddingTask = true },
          onOpenFilters: { selectedTab = .settings },
          onToggle: store.toggleComplete,
          onStatusChange: store.setStatus,
          onEdit: { taskBeingEdited = $0 },
          onDelete: store.delete
        )

      case .insights:
        InsightsScreen(tasks: store.tasks, projects: store.projects, stats: stats)

      case .settings:
        SettingsScreen(
          statusFilter: $statusFilter,
          priorityFilter: $priorityFilter,
          projectFilterID: $projectFilterID,
          sortOrder: $sortOrder,
          defaultPriority: $defaultPriority,
          projects: store.projects,
          tasks: store.tasks,
          onAddProject: store.addProject,
          onDeleteProject: { project in
            if projectFilterID == project.id {
              projectFilterID = nil
            }
            store.deleteProject(project)
          }
        )
      }
    }
    .safeAreaInset(edge: .bottom, spacing: 0) {
      CompactTabBar(selection: $selectedTab)
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
    }
    .tint(AppTheme.accent)
    .sheet(isPresented: $isAddingTask) {
      AddTaskView(initialPriority: defaultPriority, projects: store.projects) {
        title, notes, status, priority, dueDate, projectID in
        store.addTask(
          title: title,
          notes: notes,
          status: status,
          priority: priority,
          dueDate: dueDate,
          projectID: projectID
        )
      }
      .presentationDetents([.medium, .large])
      .presentationDragIndicator(.visible)
    }
    .sheet(item: $taskBeingEdited) { task in
      EditTaskView(task: task, projects: store.projects) { updatedTask in
        store.replaceTask(updatedTask)
      }
      .presentationDetents([.medium, .large])
      .presentationDragIndicator(.visible)
    }
  }
}

private struct CompactTabBar: View {
  @Binding var selection: AppTab

  var body: some View {
    HStack(spacing: 4) {
      ForEach(AppTab.allCases) { tab in
        Button {
          withAnimation(.snappy(duration: 0.2)) {
            selection = tab
          }
        } label: {
          HStack(spacing: 6) {
            Image(systemName: selection == tab ? tab.selectedSymbol : tab.symbol)
              .symbolRenderingMode(.hierarchical)
            Text(tab.label)
          }
          .font(.footnote.weight(.semibold))
          .frame(maxWidth: .infinity, minHeight: 44)
          .foregroundStyle(selection == tab ? AppTheme.accent : Color.secondary)
          .contentShape(Rectangle())
          .background {
            if selection == tab {
              Capsule()
                .fill(AppTheme.accent.opacity(0.12))
            }
          }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(selection == tab ? .isSelected : [])
      }
    }
    .padding(5)
    .background(.ultraThinMaterial, in: Capsule())
    .overlay {
      Capsule()
        .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
    }
    .shadow(color: .black.opacity(0.08), radius: 12, y: 5)
  }
}

private struct TaskListScreen: View {
  let tasks: [TaskItem]
  let projects: [ProjectItem]
  let totalTaskCount: Int
  @Binding var searchText: String
  let hasActiveFilters: Bool
  let onAdd: () -> Void
  let onOpenFilters: () -> Void
  let onToggle: (TaskItem) -> Void
  let onStatusChange: (TaskStatus, TaskItem) -> Void
  let onEdit: (TaskItem) -> Void
  let onDelete: (TaskItem) -> Void

  var body: some View {
    NavigationStack {
      List {
        if hasActiveFilters {
          HStack {
            Label("\(tasks.count) of \(totalTaskCount) tasks", systemImage: "line.3.horizontal.decrease")
              .font(.subheadline.weight(.medium))
              .foregroundStyle(AppTheme.accent)

            Spacer()

            Button("Adjust", action: onOpenFilters)
              .font(.subheadline.weight(.semibold))
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 11)
          .background(AppTheme.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
          .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
        }

        if tasks.isEmpty {
          ContentUnavailableView(
            searchText.isEmpty && !hasActiveFilters ? "No tasks yet" : "No matching tasks",
            systemImage: searchText.isEmpty && !hasActiveFilters ? "checklist" : "magnifyingglass",
            description: Text(
              searchText.isEmpty && !hasActiveFilters
                ? "Create a task to get started."
                : "Try another search or adjust filters in Settings."
            )
          )
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
        } else {
          ForEach(tasks) { task in
            TaskRow(
              task: task,
              project: projects.first { $0.id == task.projectID },
              onToggle: { onToggle(task) },
              onStatusChange: { onStatusChange($0, task) },
              onEdit: { onEdit(task) },
              onDelete: { onDelete(task) }
            )
            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
          }
        }
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .background(AppTheme.canvas)
      .navigationTitle("Tasks")
      .searchable(text: $searchText, prompt: "Search tasks")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: onAdd) {
            Label("New task", systemImage: "plus")
          }
        }
      }
    }
  }
}

private struct InsightsScreen: View {
  let tasks: [TaskItem]
  let projects: [ProjectItem]
  let stats: TaskStats

  private var completedTasks: [TaskItem] {
    tasks.filter { $0.status == .done && $0.completedAt != nil }
  }

  private var deadlineMetCount: Int {
    completedTasks.filter { task in
      guard let completedAt = task.completedAt else { return false }
      return Calendar.current.compare(completedAt, to: task.dueDate, toGranularity: .day) != .orderedDescending
    }.count
  }

  private var deadlineRate: Double {
    guard !completedTasks.isEmpty else { return 0 }
    return Double(deadlineMetCount) / Double(completedTasks.count)
  }

  private var averageCompletionLabel: String {
    let durations = completedTasks.compactMap { task -> TimeInterval? in
      guard let completedAt = task.completedAt else { return nil }
      return max(completedAt.timeIntervalSince(task.createdAt), 0)
    }
    guard !durations.isEmpty else { return "—" }
    let averageHours = durations.reduce(0, +) / Double(durations.count) / 3_600
    if averageHours < 24 {
      return "\(max(Int(averageHours.rounded()), 1))h"
    }
    return "\(max(Int((averageHours / 24).rounded()), 1))d"
  }

  private var dailyCompletions: [DailyCompletion] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    return (0..<7).reversed().map { offset in
      let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
      let count = completedTasks.filter { task in
        guard let completedAt = task.completedAt else { return false }
        return calendar.isDate(completedAt, inSameDayAs: day)
      }.count
      return DailyCompletion(day: day, count: count)
    }
  }

  private var projectSummaries: [ProjectProgress] {
    projects.compactMap { project in
      let projectTasks = tasks.filter { $0.projectID == project.id }
      guard !projectTasks.isEmpty else { return nil }
      return ProjectProgress(
        project: project,
        total: projectTasks.count,
        done: projectTasks.filter(\.isComplete).count,
        overdue: projectTasks.filter { $0.isOverdue() }.count
      )
    }
    .sorted { first, second in
      if first.fractionComplete != second.fractionComplete {
        return first.fractionComplete < second.fractionComplete
      }
      return first.project.name.localizedCaseInsensitiveCompare(second.project.name) == .orderedAscending
    }
  }

  var body: some View {
    NavigationStack {
      List {
        Section("Overview") {
          SummaryStrip(stats: stats)
        }

        Section("Performance") {
          HStack(spacing: 0) {
            InsightMetric(
              value: averageCompletionLabel,
              label: "Avg. finish time",
              symbol: "timer"
            )

            Divider()
              .frame(height: 68)

            InsightMetric(
              value: "\(Int((deadlineRate * 100).rounded()))%",
              label: "Deadlines met",
              symbol: "calendar.badge.checkmark"
            )
          }
          .padding(.vertical, 4)
        }

        Section("Project progress") {
          if projectSummaries.isEmpty {
            Text("Assign tasks to projects to see progress here.")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          } else {
            ForEach(projectSummaries) { summary in
              ProjectProgressRow(summary: summary)
            }
          }
        }

        Section("Completed — last 7 days") {
          Chart(dailyCompletions) { item in
            BarMark(
              x: .value("Day", item.day, unit: .day),
              y: .value("Completed", item.count)
            )
            .foregroundStyle(AppTheme.accent.gradient)
            .cornerRadius(4)
          }
          .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
              AxisValueLabel(format: .dateTime.weekday(.narrow))
            }
          }
          .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3))
          }
          .chartYScale(domain: 0...max(dailyCompletions.map(\.count).max() ?? 0, 1))
          .frame(height: 170)
          .accessibilityLabel("Tasks completed over the last seven days")
        }

        Section {
          HStack(spacing: 18) {
            Gauge(value: deadlineRate) {
              Text("Deadline reliability")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(.green)
            .frame(width: 72)

            VStack(alignment: .leading, spacing: 4) {
              Text("\(deadlineMetCount) of \(completedTasks.count) on time")
                .font(.headline)
              Text("Based on completed tasks with tracked finish dates.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
          }
          .padding(.vertical, 4)
        } header: {
          Text("Deadline reliability")
        }
      }
      .listStyle(.insetGrouped)
      .scrollContentBackground(.hidden)
      .background(AppTheme.canvas)
      .navigationTitle("Insights")
    }
  }
}

private struct ProjectProgress: Identifiable {
  let project: ProjectItem
  let total: Int
  let done: Int
  let overdue: Int

  var id: UUID { project.id }

  var fractionComplete: Double {
    guard total > 0 else { return 0 }
    return Double(done) / Double(total)
  }
}

private struct ProjectProgressRow: View {
  let summary: ProjectProgress

  var body: some View {
    VStack(alignment: .leading, spacing: 9) {
      HStack {
        ProjectBadge(project: summary.project)

        Spacer()

        Text("\(summary.done) of \(summary.total)")
          .font(.subheadline.weight(.semibold))
          .monospacedDigit()
      }

      ProgressView(value: summary.fractionComplete)
        .tint(summary.project.color.swiftUIColor)

      HStack {
        Text("\(Int((summary.fractionComplete * 100).rounded()))% complete")
          .foregroundStyle(.secondary)

        Spacer()

        if summary.overdue > 0 {
          Label("\(summary.overdue) overdue", systemImage: "exclamationmark.circle.fill")
            .foregroundStyle(.red)
        }
      }
      .font(.caption)
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
  }
}

private struct DailyCompletion: Identifiable {
  let day: Date
  let count: Int

  var id: Date { day }
}

private struct InsightMetric: View {
  let value: String
  let label: String
  let symbol: String

  var body: some View {
    VStack(spacing: 6) {
      Image(systemName: symbol)
        .font(.subheadline.weight(.semibold))
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(AppTheme.accent)
        .frame(width: 30, height: 30)
        .background(AppTheme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

      Text(value)
        .font(.title3.weight(.bold))
        .monospacedDigit()

      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .combine)
  }
}

private struct SettingsScreen: View {
  @Binding var statusFilter: StatusFilter
  @Binding var priorityFilter: PriorityFilter
  @Binding var projectFilterID: UUID?
  @Binding var sortOrder: TaskSort
  @Binding var defaultPriority: TaskPriority
  let projects: [ProjectItem]
  let tasks: [TaskItem]
  let onAddProject: (String, ProjectColor) -> Void
  let onDeleteProject: (ProjectItem) -> Void

  @State private var isAddingProject = false

  private var hasActiveFilters: Bool {
    statusFilter != .all || priorityFilter != .all || projectFilterID != nil
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Task list") {
          Picker(selection: $statusFilter) {
            ForEach(StatusFilter.allCases) { filter in
              Text(filter.label).tag(filter)
            }
          } label: {
            FormRowLabel("Status", symbol: "circle.dotted")
          }

          Picker(selection: $priorityFilter) {
            ForEach(PriorityFilter.allCases) { filter in
              Text(filter.label).tag(filter)
            }
          } label: {
            FormRowLabel("Priority", symbol: "flag")
          }

          Picker(selection: $projectFilterID) {
            Text("All projects").tag(UUID?.none)
            ForEach(projects) { project in
              Text(project.name).tag(Optional(project.id))
            }
          } label: {
            FormRowLabel("Project", symbol: "folder")
          }

          Picker(selection: $sortOrder) {
            ForEach(TaskSort.allCases) { option in
              Text(option.label).tag(option)
            }
          } label: {
            FormRowLabel("Sort by", symbol: "arrow.up.arrow.down")
          }
        }

        Section("New tasks") {
          Picker(selection: $defaultPriority) {
            ForEach(TaskPriority.allCases) { priority in
              Text(priority.label).tag(priority)
            }
          } label: {
            FormRowLabel("Default priority", symbol: "flag.fill")
          }
        }

        Section("Projects") {
          ForEach(projects) { project in
            HStack {
              ProjectBadge(project: project)

              Spacer()

              Text("\(tasks.filter { $0.projectID == project.id }.count) tasks")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
              Button(role: .destructive) {
                onDeleteProject(project)
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
          }

          Button {
            isAddingProject = true
          } label: {
            Label("New project", systemImage: "folder.badge.plus")
          }
        }

        Section {
          Button {
            statusFilter = .all
            priorityFilter = .all
            projectFilterID = nil
          } label: {
            Label("Clear task filters", systemImage: "line.3.horizontal.decrease.circle")
          }
          .disabled(!hasActiveFilters)
        } footer: {
          Text("Filters apply to the Tasks tab. Insights always include your full task history.")
        }
      }
      .scrollContentBackground(.hidden)
      .background(AppTheme.canvas)
      .navigationTitle("Settings")
      .sheet(isPresented: $isAddingProject) {
        NewProjectView(onAdd: onAddProject)
          .presentationDetents([.medium])
          .presentationDragIndicator(.visible)
      }
    }
  }
}

private struct FormRowLabel: View {
  let title: String
  let symbol: String

  init(_ title: String, symbol: String) {
    self.title = title
    self.symbol = symbol
  }

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: symbol)
        .font(.subheadline.weight(.medium))
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(AppTheme.accent)
        .frame(width: 22)

      Text(title)
    }
  }
}

private struct NewProjectView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var name = ""
  @State private var color: ProjectColor = .blue
  @FocusState private var isNameFocused: Bool

  let onAdd: (String, ProjectColor) -> Void

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Project name", text: $name)
            .focused($isNameFocused)

          Picker(selection: $color) {
            ForEach(ProjectColor.allCases) { option in
              Label(option.label, systemImage: "circle.fill")
                .foregroundStyle(option.swiftUIColor)
                .tag(option)
            }
          } label: {
            FormRowLabel("Color", symbol: "paintpalette")
          }
        } header: {
          Label("Project", systemImage: "folder")
        }
      }
      .scrollContentBackground(.hidden)
      .background(AppTheme.canvas)
      .navigationTitle("New Project")
      .navigationBarTitleDisplayMode(.inline)
      .onAppear { isNameFocused = true }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            onAdd(name, color)
            dismiss()
          }
          .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
  }
}

private struct SummaryStrip: View {
  let stats: TaskStats

  private var items: [(String, Int, String, Color)] {
    [
      ("Open", stats.open, "circle.dotted", AppTheme.accent),
      ("Done", stats.done, "checkmark.circle.fill", .green),
      ("Overdue", stats.overdue, "exclamationmark.circle.fill", .red),
    ]
  }

  var body: some View {
    HStack(spacing: 0) {
      ForEach(items.indices, id: \.self) { index in
        let item = items[index]

        if index > 0 {
          Divider()
            .frame(height: 38)
        }

        VStack(spacing: 4) {
          HStack(spacing: 5) {
            Image(systemName: item.2)
              .font(.caption)
              .foregroundStyle(item.3)
            Text("\(item.1)")
              .font(.headline)
              .monospacedDigit()
          }

          Text(item.0)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
      }
    }
    .padding(.vertical, 6)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      "\(stats.open) open, \(stats.done) done, \(stats.overdue) overdue"
    )
  }
}

private struct TaskRow: View {
  let task: TaskItem
  let project: ProjectItem?
  let onToggle: () -> Void
  let onStatusChange: (TaskStatus) -> Void
  let onEdit: () -> Void
  let onDelete: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 2) {
      Button(action: onToggle) {
        Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
          .font(.title3)
          .symbolRenderingMode(.hierarchical)
          .foregroundStyle(task.status == .done ? .green : AppTheme.accent)
      }
      .buttonStyle(.plain)
      .frame(width: 44, height: 44, alignment: .top)
      .accessibilityLabel(task.status == .done ? "Mark task as to do" : "Mark task as done")

      VStack(alignment: .leading, spacing: 7) {
        HStack(alignment: .firstTextBaseline) {
          Text(task.title)
            .font(.body.weight(.semibold))
            .strikethrough(task.status == .done)
            .foregroundStyle(task.status == .done ? .secondary : .primary)
            .lineLimit(2)

          Spacer()

          PriorityBadge(priority: task.priority)
        }

        if !task.notes.isEmpty {
          Text(task.notes)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .strikethrough(task.status == .done)
            .lineLimit(2)
        }

        HStack(spacing: 10) {
          if let project {
            ProjectBadge(project: project)
          }

          Spacer(minLength: 0)

          Label(task.dueDate.formatted(.dateTime.month(.abbreviated).day()), systemImage: "calendar")
            .fontWeight(.medium)
            .foregroundStyle(task.isOverdue() ? .red : .secondary)

          Menu {
            ForEach(TaskStatus.allCases) { status in
              Button(status.label) {
                onStatusChange(status)
              }
            }
          } label: {
            Label(task.status.label, systemImage: task.status.symbolName)
              .foregroundStyle(task.status.tintColor)
          }
        }
        .font(.caption)
      }
    }
    .padding(.leading, 6)
    .padding(.trailing, 14)
    .padding(.vertical, 12)
    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
        .stroke(AppTheme.border, lineWidth: 0.5)
    }
    .contentShape(Rectangle())
    .onTapGesture(perform: onEdit)
    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
      Button(role: .destructive, action: onDelete) {
        Label("Delete", systemImage: "trash")
      }
    }
    .swipeActions(edge: .leading, allowsFullSwipe: false) {
      Button(action: onEdit) {
        Label("Edit", systemImage: "pencil")
      }
      .tint(AppTheme.accent)
    }
    .contextMenu {
      Button(action: onEdit) {
        Label("Edit", systemImage: "pencil")
      }

      Button(role: .destructive, action: onDelete) {
        Label("Delete", systemImage: "trash")
      }
    }
  }
}

private struct ProjectBadge: View {
  let project: ProjectItem

  var body: some View {
    HStack(spacing: 5) {
      Circle()
        .fill(project.color.swiftUIColor)
        .frame(width: 6, height: 6)

      Text(project.name)
        .lineLimit(1)
    }
    .font(.caption2.weight(.semibold))
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .foregroundStyle(.primary)
    .background(project.color.swiftUIColor.opacity(0.12))
    .clipShape(Capsule())
    .accessibilityLabel("Project \(project.name)")
  }
}

private struct PriorityBadge: View {
  let priority: TaskPriority

  var body: some View {
    Label(priority.label, systemImage: "flag.fill")
      .font(.caption2.weight(.semibold))
      .labelStyle(.titleAndIcon)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .foregroundStyle(priority.foregroundColor)
      .background(priority.backgroundColor)
      .clipShape(Capsule())
  }
}

extension TaskPriority {
  fileprivate var sortRank: Int {
    switch self {
    case .high:
      return 0
    case .medium:
      return 1
    case .low:
      return 2
    }
  }

  fileprivate var backgroundColor: Color {
    switch self {
    case .high:
      return Color.red.opacity(0.16)
    case .medium:
      return Color.orange.opacity(0.14)
    case .low:
      return Color.secondary.opacity(0.12)
    }
  }

  fileprivate var foregroundColor: Color {
    switch self {
    case .high:
      return .red
    case .medium:
      return .orange
    case .low:
      return .secondary
    }
  }
}

extension TaskStatus {
  fileprivate var tintColor: Color {
    switch self {
    case .todo:
      return .secondary
    case .doing:
      return .orange
    case .done:
      return .green
    }
  }
}

extension ProjectColor {
  fileprivate var swiftUIColor: Color {
    switch self {
    case .blue:
      return .blue
    case .teal:
      return .teal
    case .orange:
      return .orange
    case .purple:
      return .purple
    case .pink:
      return .pink
    }
  }
}

#Preview {
  ContentView()
}
