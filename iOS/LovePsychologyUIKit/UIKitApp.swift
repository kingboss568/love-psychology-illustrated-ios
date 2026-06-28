import StoreKit
import UIKit
import VisualGuideCore

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.tintColor = AppStyle.wine
        window.rootViewController = RootTabController()
        window.makeKeyAndVisible()
        self.window = window
    }
}

enum AppStyle {
    static let paper = UIColor(red: 1.0, green: 0.975, blue: 0.94, alpha: 1)
    static let card = UIColor.white
    static let coral = UIColor(red: 0.98, green: 0.35, blue: 0.38, alpha: 1)
    static let apricot = UIColor(red: 1.0, green: 0.73, blue: 0.45, alpha: 1)
    static let wine = UIColor(red: 0.50, green: 0.05, blue: 0.16, alpha: 1)
    static let teal = UIColor(red: 0.08, green: 0.43, blue: 0.42, alpha: 1)
    static let ink = UIColor(red: 0.15, green: 0.10, blue: 0.12, alpha: 1)
    static let mute = UIColor(red: 0.48, green: 0.40, blue: 0.42, alpha: 1)
    static let line = UIColor(red: 0.91, green: 0.84, blue: 0.80, alpha: 1)

    static func font(_ size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        UIFontMetrics.default.scaledFont(for: .systemFont(ofSize: size, weight: weight))
    }

    static func pill(_ color: UIColor) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
}

struct ToolItem {
    let title: String
    let group: String
    let summary: String
}

@MainActor
final class AppModel {
    static let shared = AppModel()

    let content: AppContent
    let tools: [ToolItem]
    let links: [(title: String, url: URL)]
    let purchase = PurchaseStore(productID: "com.jiang.visualguide.lovepsychology.pro.lifetime")

    private init() {
        do {
            content = try BundleContentRepository().loadContent(appSlug: "love-psychology")
        } catch {
            fatalError("Missing bundled love-psychology content: \(error)")
        }
        tools = Self.makeTools()
        links = [
            ("The Gottman Institute", URL(string: "https://www.gottman.com/blog/")!),
            ("Psychology Today Relationships", URL(string: "https://www.psychologytoday.com/us/basics/relationships")!),
            ("Verywell Mind Relationships", URL(string: "https://www.verywellmind.com/relationships-4157190")!),
            ("NVC 說明資源", URL(string: "https://www.cnvc.org/")!)
        ]
    }

    func canOpen(_ diagram: Diagram) -> Bool {
        purchase.isUnlocked || diagram.order <= 20
    }

    private static func makeTools() -> [ToolItem] {
        let groups = [
            "訊息節奏", "約會復盤", "界線確認", "情緒整理", "依附觀察",
            "冷淡判讀", "衝突修復", "承諾檢查", "Red Flag", "自我照顧"
        ]
        let actions = [
            "三次互動紀錄", "低壓詢問句", "投入比例盤點", "等待時間設定", "需求翻譯",
            "界線句練習", "關係溫度計", "修復對話稿", "風險提醒卡", "下一步選擇器"
        ]
        return groups.flatMap { group in
            actions.enumerated().map { index, action in
                ToolItem(
                    title: "\(group) \(action)",
                    group: group,
                    summary: "用 2 分鐘把事件、感受、可觀察行為與下一步分開，避免只靠猜。步驟 \(index + 1) 適合保存到收藏後反覆使用。"
                )
            }
        }
    }
}

final class RootTabController: UITabBarController {
    private let model = AppModel.shared
    private var didApplyScreenshotArguments = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppStyle.paper
        tabBar.backgroundColor = .white
        tabBar.tintColor = AppStyle.wine
        tabBar.unselectedItemTintColor = AppStyle.mute

        viewControllers = [
            nav(HomeViewController(model: model), "首頁", "house.fill"),
            nav(BoardViewController(model: model), "圖卡", "square.grid.2x2.fill"),
            nav(CategoriesViewController(model: model), "主題", "heart.text.square.fill"),
            nav(ToolsViewController(model: model), "工具", "checklist.checked"),
            nav(PaywallViewController(model: model), "Pro", "sparkles")
        ]

        Task {
            await model.purchase.load()
            await model.purchase.refreshEntitlements()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didApplyScreenshotArguments else { return }
        didApplyScreenshotArguments = true
        applyScreenshotArguments()
    }

