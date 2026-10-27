import SwiftUI
import SwiftData

struct ProgressPhotosSection: View {
    let photos: [ProgressPhoto]
    let initialWeight: Double

    @State private var showingAdd = false
    @State private var showingCompare = false
    @State private var showingDetail = false
    @State private var selectedPhoto: ProgressPhoto?

    private var monthGroups: [PhotoMonthGroup] {
        let grouped = Dictionary(grouping: photos, by: \.monthKey)
        return grouped.compactMap { key, value in
            guard let date = value.first?.date else { return nil }
            return PhotoMonthGroup(
                key: key,
                title: Formatters.monthYearTitle(date),
                photos: value.sorted { $0.date > $1.date }
            )
        }
        .sorted { $0.key > $1.key }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 10) {
                SectionHeader(
                    title: "Фото прогресса",
                    subtitle: photos.isEmpty
                        ? "Раз в месяц — достаточно"
                        : "\(photos.count) фото · \(monthGroups.count) мес."
                )

                Button {
                    showingAdd = true
                    Haptics.tap()
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.bg)
                        .frame(width: 38, height: 38)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Добавить фото")
            }

            if photos.count >= 2 {
                Button {
                    showingCompare = true
                    Haptics.tap()
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "rectangle.split.2x1")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Сравнить месяцы")
                            .font(ByFont.semibold(12))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 14)
                    .frame(height: 42)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .strokeBorder(Theme.stroke, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }

            if photos.isEmpty {
                EmptyStateView(
                    symbol: "camera",
                    title: "Первый кадр",
                    message: "Сфотографируйся сейчас — через месяц увидишь разницу. Свет, ракурс и время лучше не менять.",
                    actionTitle: "Добавить фото",
                    action: {
                        showingAdd = true
                        Haptics.tap()
                    }
                )
                .byCard()
            } else {
                ForEach(monthGroups) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(group.title.uppercased())
                                .font(ByFont.label)
                                .tracking(1.1)
                                .foregroundStyle(Theme.secondary)
                            Spacer()
                            Text("\(group.photos.count)")
                                .font(ByFont.mono(10, weight: .medium))
                                .foregroundStyle(Theme.tertiary)
                        }

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)
                            ],
                            spacing: 10
                        ) {
                            ForEach(group.photos, id: \.id) { photo in
                                photoCard(photo)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddProgressPhotoView(initialWeight: initialWeight)
        }
        .sheet(isPresented: $showingCompare) {
            PhotoCompareFlow(photos: photos)
        }
        .sheet(isPresented: $showingDetail) {
            if let selectedPhoto {
                PhotoDetailView(photo: selectedPhoto)
            }
        }
    }

    private func photoCard(_ photo: ProgressPhoto) -> some View {
        Button {
            selectedPhoto = photo
            showingDetail = true
            Haptics.tap()
        } label: {
            ZStack(alignment: .bottomLeading) {
                StoredPhotoView(fileName: photo.fileName, maxPixel: 760)
                    .frame(height: 218)

                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.78)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(Formatters.shortDate(photo.date).uppercased())
                        .font(ByFont.label)
                        .tracking(0.7)
                        .foregroundStyle(Theme.text)
                    HStack(spacing: 5) {
                        Text(photo.angle.title)
                        if let weight = photo.weightKg {
                            Text("·")
                            Text(Formatters.kg(weight))
                        }
                    }
                    .font(ByFont.regular(10))
                    .foregroundStyle(Color.white.opacity(0.62))
                }
                .padding(12)

                VStack {
                    HStack {
                        Text(photo.angle.title.uppercased())
                            .font(ByFont.micro)
                            .tracking(0.5)
                            .foregroundStyle(Theme.text)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.42), in: Capsule())
                        Spacer()
                    }
                    Spacer()
                }
                .padding(9)
            }
            .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "Фото \(Formatters.fullDate(photo.date))\(photo.weightKg.map { ", \(Formatters.kg($0))" } ?? "")"
        )
    }
}

private struct PhotoMonthGroup: Identifiable {
    let key: String
    let title: String
    let photos: [ProgressPhoto]
    var id: String { key }
}

// MARK: - Detail

struct PhotoDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let photo: ProgressPhoto

    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    StoredPhotoView(
                        fileName: photo.fileName,
                        maxPixel: 1800,
                        contentMode: .fit
                    )
                    .frame(height: 485)
                    .background(Theme.surfaceSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Theme.stroke, lineWidth: 1)
                    }

                    HStack(spacing: 8) {
                        TagPill(text: photo.angle.title)
                        if let weight = photo.weightKg {
                            TagPill(text: Formatters.kg(weight))
                        }
                        Spacer()
                        Text(Formatters.fullDate(photo.date))
                            .font(ByFont.regular(11))
                            .foregroundStyle(Theme.tertiary)
                    }

                    if !photo.note.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ЗАМЕТКА")
                                .font(ByFont.label)
                                .tracking(1.1)
                                .foregroundStyle(Theme.secondary)
                            Text(photo.note)
                                .font(ByFont.regular(13))
                                .foregroundStyle(Theme.text)
                                .lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .byCard()
                    }

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Text("Удалить фото")
                            .font(ByFont.semibold(13))
                            .foregroundStyle(Theme.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(ByBackground())
            .navigationTitle("Фото")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .font(ByFont.semibold(13))
                    .foregroundStyle(Theme.text)
                }
            }
            .alert("Удалить фото?", isPresented: $showingDeleteAlert) {
                Button("Удалить", role: .destructive) {
                    deletePhoto()
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Файл будет удалён с устройства без возможности восстановления.")
            }
        }
    }

    private func deletePhoto() {
        PhotoStore.shared.delete(fileName: photo.fileName)
        context.delete(photo)
        ProgramStore.save(context)
        Haptics.warning()
        dismiss()
    }
}
