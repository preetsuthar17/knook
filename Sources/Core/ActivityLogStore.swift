import Foundation

public final class ActivityLogStore {
    public let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let minimumSamples: Int

    public init(fileURL: URL = ActivityLogStore.defaultFileURL, minimumSamples: Int = 5) {
        self.fileURL = fileURL
        self.minimumSamples = minimumSamples
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func load() -> ActivityLogData {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode(ActivityLogData.self, from: data)
        else {
            return .empty
        }
        return decoded
    }

    public func save(_ log: ActivityLogData) {
        guard let data = try? encoder.encode(log) else { return }
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        try? data.write(to: fileURL, options: .atomic)
    }

    public func recordActivity(at date: Date, calendar: Calendar = .current) {
        var log = load()
        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)
        let todayKey = BreakStatsData.dateKey(for: date)

        let isNewDay = log.lastRecordedDate != todayKey

        if let index = log.weekdayLogs.firstIndex(where: { $0.weekday == weekday }) {
            log.weekdayLogs[index].activeHours.insert(hour)
            if isNewDay {
                log.weekdayLogs[index].sampleCount += 1
            }
        } else {
            log.weekdayLogs.append(WeekdayActivityLog(
                weekday: weekday,
                activeHours: [hour],
                sampleCount: 1
            ))
        }

        log.lastRecordedDate = todayKey
        save(log)
    }

    public func suggestedOfficeHours() -> [OfficeHoursRule] {
        let log = load()
        var rules: [OfficeHoursRule] = []

        for weekdayLog in log.weekdayLogs {
            guard weekdayLog.sampleCount >= minimumSamples,
                  !weekdayLog.activeHours.isEmpty else { continue }

            let sorted = weekdayLog.activeHours.sorted()
            let startMinutes = sorted.first! * 60
            let endMinutes = (sorted.last! + 1) * 60

            rules.append(OfficeHoursRule(
                weekday: weekdayLog.weekday,
                startMinutes: startMinutes,
                endMinutes: min(endMinutes, 24 * 60)
            ))
        }

        return rules.sorted { $0.weekday < $1.weekday }
    }

    public func hasEnoughData() -> Bool {
        let log = load()
        return log.weekdayLogs.contains { $0.sampleCount >= minimumSamples }
    }

    public static var defaultFileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return base
            .appendingPathComponent("knook", isDirectory: true)
            .appendingPathComponent("activity-log.json", isDirectory: false)
    }
}