    private func nav(_ root: UIViewController, _ title: String, _ symbol: String) -> UIViewController {
        root.title = title
        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.prefersLargeTitles = false
        nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: symbol), selectedImage: UIImage(systemName: symbol))
        return nav
    }

    private func applyScreenshotArguments() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--screenshot-paywall") {
            selectedIndex = 4
            return
        }
        if let tabValue = argumentValue(named: "--screenshot-tab", in: args),
           let tab = Int(tabValue),
           tab >= 0,
           tab < (viewControllers?.count ?? 0) {
            selectedIndex = tab
        }
        if let diagramValue = argumentValue(named: "--screenshot-diagram", in: args),
           let order = Int(diagramValue) {
            let index = min(max(order - 1, 0), model.content.diagrams.count - 1)
            let diagram = model.content.diagrams[index]
            let navigation = selectedViewController as? UINavigationController
            DispatchQueue.main.async {
                navigation?.pushViewController(DiagramDetailViewController(model: self.model, diagram: diagram), animated: false)
            }
        }
    }

    private func argumentValue(named name: String, in args: [String]) -> String? {
        if let inline = args.first(where: { $0.hasPrefix(name + "=") }) {
            return String(inline.dropFirst(name.count + 1))
        }
        guard let index = args.firstIndex(of: name), args.indices.contains(index + 1) else { return nil }
        return args[index + 1]
    }
}

class BaseViewController: UIViewController {
    let model: AppModel

    init(model: AppModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppStyle.paper
    }

