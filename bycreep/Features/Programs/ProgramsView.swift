import SwiftUI
import SwiftData

struct ProgramsView: View {
    @Environment(\.modelContext) private var context
    @Bindable var profile: UserProfile

    @Query(sort: \Program.createdAt, order: .reverse)
    private var programs: [Program]

    @State private var showingGenerator = false
    @State private var showingEditor = false
    @State private var editorProgram: Program?
    @State private var programToDelete: Program?
    @State private var showingDeleteAlert = false

    private var activeProgram: Program? {
        programs.first(where: { $0.isActive })
    }

    private var otherPrograms: [Program] {
        programs.filter { !$0.isActive }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                generatorBanner

                if let activeProgram {
                    SectionHeader(title: "Активная", subtitle: "Именно она задаёт неделю и виджет")
                    NavigationLink {
                        ProgramDetailView(program: activeProgram)
                    } label: {
                        ActiveProgramCard(program: activeProgram)
                    }
                    .buttonStyle(.plain)
                }

                if !otherPrograms.isEmpty {
                    SectionHeader(title: "Мои программы")
                    VStack(spacing: 10) {
                        ForEach(otherPrograms, id: \.id) { program in
                            programRow(program)
                        }
                    }
                }

                if programs.isEmpty {
                    EmptyStateView(
                        symbol: "dumbbell",
                        title: "Пока пусто",
                        message: "Собери программу по параметрам или добавь упражнения вручную.",
                        actionTitle: nil,
                        action: nil
                    )
                    .byCard()
                }

                Button {
                    createProgram()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .black))
                        Text("Создать вручную")
                    }
                }
                .buttonStyle(GhostButtonStyle())

                Text("Активной может быть только одна программа. Дни и упражнения можно менять в любой момент.")
                    .font(ByFont.regular(11))
                    .foregroundStyle(Theme.tertiary)
                    .lineSpacing(2)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(ByBackground())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingGenerator) {
            GeneratorView(profile: profile)
        }
        .sheet(isPresented: $showingEditor) {
            if let editorProgram {
                ProgramEditorView(program: editorProgram)
            }
        }
        .alert(
            "Удалить программу?",
            isPresented: $showingDeleteAlert,
            presenting: programToDelete
        ) { program in
            Button("Удалить", role: .destructive) {
                ProgramStore.delete(program, context: context)
                Haptics.warning()
            }
            Button("Отмена", role: .cancel) {}
        } message: { program in
            Text("«\(program.name)» и все её дни будут удалены. История тренировок останется.")
        }
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ScreenTitle(eyebrow: "02 · Планы", title: "Тренировки")

            Spacer(minLength: 8)

            Button {
                createProgram()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .frame(width: 44, height: 44)
                    .background(Theme.surfaceElevated, in: Circle())
                    .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Добавить программу")
        }
    }

    private var generatorBanner: some View {
        Button {
            showingGenerator = true
            Haptics.tap()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.redSoft)
                        .frame(width: 46, height: 46)
                    Image(systemName: "sparkles")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.red)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("СОБРАТЬ ПОД СЕБЯ")
                        .font(ByFont.label)
                        .tracking(1.1)
                        .foregroundStyle(Theme.red)
                    Text("Идеальная тяжёлая программа")
                        .font(ByFont.semibold(14))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                    Text("Сплит и веса по твоим параметрам")
                        .font(ByFont.regular(11))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.text)
            }
            .byCard(padding: 14, radius: 20)
        }
        .buttonStyle(.plain)
    }

    private func programRow(_ program: Program) -> some View {
        HStack(spacing: 10) {
            NavigationLink {
                ProgramDetailView(program: program)
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(program.name)
                            .font(ByFont.semibold(15))
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                        HStack(spacing: 5) {
                            Text("\(program.days.count) дн.")
                            Text("·")
                            Text("\(program.totalExercises) упражн.")
                            if program.source == "generated" {
                                Text("·")
                                Text("AUTO")
                            }
                        }
                        .font(ByFont.regular(11))
                        .foregroundStyle(Theme.tertiary)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                Button {
                    ProgramStore.activate(program, context: context)
                    Haptics.impact()
                } label: {
                    Label("Сделать активной", systemImage: "bolt.fill")
                }

                Button {
                    editorProgram = program
                    showingEditor = true
                } label: {
                    Label("Изменить", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    programToDelete = program
                    showingDeleteAlert = true
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
                    .frame(width: 34, height: 40)
                    .contentShape(Rectangle())
            }
        }
        .byCard(padding: 14, radius: 18)
    }

    private func createProgram() {
        let program = Program(name: "Новая программа")
        context.insert(program)

        let day = ProgramDay(
            weekday: WeekClock.weekdayIndex(for: Date()),
            title: "ДЕНЬ 1",
            order: 0
        )
        context.insert(day)
        program.days.append(day)

        if activeProgram == nil {
            program.isActive = true
        }

        ProgramStore.save(context)
        WidgetBridge.refresh(context: context)
        editorProgram = program
        showingEditor = true
        Haptics.impact()
    }
}

private struct ActiveProgramCard: View {
    let program: Program

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                TagPill(text: "Активна", color: Theme.text, fill: Theme.red)
                Spacer()
                Text(program.source == "generated" ? "AUTO" : "MANUAL")
                    .font(ByFont.micro)
                    .tracking(0.8)
                    .foregroundStyle(Theme.tertiary)
            }

            Text(program.name)
                .font(ByFont.display(25))
                .tracking(-0.6)
                .foregroundStyle(Theme.text)
                .lineLimit(2)

            HStack(spacing: 8) {
                stat("\(program.days.count)", Formatters.plural(program.days.count, one: "день", few: "дня", many: "дней"))
                stat("\(program.totalExercises)", Formatters.plural(program.totalExercises, one: "упражнение", few: "упражнения", many: "упражнений"))
                stat("~\(program.estimatedMinutes)", "мин")
            }

            HStack(spacing: 5) {
                ForEach(program.trainingWeekdays, id: \.self) { weekday in
                    Text(Formatters.weekdayShort(weekday))
                        .font(ByFont.micro)
                        .tracking(0.4)
                        .foregroundStyle(Theme.text)
                        .frame(width: 30, height: 24)
                        .background(Color.white.opacity(0.07), in: Capsule())
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .byCard()
        .overlay {
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .strokeBorder(Theme.red.opacity(0.22), lineWidth: 1)
        }
    }

    private func stat(_ value: String, _ caption: String) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(ByFont.mono(12, weight: .semibold))
                .foregroundStyle(Theme.text)
            Text(caption)
                .font(ByFont.regular(10))
                .foregroundStyle(Theme.tertiary)
        }
    }
}
