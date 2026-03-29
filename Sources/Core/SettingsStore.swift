import Foundation

public final class SettingsStore {
    public let fileURL: URL
    public let legacyFileURLs: [URL]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        fileURL: URL = SettingsStore.defaultFileURL,
        legacyFileURL: URL? = nil,
        legacyFileURLs: [URL] = SettingsStore.legacyDefaultFileURLs
    ) {
        self.fileURL = fileURL
        if let legacyFileURL {
            self.legacyFileURLs = [legacyFileURL]
        } else {
            self.legacyFileURLs = legacyFileURLs.filter {
                $0.standardizedFileURL != fileURL.standardizedFileURL
            }
        }
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func load() throws -> AppSettings {
        try migrateLegacySettingsIfNeeded()

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .default
        }

        let data = try Data(contentsOf: fileURL)
        let decoded = try decoder.decode(AppSettings.self, from: data)
        let migrated = decoded.migrated()
        if migrated != decoded {
            try save(migrated)
        }
        return migrated
    }

    public func save(_ settings: AppSettings) throws {
        let data = try encoder.encode(settings.migrated())
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        try data.write(to: fileURL, options: .atomic)
    }

    public static var legacyDefaultFileURL: URL {
        legacyDefaultFileURLs.last ?? defaultFileURL
    }

    public static var legacyDefaultFileURLs: [URL] {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return [
            base
                .appendingPathComponent("nook", isDirectory: true)
                .appendingPathComponent("settings.json", isDirectory: false),
            base
                .appendingPathComponent("Nook", isDirectory: true)
                .appendingPathComponent("settings.json", isDirectory: false),
        ]
    }

    public static var defaultFileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return base
            .appendingPathComponent("knook", isDirectory: true)
            .appendingPathComponent("settings.json", isDirectory: false)
    }

    private func migrateLegacySettingsIfNeeded() throws {
        guard !FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }

        guard let legacyFileURL = legacyFileURLs.first(where: {
            FileManager.default.fileExists(atPath: $0.path)
        }) else {
            return
        }

        let data = try Data(contentsOf: legacyFileURL)
        let decoded = try decoder.decode(AppSettings.self, from: data)
        try save(decoded.migrated())
    }
}