    func proStrip(text: String = "Pro / 解鎖完整圖解：一次開啟 200 張圖解、100 種工具與完整主題索引") -> UIView {
        let button = UIButton(type: .system)
        button.setTitle(text, for: .normal)
        button.titleLabel?.font = AppStyle.font(13, weight: .semibold)
        button.titleLabel?.numberOfLines = 2
        button.contentHorizontalAlignment = .left
        button.tintColor = .white
        button.backgroundColor = AppStyle.wine
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        button.addTarget(self, action: #selector(openPaywall), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    @objc func openPaywall() {
        tabBarController?.selectedIndex = 4
    }

    func openDiagram(_ diagram: Diagram) {
        if model.canOpen(diagram) {
            navigationController?.pushViewController(DiagramDetailViewController(model: model, diagram: diagram), animated: true)
        } else {
            navigationController?.pushViewController(PaywallViewController(model: model, lockedDiagram: diagram), animated: true)
        }
    }
}

final class HomeViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    private lazy var scroll = UIScrollView()
    private lazy var stack = UIStackView()
    private lazy var carousel = UICollectionView(frame: .zero, collectionViewLayout: carouselLayout())
    private let featured = Array(AppModel.shared.content.diagrams.prefix(12))

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "戀愛心理全圖解"
        configureScroll()
        build()
    }

    private func configureScroll() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    private func build() {
        stack.addArrangedSubview(hero())
        stack.addArrangedSubview(searchBar())
        stack.addArrangedSubview(stats())
        stack.addArrangedSubview(categoryGrid())
        stack.addArrangedSubview(proStrip())
        stack.addArrangedSubview(sectionTitle("精選圖解", trailing: "左右滑動"))
        carousel.backgroundColor = .clear
        carousel.showsHorizontalScrollIndicator = false
        carousel.dataSource = self
        carousel.delegate = self
        carousel.register(DiagramCell.self, forCellWithReuseIdentifier: DiagramCell.reuseID)
        carousel.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(carousel)
        carousel.heightAnchor.constraint(equalToConstant: 276).isActive = true
        carousel.reloadData()
        DispatchQueue.main.async { self.carousel.scrollToItem(at: IndexPath(item: 5_000, section: 0), at: .centeredHorizontally, animated: false) }
        stack.addArrangedSubview(sectionTitle("加值服務", trailing: "100 種工具"))
        stack.addArrangedSubview(toolPreview())
        stack.addArrangedSubview(linkPreview())
    }

    private func hero() -> UIView {
        let card = UIView.card()
        let image = UIImageView(image: UIImage(named: "love_banner"))
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.cornerRadius = 8
        image.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(image)

        let title = UILabel()
        title.text = "他不是難懂，你只是還沒看懂這段關係"
        title.font = AppStyle.font(24, weight: .bold)
        title.textColor = AppStyle.ink
        title.numberOfLines = 2

        let body = UILabel()
        body.text = "200 張圖解把曖昧、冷淡、推拉與界線拆成可觀察線索。"
        body.font = AppStyle.font(14)
        body.textColor = AppStyle.mute
        body.numberOfLines = 2

        let text = UIStackView(arrangedSubviews: [title, body])
        text.axis = .vertical
        text.spacing = 6
        text.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(text)

        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: card.topAnchor),
            image.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            image.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            image.heightAnchor.constraint(equalToConstant: 168),
            text.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            text.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            text.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            text.topAnchor.constraint(greaterThanOrEqualTo: image.topAnchor, constant: 20),
            card.heightAnchor.constraint(equalToConstant: 230)
        ])
        return card
    }

    private func searchBar() -> UISearchBar {
        let bar = UISearchBar()
        bar.searchBarStyle = .minimal
        bar.placeholder = "搜尋：已讀不回、忽冷忽熱、界線"
        bar.delegate = self
        return bar
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let controller = BoardViewController(model: model, initialQuery: searchBar.text ?? "")
        navigationController?.pushViewController(controller, animated: true)
    }

    private func stats() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 8
        [
            ("200", "圖解"),
            ("20", "免費預覽"),
            ("100", "工具"),
            ("8", "主題")
        ].forEach { row.addArrangedSubview(StatView(value: $0.0, label: $0.1)) }
        return row
    }

    private func categoryGrid() -> UIView {
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 8
        for pair in stride(from: 0, to: min(6, model.content.categories.count), by: 2) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            row.distribution = .fillEqually
            model.content.categories[pair..<min(pair + 2, model.content.categories.count)].forEach { category in
                let button = CategoryButton(category: category)
                button.addAction(UIAction { [weak self] _ in
                    guard let self else { return }
                    self.navigationController?.pushViewController(CategoryDetailViewController(model: self.model, category: category), animated: true)
                }, for: .touchUpInside)
                row.addArrangedSubview(button)
            }
            grid.addArrangedSubview(row)
        }
        return grid
    }

    private func toolPreview() -> UIView {
        let card = UIView.card()
        let label = UILabel()
        label.text = "訊息節奏、界線句、約會復盤、冷淡判讀、衝突修復等 100 種微工具。"
        label.font = AppStyle.font(15, weight: .semibold)
        label.numberOfLines = 0
        label.textColor = AppStyle.ink
        let button = UIButton.primary("打開工具箱")
        button.addTarget(self, action: #selector(openTools), for: .touchUpInside)
        UIStackView.pack([label, button], in: card, spacing: 12)
        return card
    }

    private func linkPreview() -> UIView {
        let card = UIView.card()
        let label = UILabel()
        label.text = "實用連結：關係研究、溝通練習與非暴力溝通資源。"
        label.font = AppStyle.font(14)
        label.textColor = AppStyle.mute
        label.numberOfLines = 0
        UIStackView.pack([label], in: card, spacing: 8)
        return card
    }

    @objc private func openTools() {
        tabBarController?.selectedIndex = 3
    }

    private func sectionTitle(_ title: String, trailing: String) -> UIView {
        let left = UILabel()
        left.text = title
        left.font = AppStyle.font(19, weight: .bold)
        left.textColor = AppStyle.ink
        let right = UILabel()
        right.text = trailing
        right.font = AppStyle.font(12, weight: .semibold)
        right.textColor = AppStyle.teal
        let row = UIStackView(arrangedSubviews: [left, UIView(), right])
        row.axis = .horizontal
        row.alignment = .lastBaseline
        return row
    }

    private func carouselLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        return layout
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 10_000 }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiagramCell.reuseID, for: indexPath) as! DiagramCell
        let diagram = featured[indexPath.item % featured.count]
        cell.configure(diagram: diagram, locked: !model.canOpen(diagram))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        openDiagram(featured[indexPath.item % featured.count])
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 190, height: 268)
    }
}

class BoardViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    private lazy var collection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let source: ([Diagram]) -> [Diagram]
    private var query: String
    private var diagrams: [Diagram] {
        let scoped = source(model.content.diagrams)
        guard !query.isEmpty else { return scoped }
        return scoped.filter { $0.matches(query) }
    }

    init(model: AppModel, initialQuery: String = "", source: @escaping ([Diagram]) -> [Diagram] = { $0 }) {
        query = initialQuery
        self.source = source
        super.init(model: model)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if title == nil {
            title = "圖卡快覽"
        }
        let search = UISearchBar()
        search.placeholder = "搜尋你的問題"
        search.text = query
        search.delegate = self
        search.searchBarStyle = .minimal

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 12
        collection.setCollectionViewLayout(layout, animated: false)
        collection.backgroundColor = .clear
        collection.dataSource = self
        collection.delegate = self
        collection.register(DiagramCell.self, forCellWithReuseIdentifier: DiagramCell.reuseID)
        collection.translatesAutoresizingMaskIntoConstraints = false

        let strip = proStrip(text: "Pro / 解鎖完整圖解：圖卡牆 20 張免費，其餘 180 張解鎖後可看")
        let stack = UIStackView(arrangedSubviews: [search, strip, collection])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        query = searchText
        collection.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { diagrams.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiagramCell.reuseID, for: indexPath) as! DiagramCell
        let diagram = diagrams[indexPath.item]
        cell.configure(diagram: diagram, locked: !model.canOpen(diagram))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        openDiagram(diagrams[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 12) / 2
        let height: CGFloat = indexPath.item % 3 == 0 ? 292 : 252
        return CGSize(width: floor(width), height: height)
    }
}

final class CategoriesViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    private let table = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "八大主題"
        table.backgroundColor = AppStyle.paper
        table.dataSource = self
        table.delegate = self
        table.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(table)
        table.tableHeaderView = HeaderView(frame: CGRect(x: 0, y: 0, width: 1, height: 86), text: "每個分頁都能直接解鎖 Pro；先看 20 張免費預覽，再決定是否開完整圖解。")
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { model.content.categories.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let category = model.content.categories[indexPath.row]
        cell.textLabel?.text = category.title
        cell.detailTextLabel?.text = "\(category.topicCount) 張圖解 · 免費 \(category.freeCount) · Pro \(category.proCount)"
        cell.imageView?.image = UIImage(systemName: category.iconSystemName)
        cell.imageView?.tintColor = AppStyle.wine
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(CategoryDetailViewController(model: model, category: model.content.categories[indexPath.row]), animated: true)
    }
}

final class CategoryDetailViewController: BoardViewController {
    init(model: AppModel, category: GuideCategory) {
        super.init(model: model, source: { diagrams in
            diagrams.filter { $0.moduleId == category.id }
        })
        title = category.title
    }
}

final class ToolsViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    private let table = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "工具箱 100"
        table.backgroundColor = AppStyle.paper
        table.dataSource = self
        table.delegate = self
        table.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(table)
        table.tableHeaderView = HeaderView(frame: CGRect(x: 0, y: 0, width: 1, height: 96), text: "100 種小工具：不是診斷，不替你做決定；幫你把情境、感受、界線與下一步分開。Pro 可搭配完整 200 張圖解使用。")
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func numberOfSections(in tableView: UITableView) -> Int { 10 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 10 }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { model.tools[section * 10].group }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = model.tools[indexPath.section * 10 + indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.summary
        cell.detailTextLabel?.numberOfLines = 2
        cell.imageView?.image = UIImage(systemName: indexPath.row < 2 ? "checkmark.circle.fill" : "lock.circle")
        cell.imageView?.tintColor = indexPath.row < 2 ? AppStyle.teal : AppStyle.wine
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = model.tools[indexPath.section * 10 + indexPath.row]
        if indexPath.section * 10 + indexPath.row >= 20 && !model.purchase.isUnlocked {
            openPaywall()
            return
        }
        let alert = UIAlertController(title: item.title, message: item.summary + "\n\n1. 寫下事實，不寫猜測。\n2. 標出自己的界線。\n3. 選一個低壓下一步。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "完成", style: .default))
        present(alert, animated: true)
    }
}

final class PaywallViewController: BaseViewController {
    private let lockedDiagram: Diagram?
    private let stack = UIStackView()
    private let priceButton = UIButton.primary("載入價格中")
    private let status = UILabel()

