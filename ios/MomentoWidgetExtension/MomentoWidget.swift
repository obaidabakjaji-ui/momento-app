import WidgetKit
import SwiftUI

// MARK: - Data model

struct MomentoEntry: TimelineEntry {
    let date: Date
    let imagePath: String
    let senderName: String
    let roomName: String
    let caption: String
    let likeCount: Int
    let createdAt: Date?
    let isFavorite: Bool
    let isVideo: Bool
    let index: Int
    let total: Int
}

// MARK: - Timeline provider

struct MomentoProvider: TimelineProvider {
    let appGroupId = "group.com.momento.momento"

    func placeholder(in context: Context) -> MomentoEntry {
        MomentoEntry(
            date: Date(),
            imagePath: "",
            senderName: "Friend",
            roomName: "",
            caption: "",
            likeCount: 0,
            createdAt: Date(),
            isFavorite: false,
            isVideo: false,
            index: 0,
            total: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MomentoEntry) -> Void) {
        let entries = loadEntries()
        completion(entries.first ?? placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MomentoEntry>) -> Void) {
        let entries = loadEntries()

        if entries.isEmpty {
            let entry = MomentoEntry(
                date: Date(), imagePath: "", senderName: "", roomName: "",
                caption: "", likeCount: 0, createdAt: nil,
                isFavorite: false, isVideo: false, index: 0, total: 0
            )
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
            return
        }

        if entries.count == 1 {
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            completion(Timeline(entries: entries, policy: .after(nextUpdate)))
            return
        }

        // Multiple photos: create timeline entries every 3 seconds, cycling through all photos.
        // 60 entries = 3 minutes of rotation, then refresh.
        var timedEntries: [MomentoEntry] = []
        let now = Date()
        for i in 0..<60 {
            let entryDate = now.addingTimeInterval(Double(i) * 3.0)
            let photoIndex = i % entries.count
            let original = entries[photoIndex]
            timedEntries.append(MomentoEntry(
                date: entryDate,
                imagePath: original.imagePath,
                senderName: original.senderName,
                roomName: original.roomName,
                caption: original.caption,
                likeCount: original.likeCount,
                createdAt: original.createdAt,
                isFavorite: original.isFavorite,
                isVideo: original.isVideo,
                index: original.index,
                total: original.total
            ))
        }

        let nextRefresh = now.addingTimeInterval(180)
        completion(Timeline(entries: timedEntries, policy: .after(nextRefresh)))
    }

    private func loadEntries() -> [MomentoEntry] {
        let defaults = UserDefaults(suiteName: appGroupId)
        let paths = decodeArray(defaults?.string(forKey: "momento_image_paths"), of: String.self)
        let names = decodeArray(defaults?.string(forKey: "momento_senders"), of: String.self)
        let rooms = decodeArray(defaults?.string(forKey: "momento_rooms"), of: String.self)
        let favs = decodeArray(defaults?.string(forKey: "momento_favorites"), of: Bool.self)
        let captions = decodeArray(defaults?.string(forKey: "momento_captions"), of: String.self)
        let likes = decodeArray(defaults?.string(forKey: "momento_likes"), of: Int.self)
        let createdAtsMs = decodeArray(defaults?.string(forKey: "momento_created_ats"), of: Int64.self)
        let videos = decodeArray(defaults?.string(forKey: "momento_is_videos"), of: Bool.self)

        if paths.isEmpty {
            // Legacy single-image fallback
            let path = defaults?.string(forKey: "momento_image_path") ?? ""
            let name = defaults?.string(forKey: "momento_sender") ?? ""
            if path.isEmpty { return [] }
            return [MomentoEntry(
                date: Date(), imagePath: path, senderName: name,
                roomName: "", caption: "", likeCount: 0,
                createdAt: nil, isFavorite: false, isVideo: false,
                index: 0, total: 1
            )]
        }

        return paths.enumerated().map { (i, path) in
            let createdAt: Date? = {
                guard i < createdAtsMs.count else { return nil }
                let ms = createdAtsMs[i]
                guard ms > 0 else { return nil }
                return Date(timeIntervalSince1970: Double(ms) / 1000.0)
            }()
            return MomentoEntry(
                date: Date(),
                imagePath: path,
                senderName: i < names.count ? names[i] : "",
                roomName: i < rooms.count ? rooms[i] : "",
                caption: i < captions.count ? captions[i] : "",
                likeCount: i < likes.count ? likes[i] : 0,
                createdAt: createdAt,
                isFavorite: i < favs.count ? favs[i] : false,
                isVideo: i < videos.count ? videos[i] : false,
                index: i,
                total: paths.count
            )
        }
    }

    private func decodeArray<T: Decodable>(_ json: String?, of: T.Type) -> [T] {
        guard let data = json?.data(using: .utf8),
              let arr = try? JSONDecoder().decode([T].self, from: data) else {
            return []
        }
        return arr
    }
}

// MARK: - Time formatting

private func relativeTime(_ date: Date?) -> String? {
    guard let date = date else { return nil }
    let now = Date()
    let delta = now.timeIntervalSince(date)
    if delta < 60 { return "now" }
    if delta < 3600 { return "\(Int(delta / 60))m" }
    if delta < 86400 { return "\(Int(delta / 3600))h" }
    return "\(Int(delta / 86400))d"
}

// MARK: - Widget view

