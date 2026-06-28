import Foundation

public struct AppVariant: Identifiable, Hashable, Decodable {
    public let slug: String
    public let name: String
    public let bundleId: String
    public let uniqueFeature: UniqueFeature

    public var id: String { slug }
}

public struct AppsManifest: Decodable {
    public let schemaVersion: String
    public let apps: [AppVariant]
}

public struct UniqueFeature: Hashable, Decodable {
    public let id: String
    public let name: String
    public let description: String
    public let views: [String]
}
