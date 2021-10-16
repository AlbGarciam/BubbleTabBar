import UIKit

protocol BubbleTabBarViewDelegate: AnyObject {
    func tabBarView(_ tabBar: BubbleTabBarView, didSwitchTo position: Int)
    func didRepeatTap(_ tabBar: BubbleTabBarView)
    func didExpand()
    func didCollapse()
}

final class BubbleTabBarView: UIView {
    private lazy var mainStackView = UIStackView(arrangedSubviews: [tabsStackView])
    private lazy var tabsStackView = UIStackView()
    private let cardView = UIView()
    weak var delegate: BubbleTabBarViewDelegate?
    var font: UIFont = .systemFont(ofSize: 8, weight: .semibold) {
        didSet {
            tabsStackView.subviews
                .compactMap { $0 as? BubbleTabBarItemView }
                .forEach { $0.setTitleFont(font) }
        }
    }

    var selectedContentColor: UIColor = .white {
        didSet {
            tabsStackView.subviews
                .compactMap { $0 as? BubbleTabBarItemView }
                .forEach { $0.selectedContentColor = selectedContentColor }
        }
    }
    var unselectedContentColor: UIColor = .black {
        didSet {
            tabsStackView.subviews
                .compactMap { $0 as? BubbleTabBarItemView }
                .forEach { $0.unselectedContentColor = unselectedContentColor }
        }
    }
    var selectedBackgroundColor: UIColor = .black {
        didSet {
            tabsStackView.subviews
                .compactMap { $0 as? BubbleTabBarItemView }
                .forEach { $0.selectedBackgroundColor = selectedBackgroundColor }
        }
    }

    override var backgroundColor: UIColor? {
        get { cardView.backgroundColor }
        set { cardView.backgroundColor = newValue }
    }

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    func setItems(_ items: [BubbleTabBarItem]) {
        tabsStackView.subviews.forEach { $0.removeFromSuperview() }
        items
            .map {
                let item = BubbleTabBarItem(expandedIcon: $0.expandedIcon,
                                            collapsedIcon: $0.collapsedIcon,
                                            title: $0.title)
                let view = BubbleTabBarItemView(item: item) { [weak self] item in
                    self?.didTap(on: item)
                }
                view.setTitleFont(self.font)
                view.collapse()
                view.selectedContentColor = selectedContentColor
                view.unselectedContentColor = unselectedContentColor
                view.selectedBackgroundColor = selectedBackgroundColor
                return view
            }
            .forEach { self.tabsStackView.addArrangedSubview($0) }
        if let firstTab = tabsStackView.subviews.first as? BubbleTabBarItemView {
            firstTab.expand()
            tabsStackView.layoutIfNeeded()
        }
    }

    func addTopView(view: UIView) {
        removeTopView { [weak self] in
            view.isHidden = true
            view.alpha = 0
            self?.mainStackView.insertArrangedSubview(view, at: 0)
            self?.mainStackView.layoutIfNeeded()
            UIView.animate(withDuration: 0.25, animations: {
                view.alpha = 1
                view.isHidden = false
                self?.mainStackView.layoutIfNeeded()
            }) { _ in
                self?.delegate?.didExpand()
            }
        }
    }

    func removeTopView(completion: (() -> Void)? = nil) {
        guard mainStackView.arrangedSubviews.count > 1,
            let subview = mainStackView.arrangedSubviews.first else {
                completion?()
                return
        }
        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            subview.alpha = 0
            subview.isHidden = true
            self?.mainStackView.layoutIfNeeded()
        }) { [weak self] _ in
            subview.removeFromSuperview()
            self?.delegate?.didCollapse()
            completion?()
        }
    }

    func selectItem(at position: Int) {
        guard position >= 0 && position < tabsStackView.subviews.count else { return }
        didTap(on: tabsStackView.subviews[position] as! BubbleTabBarItemView)
    }
}

private extension BubbleTabBarView {
    func configure() {
        configureMainStackView()
        configureTabsStackView()
        configureBackground()
        layoutIfNeeded()
    }

    func configureTabsStackView() {
        tabsStackView.translatesAutoresizingMaskIntoConstraints = false
        tabsStackView.axis = .horizontal
        tabsStackView.distribution = .fillEqually
        tabsStackView.spacing = 10
    }

    func configureMainStackView() {
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.axis = .vertical
        mainStackView.spacing = 10
        addSubview(mainStackView)
        mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3).isActive = true
        mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3).isActive = true
        mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: 3).isActive = true
        mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3).isActive = true
    }

    func configureBackground() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.layer.cornerRadius = Constants.backgroundCornerRadius
        cardView.layer.masksToBounds = true
        insertSubview(cardView, at: 0)
        cardView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        cardView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        cardView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        cardView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    func switchTab(to newTab: BubbleTabBarItemView, from oldTab: BubbleTabBarItemView?) {
        let options: UIView.AnimationOptions = [.curveEaseInOut, .layoutSubviews]
        UIView.animate(withDuration: 0.2, delay: 0, options: options, animations: {
            newTab.expand()
            oldTab?.collapse()
        }, completion: { _ in
            self.layoutIfNeeded()
        })
    }

    func didTap(on itemView: BubbleTabBarItemView) {
        if itemView.isCollapsed {
            let tabs = tabsStackView.subviews.compactMap { $0 as? BubbleTabBarItemView }
            let currentTab = tabs.first { !$0.isCollapsed }
            switchTab(to: itemView, from: currentTab)
            if let index = tabsStackView.subviews.firstIndex(of: itemView) {
                delegate?.tabBarView(self, didSwitchTo: index)
            }
        } else {
            delegate?.didRepeatTap(self)
        }
    }
}

private extension BubbleTabBarView {
    struct Constants {
        static let spacing: CGFloat = 10
        static let backgroundCornerRadius: CGFloat = 15
        static let backgroundViewCornerRadius: CGFloat = 14
    }
}
