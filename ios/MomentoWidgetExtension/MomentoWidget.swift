import WidgetKit
import SwiftUI

struct MomentoEntry: TimelineEntry {
    let date: Date
    let imagePath: String
    let senderName: String
    let index: Int
    let total: Int
}

struct MomentoProvider: TimelineProvider {
    let appGroupId = "group.com.momento.momento"

    func placeholder(in context: Context) -> MomentoEntry {
        MomentoEntry(date: Date(), imagePath: "", senderName: "Friend", index: 0, total: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (MomentoEntry) -> Void) {
        let entries = loadEntries()
        completion(entries.first ?? placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MomentoEntry>) -> Void) {
        let entries = loadEntries()

        if entries.isEmpty {
            let entry = MomentoEntry(date: Date(), imagePath: "", senderName: "", index: 0, total: 0)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
            return
        }

        if entries.count == 1 {
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            completion(Timeline(entries: entries, policy: .after(nextUpdate)))
            return
        }

        // Multiple photos: create timeline entries every 3 seconds, cycling through all photos
        var timedEntries: [MomentoEntry] = []
        let now = Date()
        // Create 60 entries (3 minutes of rotation), then refresh
        for i in 0..<60 {
            let entryDate = now.addingTimeInterval(Double(i) * 3.0)
            let photoIndex = i % entries.count
            let original = entries[photoIndex]
            timedEntries.append(MomentoEntry(
                date: entryDate,
                imagePath: original.imagePath,
                senderName: original.senderName,
                index: original.index,
                total: original.total
            ))
        }

        let nextRefresh = now.addingTimeInterval(180) // 3 minutes
        completion(Timeline(entries: timedEntries, policy: .after(nextRefresh)))
    }

    private func loadEntries() -> [MomentoEntry] {
        let defaults = UserDefaults(suiteName: appGroupId)
        let pathsJson = defaults?.string(forKey: "momento_image_paths") ?? "[]"
        let namesJson = defaults?.string(forKey: "momento_senders") ?? "[]"

        guard let pathsData = pathsJson.data(using: .utf8),
              let namesData = namesJson.data(using: .utf8),
              let paths = try? JSONDecoder().decode([String].self, from: pathsData),
              let names = try? JSONDecoder().decode([String].self, from: namesData)
        else {
            // Fallback to single image
            let path = defaults?.string(forKey: "momento_image_path") ?? ""
            let name = defaults?.string(forKey: "momento_sender") ?? ""
            if path.isEmpty { return [] }
            return [MomentoEntry(date: Date(), imagePath: path, senderName: name, index: 0, total: 1)]
        }

        if paths.isEmpty { return [] }

        return paths.enumerated().map { (i, path) in
            let name = i < names.count ? names[i] : ""
            return MomentoEntry(date: Date(), imagePath: path, senderName: name, index: i, total: paths.count)
        }
    }
}

struct MomentoWidgetEntryView: View {
    var entry: MomentoEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.imagePath.isEmpty {
            emptyState
        } else {
            photoState
        }
    }

    var emptyState: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FF6B6B"), Color(hex: "FF9A56")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .font(.system(size: family == .systemSmall ? 24 : 32))
                    .foregroundColor(.white.opacity(0.8))
                Text("Momento")
                    .font(.system(size: family == .systemSmall ? 12 : 16, weight: .bold))
                    .foregroundColor(.white)
                Text("No new photos")
                    .font(.system(size: family == .systemSmall ? 10 : 12))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    var photoState: some View {
        ZStack(alignment: .bottom) {
            // Photo
            if let uiImage = UIImage(contentsOfFile: entry.imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color(hex: "FFB7B2")
            }

            // Bottom overlay with sender name
            VStack(spacing: 0) {
                Spacer()
                HStack {
                    Text(entry.senderName)
                        .font(.system(size: family == .systemSmall ? 11 : 14, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    // Page indicator
                    if entry.total > 1 {
                        Text("\(entry.index + 1)/\(entry.total)")
                            .font(.system(size: family == .systemSmall ? 9 : 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.black.opacity(0.3))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
}

@main
struct MomentoWidget: Widget {
    let kind: String = "MomentoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MomentoProvider()) { entry in
            MomentoWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(hex: "FFF5EE")
                }
        }
        .configurationDisplayName("Momento")
        .description("See your friends' latest photos")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
