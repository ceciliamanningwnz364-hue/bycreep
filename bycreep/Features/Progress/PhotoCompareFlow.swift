import SwiftUI
import SwiftData
import UIKit

struct PhotoCompareFlow: View {
    @Environment(\.dismiss) private var dismiss

    let photos: [ProgressPhoto]

    @State private var selection: [UUID] = []
    @State private var showingComparison = false
    @State private var comparisonPair: [ProgressPhoto] = []

    private var selectedPhotos: [ProgressPhoto] {
        selection.compactMap { id in
            photos.first(where: { $0.id == id })
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("ДО / ПОСЛЕ")
                            .font(ByFont.label)
                            .tracking(1.4)
                            .foregroundStyle(Theme.red)
                        Text("Выбери два фото")
                            .font(ByFont.display(30))
                            .tracking(-0.8)
                            .foregroundStyle(Theme.text)
                        Text("Лучше выбирать одинаковый ракурс и освещение — так разница честнее.")
                            .font(ByFont.regular(12))
                            .foregroundStyle(Theme.secondary)
                            .lineSpacing(2)
                    }
                    .padding(.top, 4)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 7),
                            GridItem(.flexible(), spacing: 7),
                            GridItem(.flexible(), spacing: 7)
                        ],
                        spacing: 7
                    ) {
                        ForEach(photos, id: \.id) { photo in
                            selectionCard(photo)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 22)
            }
            .scrollIndicators(.hidden)
            .background(ByBackground())
            .safeAreaInset(edge: .bottom) {
                compareButton
            }
            .navigationTitle("Сравнение")
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
            .navigationDestination(isPresented: $showingComparison) {
                if comparisonPair.count == 2 {
                    PhotoCompareView(
                        photoA: comparisonPair[0],
                        photoB: comparisonPair[1],
                        onClose: { showingComparison = false }
                    )
                }
            }
        }
    }

    private func selectionCard(_ photo: ProgressPhoto) -> some View {
        let index = selection.firstIndex(of: photo.id)

        return Button {
            if let index {
                selection.remove(at: index)
                Haptics.tap()
            } else if selection.count < 2 {
                selection.append(photo.id)
                Haptics.tap()
            } else {
                Haptics.warning()
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                StoredPhotoView(fileName: photo.fileName, maxPixel: 500)
                    .frame(height: 142)

                if let index {
                    Text(index == 0 ? "A" : "B")
                        .font(ByFont.heavy(12))
                        .foregroundStyle(Theme.bg)
                        .frame(width: 26, height: 26)
                        .background(Color.white, in: Circle())
                        .padding(7)
                }

                VStack {
                    Spacer()
                    HStack {
                        Text(Formatters.shortDate(photo.date))
                            .font(ByFont.semibold(9))
                            .foregroundStyle(Theme.text)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.55), in: Capsule())
                        Spacer(minLength: 0)
                    }
                }
                .padding(6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        index == nil ? Theme.stroke : Color.white,
                        lineWidth: index == nil ? 1 : 2
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private var compareButton: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Theme.bg.opacity(0), Theme.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 14)

            Button {
                let ordered = selectedPhotos.sorted { $0.date < $1.date }
                guard ordered.count == 2 else { return }
                comparisonPair = ordered
                showingComparison = true
                Haptics.impact()
            } label: {
                HStack(spacing: 8) {
                    Text("Сравнить")
                    Image(systemName: "rectangle.split.2x1")
                        .font(.system(size: 11, weight: .bold))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selection.count != 2)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(Theme.bg)
    }
}

// MARK: - Comparison slider

struct PhotoCompareView: View {
    let photoA: ProgressPhoto
    let photoB: ProgressPhoto
    let onClose: () -> Void

    @State private var imageA: UIImage?
    @State private var imageB: UIImage?
    @State private var split: CGFloat = 0.5

    private var weightDelta: Double? {
        guard let first = photoA.weightKg, let second = photoB.weightKg else {
            return nil
        }
        return second - first
    }

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { proxy in
                let size = proxy.size

                ZStack {
                    comparisonImage(imageA, size: size)
                        .overlay(alignment: .topLeading) {
                            photoBadge(photoA, caption: "ДО")
                                .padding(12)
                        }

                    comparisonImage(imageB, size: size)
                        .mask(alignment: .trailing) {
                            Rectangle()
                                .frame(width: size.width * (1 - split))
                        }
                        .overlay(alignment: .topTrailing) {
                            photoBadge(photoB, caption: "ПОСЛЕ")
                                .padding(12)
                        }

                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2)
                        .position(x: size.width * split, y: size.height / 2)

                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                        HStack(spacing: 1) {
                            Image(systemName: "chevron.left")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(Theme.bg)
                    }
                    .position(x: size.width * split, y: size.height / 2)
                    .shadow(color: Color.black.opacity(0.35), radius: 6, y: 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Theme.stroke, lineWidth: 1)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            split = min(max(value.location.x / max(size.width, 1), 0.05), 0.95)
                        }
                )
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Formatters.shortDate(photoA.date))
                        .font(ByFont.semibold(11))
                        .foregroundStyle(Theme.secondary)
                    Text(photoA.weightKg.map { Formatters.kg($0) } ?? "вес не указан")
                        .font(ByFont.regular(10))
                        .foregroundStyle(Theme.tertiary)
                }

                Spacer()

                if let weightDelta, abs(weightDelta) >= 0.05 {
                    TagPill(
                        text: "\(weightDelta > 0 ? "+" : "−")\(Formatters.number(abs(weightDelta))) кг",
                        color: Theme.text,
                        fill: Theme.redSoft
                    )
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(Formatters.shortDate(photoB.date))
                        .font(ByFont.semibold(11))
                        .foregroundStyle(Theme.secondary)
                    Text(photoB.weightKg.map { Formatters.kg($0) } ?? "вес не указан")
                        .font(ByFont.regular(10))
                        .foregroundStyle(Theme.tertiary)
                }
            }
            .padding(.horizontal, 4)

            Text("Двигай ползунок, чтобы увидеть разницу")
                .font(ByFont.regular(10))
                .foregroundStyle(Theme.tertiary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(ByBackground())
        .navigationTitle("До / после")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Закрыть") {
                    onClose()
                }
                .font(ByFont.semibold(13))
                .foregroundStyle(Theme.text)
            }
        }
        .task {
            async let loadedA = PhotoStore.shared.image(
                fileName: photoA.fileName,
                maxPixel: 1800
            )
            async let loadedB = PhotoStore.shared.image(
                fileName: photoB.fileName,
                maxPixel: 1800
            )
            let (first, second) = await (loadedA, loadedB)
            guard !Task.isCancelled else { return }
            imageA = first
            imageB = second
        }
    }

    @ViewBuilder
    private func comparisonImage(_ image: UIImage?, size: CGSize) -> some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
        } else {
            ZStack {
                Theme.surfaceSoft
                ProgressView()
                    .tint(Theme.tertiary)
            }
            .frame(width: size.width, height: size.height)
        }
    }

    private func photoBadge(_ photo: ProgressPhoto, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(caption)
                .font(ByFont.label)
                .tracking(1)
                .foregroundStyle(Theme.text)
            Text(Formatters.shortDate(photo.date))
                .font(ByFont.regular(9))
                .foregroundStyle(Color.white.opacity(0.7))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}
