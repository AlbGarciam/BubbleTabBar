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
    private weak var topController: UIViewController?
    private weak var blurView: UIView?

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

    public var blurColor: UIColor? {
        didSet {
            blurView?.backgroundColor = blurColor
        }
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
        if let firstController = viewControllers.first {
            setCurrentController(firstController)
        }
    }

    public func setTopChild(_ controller: UIViewController, disableTouches: Bool = false) {
        removeTopChild(restoreTouches: !disableTouches)
        topController = controller
        topController?.willMove(toParent: self)
        addChild(controller)
        setTopView(controller.view, disableTouches: disableTouches)
        topController?.didMove(toParent: self)
    }

    public func setTopView(_ view: UIView, disableTouches: Bool = false) {
        removeTopView(restoreTouches: !disableTouches)
        tabBarView.addTopView(view: view)
        if disableTouches && blurView == nil {
            self.disableTouches()
        }
    }

    public func removeTopChild(restoreTouches: Bool = true) {
        topController?.willMove(toParent: nil)
        topController?.removeFromParent()
        removeTopView(restoreTouches: restoreTouches)
        topController?.didMove(toParent: nil)
    }

    public func removeTopView(restoreTouches: Bool = true) {
        tabBarView.removeTopView()
        if restoreTouches && blurView != nil {
            enableTouches()
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
        tabBarView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor,
                                             constant: -Constants.horizontalPadding).isActive = true
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
        view.insertSubview(controller.view, belowSubview: blurView ?? tabBarView)
        controller.view.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        controller.view.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        controller.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        controller.view.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        currentController = controller
        view.setNeedsLayout()
        view.layoutIfNeeded()
        updateContentArea(of: controller.view)
        (currentController as? UINavigationController)?.delegate = self
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

    func updateContentArea(of view: UIView) {
        let tabBarFrame = tabBarView.convert(tabBarView.frame, from: self.view)
        let subviewFrame = view.convert(view.frame, from: self.view)
        let overlapping = tabBarFrame.intersects(subviewFrame)
        guard overlapping else { return }
        guard let scrollView = view as? UIScrollView else {
            return view.subviews.forEach { self.updateContentArea(of: $0) }
        }
        let intersection = tabBarFrame.intersection(subviewFrame)
        var edgeInsets = scrollView.contentInset
        edgeInsets.bottom = intersection.height + Constants.bottomPadding
        scrollView.contentInset = edgeInsets
    }


    func disableTouches() {
        let blurView = UIView(frame: view.bounds)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.alpha = 0
        view.insertSubview(blurView, belowSubview: tabBarView)
        blurView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        blurView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        blurView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        blurView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.blurView = blurView
        UIView.animate(withDuration:0.2) {
            blurView.alpha = 1
        }
    }

    func enableTouches() {
        UIView.animate(withDuration: 0.2, animations: {
            self.blurView?.alpha = 0
        }) { (_) in
            self.blurView?.removeFromSuperview()
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

    func didCollapse() {
        guard let controller = currentController else { return }
        updateContentArea(of: controller.view)
    }

    func didExpand() {
        guard let controller = currentController else { return }
        updateContentArea(of: controller.view)
    }
}

extension BubbleTabBarViewController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController,
                                     willShow viewController: UIViewController,
                                     animated: Bool) {
        let barWasHidden = bottomConstraint?.constant != Constants.verticalPadding
        let shouldDisplayTabBar = viewController.hidesBottomBarWhenPushed
        !shouldDisplayTabBar ? showTabBar(animated: animated) : hideTabBar(animated: animated)
        guard let coordinator = navigationController.topViewController?.transitionCoordinator else { return }
        coordinator.notifyWhenInteractionChanges { [weak self] context in
            guard context.isCancelled else { return }
            barWasHidden ? self?.hideTabBar(animated: animated) : self?.showTabBar(animated: animated)
        }
    }

    public func navigationController(_ navigationController: UINavigationController,
                                     didShow viewController: UIViewController,
                                     animated: Bool) {
        guard navigationController == currentController else { return }
        updateContentArea(of: viewController.view)
    }
}

//MARK: - Constants
private extension BubbleTabBarViewController {
    struct Constants {
        static let tabBarMaxWidth: CGFloat = 414
        static let horizontalPadding: CGFloat = 8
        static let verticalPadding: CGFloat = -8
        static let bottomPadding: CGFloat = 16
    }
}
