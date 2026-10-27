import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct AddProgressPhotoView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let initialWeight: Double

    @State private var date = Date()
    @State private var weightText: String
    @State private var note = ""
    @State private var angle: PhotoAngle = .front

    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedData: Data?
    @State private var preview: UIImage?
    @State private var isLoading = false
    @State private var isSaving = false

    @State private var showingCamera = false
    @State private var cameraImage: UIImage?

    @State private var errorMessage = ""
    @State private var showingError = false

    init(initialWeight: Double) {
        self.initialWeight = initialWeight
        _weightText = State(
            initialValue: initialWeight > 0 ? Formatters.number(initialWeight) : ""
        )
    }

    private var canSave: Bool {
        selectedData != nil && !isSaving
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    previewCard
                    sourceButtons
                    fieldsCard
                    noteCard
                    hint
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .background(ByBackground())
            .safeAreaInset(edge: .bottom) {
                saveButton
            }
            .navigationTitle("Новое фото")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.secondary)
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraPicker(image: $cameraImage)
                    .ignoresSafeArea()
            }
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                loadFromLibrary(item)
            }
            .onChange(of: cameraImage) { _, image in
                guard let image else { return }
                loadFromCamera(image)
            }
            .alert("Не получилось", isPresented: $showingError) {
                Button("Ок", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var previewCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.surface)

            if let preview {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "camera")
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(Theme.tertiary)
                    Text("ВЫБЕРИ ФОТО")
                        .font(ByFont.label)
                        .tracking(1.2)
                        .foregroundStyle(Theme.secondary)
                    Text("Один и тот же свет и ракурс\nдадут честное сравнение")
                        .font(ByFont.regular(11))
                        .foregroundStyle(Theme.tertiary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }

            if isLoading {
                ZStack {
                    Color.black.opacity(0.5)
                    ProgressView()
                        .tint(.white)
                }
            }
        }
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        }
    }

    private var sourceButtons: some View {
        HStack(spacing: 9) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                sourceLabel(title: "Галерея", symbol: "photo.on.rectangle")
            }
            .buttonStyle(.plain)

            Button {
                showingCamera = true
                Haptics.tap()
            } label: {
                sourceLabel(title: "Камера", symbol: "camera.fill")
            }
            .buttonStyle(.plain)
        }
    }

    private func sourceLabel(title: String, symbol: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
            Text(title)
                .font(ByFont.semibold(13))
        }
        .foregroundStyle(Theme.text)
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        }
    }

    private var fieldsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Дата")
                    .font(ByFont.regular(13))
                    .foregroundStyle(Theme.secondary)
                Spacer()
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: .date
                )
                .labelsHidden()
                .tint(Theme.red)
            }
            .padding(.vertical, 10)

            ByDivider()

            HStack {
                Text("Вес")
                    .font(ByFont.regular(13))
                    .foregroundStyle(Theme.secondary)
                Spacer()
                TextField("—", text: $weightText)
                    .font(ByFont.heavy(15))
                    .foregroundStyle(Theme.text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 76)
                Text("кг")
                    .font(ByFont.regular(11))
                    .foregroundStyle(Theme.tertiary)
            }
            .padding(.vertical, 10)

            ByDivider()

            VStack(alignment: .leading, spacing: 9) {
                Text("Ракурс")
                    .font(ByFont.regular(13))
                    .foregroundStyle(Theme.secondary)

                HStack(spacing: 6) {
                    ForEach(PhotoAngle.allCases) { item in
                        Button {
                            angle = item
                            Haptics.tap()
                        } label: {
                            Text(item.title)
                                .font(ByFont.semibold(11))
                                .foregroundStyle(angle == item ? Theme.bg : Theme.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(
                                    angle == item ? Color.white : Color.white.opacity(0.04),
                                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .byCard()
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ЗАМЕТКА")
                .font(ByFont.label)
                .tracking(1.1)
                .foregroundStyle(Theme.secondary)
            TextField("Самочувствие, свет, ракурс…", text: $note, axis: .vertical)
                .font(ByFont.regular(13))
                .foregroundStyle(Theme.text)
                .lineLimit(2...4)
                .byField(minHeight: 72)
        }
        .byCard()
    }

    private var hint: some View {
        Text("Фото сжимается до 2400 px по длинной стороне и хранится только на этом iPhone.")
            .font(ByFont.regular(10.5))
            .foregroundStyle(Theme.tertiary)
            .lineSpacing(2)
            .padding(.horizontal, 4)
    }

    private var saveButton: some View {
        Button {
            savePhoto()
        } label: {
            Text(isSaving ? "Сохраняю…" : "Сохранить фото")
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!canSave)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Theme.bg)
    }

    // MARK: Loading

    private func loadFromLibrary(_ item: PhotosPickerItem) {
        isLoading = true
        Task { @MainActor in
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    await apply(data: data)
                } else {
                    showError("Не удалось прочитать изображение.")
                }
            } catch {
                showError("Фото не загрузилось. Попробуй другое.")
            }
            pickerItem = nil
        }
    }

    private func loadFromCamera(_ image: UIImage) {
        isLoading = true
        Task { @MainActor in
            if let data = image.jpegData(compressionQuality: 0.92) {
                await apply(data: data)
            } else {
                showError("Не удалось обработать снимок.")
            }
            cameraImage = nil
        }
    }

    @MainActor
    private func apply(data: Data) async {
        selectedData = data
        preview = await PhotoStore.shared.preview(from: data, maxPixel: 1400)
        isLoading = false
        Haptics.tap()
    }

    private func showError(_ message: String) {
        isLoading = false
        errorMessage = message
        showingError = true
    }

    // MARK: Save

    private func savePhoto() {
        guard let selectedData, !isSaving else { return }
        isSaving = true

        Task { @MainActor in
            do {
                let fileName = try await PhotoStore.shared.save(data: selectedData)
                let cleanWeight = Double(
                    weightText
                        .replacingOccurrences(of: ",", with: ".")
                        .trimmingCharacters(in: .whitespaces)
                )

                let photo = ProgressPhoto(
                    date: date,
                    fileName: fileName,
                    weightKg: cleanWeight.flatMap { $0 > 0 ? $0 : nil },
                    note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                    angle: angle
                )
                context.insert(photo)
                ProgramStore.save(context)
                Haptics.success()
                dismiss()
            } catch {
                isSaving = false
                showError("Не удалось сохранить фото. Попробуй ещё раз.")
            }
        }
    }
}

// MARK: - Camera

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera)
            ? .camera
            : .photoLibrary
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
