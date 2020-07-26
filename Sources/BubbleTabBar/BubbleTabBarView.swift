import UIKit

protocol BubbleTabBarViewDelegate: AnyObject {
    func tabBarView(_ tabBar: BubbleTabBarView, didSwitchTo position: Int)
    func didRepeatTap(_ tabBar: BubbleTabBarView)
}

final class BubbleTabBarView: UIView {
    private let tabsStackView = UIStackView()
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
            moveBackground(to: firstTab)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let tabs = tabsStackView.subviews
        if let selected = tabs.compactMap { $0 as? BubbleTabBarItemView }.first(where: { !$0.isCollapsed }) {
            moveBackground(to: selected)
        }
    }
}

private extension BubbleTabBarView {
    func configure() {
        configureTabsStackView()
        configureBackground()
        configureBackgroundView()
    }

    func configureTabsStackView() {
        tabsStackView.translatesAutoresizingMaskIntoConstraints = false
        tabsStackView.axis = .horizontal
        tabsStackView.distribution = .equalSpacing
        tabsStackView.spacing = 10
        addSubview(tabsStackView)
        tabsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.horizontalPadding).isActive = true
        tabsStackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.verticalPadding).isActive = true
        let centerX = tabsStackView.centerXAnchor.constraint(equalTo: centerXAnchor)
        centerX.priority = .defaultHigh
        centerX.isActive = true
        let centerY = tabsStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
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
        let destinationFrame = subview.convert(subview.frame, to: self)
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
            self.moveBackground(to: newTab)
        }, completion: { _ in
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
