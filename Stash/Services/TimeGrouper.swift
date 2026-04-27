import Foundation

enum TimeGrouper {
    enum Group: String, CaseIterable {
        case justNow = "Just now"
        case today = "Today"
        case yesterday = "Yesterday"
        case lastWeek = "Last week"
        case older = "Older"
    }

    static func group(for date: Date) -> Group {
        let now = Date()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            let interval = now.timeIntervalSince(date)
            if interval < 300 { // 5 minutes
                return .justNow
            }
            return .today
        }

        if calendar.isDateInYesterday(date) {
            return .yesterday
        }

        if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
           date > weekAgo {
            return .lastWeek
        }

        return .older
    }

    static func groupClips(_ clips: [Clip]) -> [(Group, [Clip])] {
        var groups: [(Group, [Clip])] = []
        var currentGroup: Group?
        var currentClips: [Clip] = []

        for clip in clips {
            let g = group(for: clip.createdAt)
            if g != currentGroup {
                if !currentClips.isEmpty {
                    groups.append((currentGroup!, currentClips))
                }
                currentGroup = g
                currentClips = [clip]
            } else {
                currentClips.append(clip)
            }
        }

        if !currentClips.isEmpty, let g = currentGroup {
            groups.append((g, currentClips))
        }

        return groups
    }
}