    init(model: AppModel, lockedDiagram: Diagram? = nil) {
        self.lockedDiagram = lockedDiagram
        super.init(model: model)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Pro / 解鎖完整圖解"
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        let headline = UILabel()
        headline.text = lockedDiagram.map { "解鎖「\($0.title)」與完整圖解" } ?? "一次解鎖戀愛心理完整圖解"
        headline.font = AppStyle.font(25, weight: .bold)
        headline.numberOfLines = 0
        headline.textColor = AppStyle.ink

        let body = UILabel()
        body.text = "免費下載，先看 20 張預覽。付費 NT$199 後解鎖 200 張圖解、100 種工具、完整分類與收藏流程。"
        body.font = AppStyle.font(15)
        body.numberOfLines = 0
        body.textColor = AppStyle.mute

        stack.addArrangedSubview(headline)
        stack.addArrangedSubview(body)
        stack.addArrangedSubview(benefits())
        priceButton.addTarget(self, action: #selector(buy), for: .touchUpInside)
        stack.addArrangedSubview(priceButton)

        let restore = UIButton(type: .system)
        restore.setTitle("恢復購買", for: .normal)
        restore.titleLabel?.font = AppStyle.font(15, weight: .semibold)
        restore.addTarget(self, action: #selector(restorePurchase), for: .touchUpInside)
        stack.addArrangedSubview(restore)

        status.textColor = AppStyle.mute
        status.font = AppStyle.font(13)
        status.numberOfLines = 0
        status.text = "教育與自我反思用途，不保證讀心、不作心理診斷。"
        stack.addArrangedSubview(status)

        Task { await refresh() }
    }

    private func benefits() -> UIView {
        let card = UIView.card()
        let items = ["200 張完整圖解", "100 種關係微工具", "8 大主題完整索引", "StoreKit 恢復購買"]
        let labels = items.map { item -> UILabel in
            let label = UILabel()
            label.text = "✓ \(item)"
            label.font = AppStyle.font(15, weight: .semibold)
            label.textColor = AppStyle.ink
            return label
        }
        UIStackView.pack(labels, in: card, spacing: 9)
        return card
    }

    private func refresh() async {
        await model.purchase.load()
        await model.purchase.refreshEntitlements()
        priceButton.setTitle("Pro / 解鎖完整圖解 \(model.purchase.displayPrice ?? "NT$199")", for: .normal)
        if model.purchase.isUnlocked {
            status.text = "Pro 已解鎖。"
            priceButton.isEnabled = false
        }
    }

    @objc private func buy() {
        Task {
            await model.purchase.purchase()
            await refresh()
            status.text = model.purchase.statusText
        }
    }

    @objc private func restorePurchase() {
        Task {
            await model.purchase.restore()
            await refresh()
            status.text = model.purchase.statusText
        }
    }
}

final class DiagramDetailViewController: BaseViewController {
    private let diagram: Diagram

    init(model: AppModel, diagram: Diagram) {
        self.diagram = diagram
        super.init(model: model)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = diagram.title
        let scroll = UIScrollView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24)
        ])

        let image = UIImageView(image: DiagramImageLoader.image(named: diagram.diagram.assetName))
        image.contentMode = .scaleAspectFit
        image.backgroundColor = .white
        image.layer.cornerRadius = 8
        image.clipsToBounds = true
        image.isAccessibilityElement = true
        image.accessibilityLabel = diagram.diagram.altText
        stack.addArrangedSubview(image)
        image.heightAnchor.constraint(equalTo: image.widthAnchor, multiplier: 1.45).isActive = true

        stack.addArrangedSubview(textCard(title: diagram.userQuestion, body: diagram.answerSummary))
        stack.addArrangedSubview(listCard(title: "三個觀察點", items: diagram.keyPoints))
        stack.addArrangedSubview(listCard(title: "下一步", items: diagram.actionSteps))
        stack.addArrangedSubview(textCard(title: "常見誤判", body: diagram.commonMisconception))
        stack.addArrangedSubview(proStrip())
    }

    private func textCard(title: String, body: String) -> UIView {
        let card = UIView.card()
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = AppStyle.font(18, weight: .bold)
        titleLabel.numberOfLines = 0
        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = AppStyle.font(15)
        bodyLabel.textColor = AppStyle.mute
        bodyLabel.numberOfLines = 0
        UIStackView.pack([titleLabel, bodyLabel], in: card, spacing: 8)
        return card
    }

    private func listCard(title: String, items: [String]) -> UIView {
        let labels = [title].map { text -> UILabel in
            let label = UILabel()
            label.text = text
            label.font = AppStyle.font(17, weight: .bold)
            return label
        } + items.enumerated().map { index, item -> UILabel in
            let label = UILabel()
            label.text = "\(index + 1). \(item)"
            label.font = AppStyle.font(15)
            label.numberOfLines = 0
            label.textColor = AppStyle.ink
            return label
        }
        let card = UIView.card()
        UIStackView.pack(labels, in: card, spacing: 8)
        return card
    }
}

