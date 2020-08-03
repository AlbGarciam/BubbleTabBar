import UIKit

protocol BubbleTabBarViewDelegate: AnyObject {
    func tabBarView(_ tabBar: BubbleTabBarView, didSwitchTo position: Int)
    func didRepeatTap(_ tabBar: BubbleTabBarView)
}

final class BubbleTabBarView: UIView {
    private lazy var mainStackView = UIStackView(arrangedSubviews: [tabsStackView])
    private lazy var tabsStackView = UIStackView()
    private let cardView = UIView()
    private let backgroundView = UIView()
    weak var delegate: BubbleTabBarViewDelegate?
    var font: UIFont = .systemFont(ofSize: 8, weight: .semibold) {
        didSet {
            tabsStackView.subviews
                .compactMap { $0 as? BubbleTabBarItemView }
                .forEach { $0.setTitleFont(font) }
        }
    }

    var backgroundViewColor: UIColor = .clear {
        didSet {
            backgroundView.backgroundColor = backgroundViewColor
        }
    }

    override var backgroundColor: UIColor? {
        get { cardView.backgroundColor }
        set { cardView.backgroundColor = newValue }
    }

    override var tintColor: UIColor! {
        didSet {
            tabsStackView.subviews
                .compactMap { $0 as? BubbleTabBarItemView }
                .forEach { $0.tintColor = tintColor }
        }
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
                let view = BubbleTabBarItemView()
                view.setTitle($0.title)
                view.setCollapsedIcon($0.collapsedIcon)
                view.setExpandedIcon($0.expandedIcon)
                view.tintColor = self.tintColor
                view.setTitleFont(self.font)
                view.collapse()
                view.delegate = self
                return view
            }
            .forEach { self.tabsStackView.addArrangedSubview($0) }
        if let firstTab = tabsStackView.subviews.first as? BubbleTabBarItemView {
            firstTab.expand()
            tabsStackView.layoutIfNeeded()
            moveBackground(to: firstTab)
        }
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        let tabs = tabsStackView.subviews
        if let selected = tabs.compactMap({ $0 as? BubbleTabBarItemView }).first(where: { !$0.isCollapsed }) {
            moveBackground(to: selected)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let tabs = tabsStackView.subviews
        if let selected = tabs.compactMap({ $0 as? BubbleTabBarItemView }).first(where: { !$0.isCollapsed }) {
            moveBackground(to: selected)
        }
    }

    func addTopView(view: UIView) {
        removeTopView { [weak self] in
            view.isHidden = true
            view.alpha = 0
            self?.mainStackView.insertArrangedSubview(view, at: 0)
            self?.mainStackView.layoutIfNeeded()
            UIView.animate(withDuration: 0.2) {
                view.alpha = 1
                view.isHidden = false
                self?.mainStackView.layoutIfNeeded()
            }
        }
        mainStackView.insertArrangedSubview(view, at: 0)
    }

    func removeTopView(completion: (() -> Void)? = nil) {
        guard mainStackView.arrangedSubviews.count > 1,
            let subview = mainStackView.arrangedSubviews.first else {
                completion?()
                return
        }
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            subview.alpha = 0
            subview.isHidden = true
            self?.mainStackView.layoutIfNeeded()
        }) { _ in
            subview.removeFromSuperview()
            completion?()
        }
    }
}

private extension BubbleTabBarView {
    func configure() {
        configureMainStackView()
        configureTabsStackView()
        configureBackground()
        configureBackgroundView()
        layoutIfNeeded()
    }

    func configureTabsStackView() {
        tabsStackView.translatesAutoresizingMaskIntoConstraints = false
        tabsStackView.axis = .horizontal
        tabsStackView.distribution = .equalSpacing
        tabsStackView.spacing = 10
    }

    func configureMainStackView() {
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.axis = .vertical
        mainStackView.spacing = 10
        addSubview(mainStackView)
        mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.horizontalPadding).isActive = true
        mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.verticalPadding).isActive = true
        let centerX = mainStackView.centerXAnchor.constraint(equalTo: centerXAnchor)
        centerX.priority = .defaultHigh
        centerX.isActive = true
        let centerY = mainStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        centerY.priority = .defaultHigh
        centerY.isActive = true
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

    func configureBackgroundView() {
        backgroundView.backgroundColor = backgroundViewColor
        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = Constants.backgroundViewCornerRadius
        insertSubview(backgroundView, belowSubview: tabsStackView)
    }

    func moveBackground(to subview: UIView) {
        subview.layoutIfNeeded()
        var destinationFrame = subview.convert(subview.bounds, to: self)
        let maxXPosition = max(Constants.horizontalPadding, destinationFrame.minX)
        let minYPosition = min(Constants.verticalPadding, destinationFrame.minY)
        destinationFrame.origin = CGPoint(x: maxXPosition, y: minYPosition)
        let options: UIView.AnimationOptions = [.curveEaseInOut, .layoutSubviews]
        UIView.animate(withDuration: 0.2, delay: 0, options: options, animations: {
            self.backgroundView.frame = destinationFrame
        }, completion: nil)
    }

    func switchTab(to newTab: BubbleTabBarItemView, from oldTab: BubbleTabBarItemView?) {
        let options: UIView.AnimationOptions = [.curveEaseInOut, .layoutSubviews]
        UIView.animate(withDuration: 0.2, delay: 0, options: options, animations: {
            newTab.expand()
            oldTab?.collapse()
        }, completion: { _ in
            self.moveBackground(to: newTab)
            self.layoutIfNeeded()
        })
    }
}

extension BubbleTabBarView: BubbleTabBarItemViewDelegate {
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
        static let horizontalPadding: CGFloat = 3
        static let verticalPadding: CGFloat = 3
        static let spacing: CGFloat = 10
        static let backgroundCornerRadius: CGFloat = 15
        static let backgroundViewCornerRadius: CGFloat = 14
    }
}
