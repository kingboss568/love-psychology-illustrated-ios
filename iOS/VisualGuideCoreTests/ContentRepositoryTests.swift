import XCTest
@testable import VisualGuideCore

final class ContentRepositoryTests: XCTestCase {
    private var repository: FileContentRepository!

    override func setUp() {
        super.setUp()
        let file = URL(fileURLWithPath: #filePath)
        let root = file
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        repository = FileContentRepository(appsDirectory: root.appendingPathComponent("data/apps"))
    }

    func testEveryAppDecodesWithExpectedCounts() throws {
        let variants = try repository.loadVariants()
        XCTAssertEqual(variants.count, 8)

        for variant in variants {
            let content = try repository.loadContent(appSlug: variant.slug)
            XCTAssertEqual(content.diagrams.count, 200, variant.slug)
            XCTAssertEqual(content.videos.count, 20, variant.slug)
            XCTAssertEqual(Set(content.diagrams.map(\.id)).count, 200, variant.slug)
            XCTAssertEqual(content.categories.count, 8, variant.slug)
        }
    }

    func testLovePsychologySearchFindsFreeQuestion() throws {
        let content = try repository.loadContent(appSlug: "love-psychology")
        let results = content.searchDiagrams("已讀不回")
        XCTAssertTrue(results.contains { $0.id == "love-psychology-d001" })
        XCTAssertTrue(results.first?.isFree == true)
    }
}