struct MomentoWidgetEntryView: View {
    var entry: MomentoEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.imagePath.isEmpty {
            EmptyStateView()
        } else {
            switch family {
            case .systemMedium:
                MediumPhotoView(entry: entry)
            default:
                SmallPhotoView(entry: entry)
            }
        }
    }
}

// MARK: - Small widget

struct SmallPhotoView: View {
    let entry: MomentoEntry

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Photo — explicitly framed to widget bounds so .fill cropping
                // doesn't blow up the parent ZStack size.
                Group {
                    if let uiImage = UIImage(contentsOfFile: entry.imagePath) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        BrandGradient()
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()

                LinearGradient(
                    colors: [
                        .clear, .clear,
                        Color.black.opacity(0.25),
                        Color.black.opacity(0.75)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: 0) {
                    HStack {
                        if let rel = relativeTime(entry.createdAt) {
                            Chip(text: rel, systemImage: "clock.fill")
                        }
                        Spacer()
                        if entry.total > 1 {
                            Chip(text: "\(entry.index + 1)/\(entry.total)")
                        }
                    }
                    Spacer()
                    BottomLabel(entry: entry, compact: true)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                if entry.isFavorite {
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color(hex: "FF9A56"))
                            .frame(height: 3)
                    }
                }

                if entry.isVideo {
                    PlayBadge(size: 44)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Medium widget

struct MediumPhotoView: View {
    let entry: MomentoEntry

    var body: some View {
        HStack(spacing: 0) {
            // Photo occupies ~58% of width
            ZStack {
                if let uiImage = UIImage(contentsOfFile: entry.imagePath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    BrandGradient()
                }
                // Subtle vignette so photo feels bound on the right edge
                LinearGradient(
                    colors: [.clear, .black.opacity(0.15)],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                if entry.isVideo {
                    PlayBadge(size: 38)
                }
            }
            .frame(maxWidth: .infinity)
            .clipped()

            // Info panel
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    if entry.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "FF9A56"))
                    }
                    Text(entry.roomName.isEmpty ? " " : entry.roomName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "2D2337").opacity(0.55))
                        .lineLimit(1)
                }

                Text(entry.senderName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "2D2337"))
                    .lineLimit(1)

                if !entry.caption.isEmpty {
                    Text(entry.caption)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "2D2337").opacity(0.8))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 2)
                }

                Spacer(minLength: 0)

                HStack(spacing: 10) {
                    if entry.likeCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(hex: "FF6B6B"))
                            Text("\(entry.likeCount)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "2D2337"))
                        }
                    }
                    if let rel = relativeTime(entry.createdAt) {
                        Text(rel)
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "2D2337").opacity(0.5))
                    }
                    Spacer()
                    if entry.total > 1 {
                        Text("\(entry.index + 1)/\(entry.total)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: "2D2337").opacity(0.4))
                    }
                }
            }
            .padding(12)
            .frame(width: 140)
            .background(
                Color(hex: "FFF5EE")
                    .overlay(
                        // Coral accent on left edge if favorite
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: entry.isFavorite
                                            ? [Color(hex: "FF6B6B"), Color(hex: "FF9A56")]
                                            : [Color.clear, Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: entry.isFavorite ? 3 : 0)
                            Spacer()
                        }
                    )
            )
        }
    }
}

// MARK: - Shared pieces

struct BottomLabel: View {
    let entry: MomentoEntry
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(entry.senderName)
                .font(.system(size: compact ? 11 : 14, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(0.7)
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)

            HStack(spacing: 5) {
                if !entry.roomName.isEmpty {
                    Text(entry.roomName)
                        .font(.system(size: compact ? 9 : 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                if entry.likeCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: compact ? 8 : 9, weight: .medium))
                        Text("\(entry.likeCount)")
                            .font(.system(size: compact ? 9 : 10, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "FFB7B2").opacity(0.9))
                }
            }

            if !compact && !entry.caption.isEmpty {
                Text(entry.caption)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                    .padding(.top, 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Centered translucent play glyph shown over a video post's poster.
struct PlayBadge: View {
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.45))
                .frame(width: size, height: size)
            Image(systemName: "play.fill")
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundColor(.white)
                .offset(x: size * 0.04) // optical center for triangle glyph
        }
    }
}

struct Chip: View {
    var text: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 2) {
            if let sym = systemImage {
                Image(systemName: sym)
                    .font(.system(size: 7, weight: .medium))
            }
            Text(text)
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundColor(.white.opacity(0.85))
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
            Capsule().fill(Color.black.opacity(0.28))
        )
    }
}

struct BrandGradient: View {
    var body: some View {
        LinearGradient(
            colors: [Color(hex: "FF6B6B"), Color(hex: "FF9A56")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            BrandGradient()

            // Soft decorative halo
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 140, height: 140)
                .offset(x: -40, y: -40)

            VStack(spacing: 6) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: family == .systemSmall ? 26 : 34,
                                  weight: .light))
                    .foregroundColor(.white.opacity(0.95))
                Text("Momento")
                    .font(.system(size: family == .systemSmall ? 13 : 16,
                                  weight: .bold))
                    .foregroundColor(.white)
                Text("Your rooms are waiting")
                    .font(.system(size: family == .systemSmall ? 10 : 12,
                                  weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .shadow(color: .black.opacity(0.15), radius: 6)
        }
    }
}

// MARK: - Widget config

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
        .description("See the latest photos from your rooms")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Helpers

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
