import UIKit

public protocol BubbleViewController {
    var expandedIcon: UIImage { get }
    var collapsedIcon: UIImage { get }
    var tabBarTitle: String { get }
}

open class BubbleTabBarViewController: UIViewController {
    fileprivate typealias Controller = BubbleViewController & UIViewController
    private lazy var tabBarView = BubbleTabBarView()
    private var viewControllers: [Controller] = []
    private weak var currentController: Controller?
    private var bottomConstraint: NSLayoutConstraint?
    public var tabBarFont: UIFont {
        set { tabBarView.font = newValue }
        get { tabBarView.font }
    }

    public var selectedItemColor: UIColor {
        get { tabBarView.backgroundViewColor }
        set { tabBarView.backgroundViewColor = newValue }
    }

    public var tintColor: UIColor {
        get { tabBarView.tintColor }
        set { tabBarView.tintColor = newValue }
    }

    public var tabBarBackgroundColor: UIColor {
        get { tabBarView.backgroundColor ?? .clear }
        set { tabBarView.backgroundColor = newValue }
    }

    public var tabBarShadowColor: CGColor? {
        get { tabBarView.layer.shadowColor }
        set { tabBarView.layer.applyShadow(color: newValue) }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }

    deinit {
        removeControllers()
    }

    public func setViewControllers(_ controllers: [BubbleViewController & UIViewController]) {
        removeControllers()
        viewControllers = controllers
        let tabBarItems = controllers.map {
            BubbleTabBarItem(expandedIcon: $0.expandedIcon, collapsedIcon: $0.collapsedIcon, title: $0.tabBarTitle)
        }
        tabBarView.setItems(tabBarItems)
        controllers.forEach {
            $0.willMove(toParent: self)
            self.addChild($0)
            $0.didMove(toParent: self)
        }
        controllers.compactMap { $0 as? UINavigationController }.forEach { $0.delegate = self }
        if let firstController = viewControllers.first {
            setCurrentController(firstController)
        }
    }
}

//MARK: - Private methods
private extension BubbleTabBarViewController {
    func configure() {
        configureTabBarView()
    }

    func configureTabBarView() {
        tabBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabBarView)
        bottomConstraint = tabBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                              constant: Constants.verticalPadding)
        bottomConstraint?.isActive = true
        tabBarView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tabBarView.widthAnchor.constraint(lessThanOrEqualToConstant: Constants.tabBarMaxWidth).isActive = true
        let leading = tabBarView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                          constant: Constants.horizontalPadding)
        leading.priority = .defaultHigh
        leading.isActive = true
        tabBarView.delegate = self
    }

    func removeControllers() {
        viewControllers.forEach {
            $0.removeFromParent()
            $0.view.removeFromSuperview()
        }
        viewControllers.removeAll()
    }

    func setCurrentController(_ controller: Controller) {
        currentController?.view.removeFromSuperview()
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(controller.view, belowSubview: tabBarView)
        controller.view.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        controller.view.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        controller.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        controller.view.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        currentController = controller
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    func hideTabBar(animated: Bool) {
        tabBarView.layoutIfNeeded()
        let destinationFrame = tabBarView.convert(tabBarView.bounds, to: view)
        bottomConstraint?.constant = view.bounds.height - destinationFrame.minY
        let animations: () -> Void = { [weak self] in
            self?.view.layoutIfNeeded()
        }
        if animated {
            let options: UIView.AnimationOptions = [.curveEaseInOut, .layoutSubviews]
            UIView.animate(withDuration: 0.2, delay: 0, options: options, animations: animations, completion: nil)
        } else {
            animations()
        }
    }

    func showTabBar(animated: Bool) {
        tabBarView.layoutIfNeeded()
        bottomConstraint?.constant = Constants.verticalPadding
        let animations: () -> Void = { [weak self] in
            self?.view.layoutIfNeeded()
        }
        if animated {
            let options: UIView.AnimationOptions = [.curveEaseInOut, .layoutSubviews]
            UIView.animate(withDuration: 0.2, delay: 0, options: options, animations: animations, completion: nil)
        } else {
            animations()
        }
    }
}

extension BubbleTabBarViewController: BubbleTabBarViewDelegate {
    func tabBarView(_ tabBar: BubbleTabBarView, didSwitchTo position: Int) {
        guard position >= 0 && position < viewControllers.count else {
            return
        }
        setCurrentController(viewControllers[position])
    }

    func didRepeatTap(_ tabBar: BubbleTabBarView) {
        (currentController as? UINavigationController)?.popToRootViewController(animated: true)
    }
}

extension BubbleTabBarViewController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController,
                                     willShow viewController: UIViewController,
                                     animated: Bool) {
        let shouldDisplayTabBar = viewController.hidesBottomBarWhenPushed
        !shouldDisplayTabBar ? showTabBar(animated: animated) : hideTabBar(animated: animated)
    }
}

//MARK: - Constants
private extension BubbleTabBarViewController {
    struct Constants {
        static let tabBarMaxWidth: CGFloat = 414
        static let horizontalPadding: CGFloat = 8
        static let verticalPadding: CGFloat = -8
    }
}
