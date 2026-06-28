import Foundation

public enum ContentRepositoryError: LocalizedError, Equatable {
    case missingFile(String)
    case decodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .missingFile(let path):
            "Missing content file: \(path)"
        case .decodingFailed(let path):
            "Could not decode content file: \(path)"
        }
    }
}

public protocol ContentRepository {
    func loadVariants() throws -> [AppVariant]
    func loadContent(appSlug: String) throws -> AppContent
}

public struct FileContentRepository: ContentRepository {
    private let appsDirectory: URL
    private let manifestURL: URL
    private let decoder = JSONDecoder()

    public init(appsDirectory: URL, manifestURL: URL? = nil) {
        self.appsDirectory = appsDirectory
        self.manifestURL = manifestURL ?? appsDirectory.deletingLastPathComponent().appendingPathComponent("apps_manifest.json")
    }

    public func loadVariants() throws -> [AppVariant] {
        let manifest: AppsManifest = try decode(manifestURL)
        return manifest.apps
    }

    public func loadContent(appSlug: String) throws -> AppContent {
        let appDirectory = appsDirectory.appendingPathComponent(appSlug, isDirectory: true)
        let manifest: AppManifest = try decode(appDirectory.appendingPathComponent("manifest.json"))
        let categories: [GuideCategory] = try decode(appDirectory.appendingPathComponent("categories.json"))
        let diagrams: [Diagram] = try decode(appDirectory.appendingPathComponent("diagrams.json"))
        let videos: [VideoLesson] = try decode(appDirectory.appendingPathComponent("videos.json"))
        let uiCopy: UICopy = try decode(appDirectory.appendingPathComponent("ui_copy.json"))
        return AppContent(
            manifest: manifest,
            categories: categories.sorted { $0.order < $1.order },
            diagrams: diagrams.sorted { $0.order < $1.order },
            videos: videos.sorted { $0.order < $1.order },
            uiCopy: uiCopy
        )
    }

    private func decode<T: Decodable>(_ url: URL) throws -> T {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ContentRepositoryError.missingFile(url.path)
        }
        do {
            return try decoder.decode(T.self, from: Data(contentsOf: url))
        } catch {
            throw ContentRepositoryError.decodingFailed(url.path)
        }
    }
}

public struct BundleContentRepository: ContentRepository {
    private let repository: FileContentRepository

    public init(bundle: Bundle = .main) throws {
        guard let appsDirectory = bundle.url(forResource: "apps", withExtension: nil) else {
            throw ContentRepositoryError.missingFile("apps")
        }
        let manifestURL = bundle.url(forResource: "apps_manifest", withExtension: "json")
        repository = FileContentRepository(appsDirectory: appsDirectory, manifestURL: manifestURL)
    }

    public func loadVariants() throws -> [AppVariant] {
        try repository.loadVariants()
    }

    public func loadContent(appSlug: String) throws -> AppContent {
        try repository.loadContent(appSlug: appSlug)
    }
}

public extension AppContent {
    func searchDiagrams(_ query: String) -> [Diagram] {
        diagrams.filter { $0.matches(query) }
    }
}
