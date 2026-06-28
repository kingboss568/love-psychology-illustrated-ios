import Foundation

public struct AppContent: Equatable {
    public let manifest: AppManifest
    public let categories: [GuideCategory]
    public let diagrams: [Diagram]
    public let videos: [VideoLesson]
    public let uiCopy: UICopy

    public var freeDiagrams: [Diagram] { diagrams.filter(\.isFree) }
    public var proDiagrams: [Diagram] { diagrams.filter { !$0.isFree } }
    public var freeVideos: [VideoLesson] { videos.filter(\.isFree) }
}

public struct AppManifest: Equatable, Decodable {
    public let name: String
    public let shortName: String
    public let slug: String
    public let bundleId: String
    public let productId: String
    public let positioning: String
    public let hook: String
    public let safeClaim: String
    public let uniqueFeature: UniqueFeature
    public let categories: [GuideCategory]
    public let monetization: Monetization
}

public struct Monetization: Equatable, Decodable {
    public let download: String
    public let iapType: String
    public let targetPriceTWD: Int
    public let priceSourceOfTruth: String
    public let restorePurchasesRequired: Bool
}

public struct GuideCategory: Identifiable, Hashable, Decodable {
    public let id: String
    public let appSlug: String
    public let title: String
    public let order: Int
    public let topicCount: Int
    public let freeCount: Int
    public let proCount: Int
    public let iconSystemName: String
}

public struct Diagram: Identifiable, Equatable, Decodable {
    public let id: String
    public let appSlug: String
    public let moduleId: String
    public let module: String
    public let order: Int
    public let accessLevel: String
    public let title: String
    public let userQuestion: String
    public let answerSummary: String
    public let keyPoints: [String]
    public let actionSteps: [String]
    public let commonMisconception: String
    public let safetyNote: String
    public let diagram: DiagramAsset
    public let searchTerms: [String]?
    public let tags: [String]?
    public let synonyms: [String]?

    public var isFree: Bool { accessLevel == "free" }

    public func matches(_ query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return true }
        return searchableText.localizedStandardContains(needle)
    }

    private var searchableText: String {
        ([title, userQuestion, answerSummary] + (searchTerms ?? []) + (tags ?? []) + (synonyms ?? []))
            .joined(separator: " ")
            .lowercased()
    }
}

public struct DiagramAsset: Equatable, Decodable {
    public let type: String
    public let concept: String
    public let onImageLabels: [String]
    public let altText: String
    public let assetName: String
    public let thumbnailAssetName: String
}

public struct VideoLesson: Identifiable, Equatable, Decodable {
    public let id: String
    public let appSlug: String
    public let order: Int
    public let accessLevel: String
    public let title: String
    public let durationSeconds: Int
    public let learningObjective: String
    public let openingHook: String
    public let storyboard: [StoryboardScene]

    public var isFree: Bool { accessLevel == "free" }
}

public struct StoryboardScene: Equatable, Decodable {
    public let scene: Int
    public let start: Int
    public let end: Int
    public let purpose: String
    public let visual: String
    public let overlay: String
    public let voiceover: String
    public let subtitle: String
}

public struct UICopy: Equatable, Decodable {
    public let common: CommonCopy
    public let variant: VariantCopy
}

public struct CommonCopy: Equatable, Decodable {
    public let navigation: NavigationCopy
    public let actions: ActionCopy
    public let access: AccessCopy
    public let purchase: PurchaseCopy
    public let search: SearchCopy
    public let library: LibraryCopy
    public let errors: ErrorCopy
}

public struct NavigationCopy: Equatable, Decodable {
    public let home: String
    public let categories: String
    public let search: String
    public let library: String
    public let pro: String
}

public struct ActionCopy: Equatable, Decodable {
    public let open: String
    public let play: String
    public let favorite: String
    public let unfavorite: String
    public let share: String
    public let retry: String
    public let close: String
    public let `continue`: String
    public let back: String
}

public struct AccessCopy: Equatable, Decodable {
    public let freeBadge: String
    public let proBadge: String
    public let lockedTitle: String
    public let lockedBody: String
    public let unlock: String
}

public struct PurchaseCopy: Equatable, Decodable {
    public let title: String
    public let body: String
    public let cta: String
    public let restore: String
    public let restoring: String
    public let success: String
    public let cancelled: String
    public let priceFallback: String
    public let legal: String
}

public struct SearchCopy: Equatable, Decodable {
    public let placeholder: String
    public let recent: String
    public let clear: String
    public let emptyTitle: String
    public let emptyBody: String
}

public struct LibraryCopy: Equatable, Decodable {
    public let favoritesTitle: String
    public let recentTitle: String
    public let emptyFavorites: String
    public let emptyRecent: String
}

public struct ErrorCopy: Equatable, Decodable {
    public let contentLoad: String
    public let productLoad: String
    public let videoLoad: String
}

public struct VariantCopy: Equatable, Decodable {
    public let appName: String
    public let hook: String
    public let homeHeroTitle: String
    public let homeHeroSubtitle: String
    public let popularSection: String
    public let recommendedVideoSection: String
    public let categorySection: String
    public let featureTitle: String
    public let featureBody: String
    public let safetyTitle: String
    public let safetyBody: String
    public let onboarding: [OnboardingPage]
    public let paywall: PaywallCopy
}

public struct OnboardingPage: Equatable, Decodable {
    public let title: String
    public let body: String
    public let cta: String
}

public struct PaywallCopy: Equatable, Decodable {
    public let headline: String
    public let subheadline: String
    public let benefits: [String]
    public let primaryCTA: String
    public let secondaryCTA: String
    public let disclaimer: String
}
