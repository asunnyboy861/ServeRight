import SwiftUI
import SwiftData

struct LetterArchiveView: View {
    @Query private var letters: [LetterArchive]
    @State private var previewLetter: LetterArchive?

    private var sorted: [LetterArchive] {
        letters.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        Group {
            if sorted.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 44))
                        .foregroundStyle(.tertiary)
                    Text("No letters yet")
                        .font(.title3.bold())
                    Text("Letters you generate and mark as served are archived here with timestamps as your compliance evidence chain.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else {
                List {
                    ForEach(sorted) { letter in
                        Button {
                            previewLetter = letter
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(letter.letterType.displayName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(letter.deliveryMethod)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.accentColor.opacity(0.12))
                                        .foregroundStyle(Color.accentColor)
                                        .cornerRadius(6)
                                }
                                Text("\(letter.tenantName) · \(letter.propertyLabel)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Text("Served \(letter.createdAt.formatted(date: .abbreviated, time: .shortened)) · \(letter.statuteCitation)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .navigationTitle("Letter Archive")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $previewLetter) { letter in
            NavigationStack {
                PDFKitView(data: letter.pdfData)
                    .ignoresSafeArea(edges: .bottom)
                    .navigationTitle(letter.letterType.displayName)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