final class DiagramCell: UICollectionViewCell {
    static let reuseID = "DiagramCell"
    private let image = UIImageView()
    private let title = UILabel()
    private let badge = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        contentView.layer.borderColor = AppStyle.line.cgColor
        contentView.layer.borderWidth = 1

        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        title.font = AppStyle.font(14, weight: .bold)
        title.textColor = AppStyle.ink
        title.numberOfLines = 2
        badge.font = AppStyle.font(11, weight: .bold)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.layer.cornerRadius = 7
        badge.clipsToBounds = true

        [image, title, badge].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: contentView.topAnchor),
            image.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            image.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            image.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.70),
            badge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            badge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            badge.widthAnchor.constraint(equalToConstant: 48),
            badge.heightAnchor.constraint(equalToConstant: 22),
            title.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 8),
            title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(diagram: Diagram, locked: Bool) {
        image.image = DiagramImageLoader.image(named: diagram.diagram.assetName)
        image.accessibilityLabel = diagram.diagram.altText
        title.text = diagram.title
        badge.text = locked ? "Pro" : "免費"
        badge.backgroundColor = locked ? AppStyle.wine : AppStyle.teal
    }
}

final class StatView: UIView {
    init(value: String, label: String) {
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 8
        layer.borderColor = AppStyle.line.cgColor
        layer.borderWidth = 1
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = AppStyle.font(20, weight: .bold)
        valueLabel.textColor = AppStyle.wine
        valueLabel.textAlignment = .center
        let labelView = UILabel()
        labelView.text = label
        labelView.font = AppStyle.font(12, weight: .semibold)
        labelView.textColor = AppStyle.mute
        labelView.textAlignment = .center
        UIStackView.pack([valueLabel, labelView], in: self, spacing: 2, insets: UIEdgeInsets(top: 10, left: 4, bottom: 10, right: 4))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class CategoryButton: UIButton {
    init(category: GuideCategory) {
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 8
        layer.borderColor = AppStyle.line.cgColor
        layer.borderWidth = 1
        contentHorizontalAlignment = .left
        titleLabel?.numberOfLines = 2
        setTitle("  \(category.title)\n  \(category.topicCount) 張 · 免費 \(category.freeCount)", for: .normal)
        setTitleColor(AppStyle.ink, for: .normal)
        titleLabel?.font = AppStyle.font(14, weight: .semibold)
        setImage(UIImage(systemName: category.iconSystemName), for: .normal)
        tintColor = AppStyle.wine
        heightAnchor.constraint(equalToConstant: 72).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class HeaderView: UIView {
    init(frame: CGRect, text: String) {
        super.init(frame: frame)
        let label = UILabel()
        label.text = text
        label.textColor = AppStyle.mute
        label.font = AppStyle.font(14, weight: .semibold)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            label.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

enum DiagramImageLoader {
    static func image(named assetName: String) -> UIImage? {
        if let url = Bundle.main.url(forResource: assetName, withExtension: "heic", subdirectory: "DiagramAssets") {
            return UIImage(contentsOfFile: url.path)
        }
        if let url = Bundle.main.url(forResource: assetName, withExtension: "png", subdirectory: "DiagramAssets") {
            return UIImage(contentsOfFile: url.path)
        }
        return UIImage(systemName: "photo")
    }
}

extension UIView {
    static func card() -> UIView {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.layer.borderColor = AppStyle.line.cgColor
        view.layer.borderWidth = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
}

extension UIStackView {
    static func pack(_ views: [UIView], in container: UIView, spacing: CGFloat, insets: UIEdgeInsets = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)) {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: insets.top),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: insets.left),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -insets.right),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -insets.bottom)
        ])
    }
}

extension UIButton {
    static func primary(_ title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = AppStyle.font(16, weight: .bold)
        button.titleLabel?.numberOfLines = 2
        button.tintColor = .white
        button.backgroundColor = AppStyle.coral
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 13, left: 14, bottom: 13, right: 14)
        return button
    }
}
