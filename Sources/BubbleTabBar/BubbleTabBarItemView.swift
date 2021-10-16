import UIKit

struct BubbleTabBarItem {
    let expandedIcon: UIImage
    let collapsedIcon: UIImage
    let title: String

    init(expandedIcon: UIImage, collapsedIcon: UIImage, title: String) {
        (self.expandedIcon, self.collapsedIcon, self.title) = (expandedIcon, collapsedIcon, title)
    }
}

final class BubbleTabBarItemView: UIView {
    private lazy var imageView = UIImageView()
    private lazy var titleLabel = UILabel()
    private lazy var stackView = UIStackView(frame: .zero)

    var selectedContentColor: UIColor = .white {
        didSet {
            isCollapsed ? collapse() : expand()
        }
    }
    var unselectedContentColor: UIColor = .black {
        didSet {
            isCollapsed ? collapse() : expand()
        }
    }
    var selectedBackgroundColor: UIColor = .black {
        didSet {
            isCollapsed ? collapse() : expand()
        }
    }
    var isCollapsed: Bool { titleLabel.isHidden }

    private let expandedIcon: UIImage
    private let collapsedIcon: UIImage
    private let onTap: (BubbleTabBarItemView) -> Void

    init(item: BubbleTabBarItem, onTap: @escaping (BubbleTabBarItemView) -> Void) {
        self.collapsedIcon = item.collapsedIcon
        self.expandedIcon = item.expandedIcon
        self.onTap = onTap
        super.init(frame: .zero)

        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onViewTapped))
        addGestureRecognizer(tapGesture)

        configure()
        titleLabel.text = item.title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func onViewTapped() {
        onTap(self)
    }

    func setTitleFont(_ font: UIFont) {
        titleLabel.font = font
    }

    func collapse() {
        titleLabel.isHidden = true
        titleLabel.alpha = 0
        imageView.image = collapsedIcon.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = unselectedContentColor
        titleLabel.textColor = unselectedContentColor
        backgroundColor = .clear
        layoutIfNeeded()
    }

    func expand() {
        titleLabel.isHidden = false
        titleLabel.alpha = 1
        imageView.image = expandedIcon.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = selectedContentColor
        titleLabel.textColor = selectedContentColor
        backgroundColor = selectedBackgroundColor
        layoutIfNeeded()
    }
}

private extension BubbleTabBarItemView {
    private func configure() {
        configureStackView()
        configureImageView()
        configureTitleLabel()
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 40).isActive = true
        layer.masksToBounds = true
        layer.cornerRadius = 14
    }

    private func configureStackView() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 6
        addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: topAnchor, constant: 2).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2).isActive = true
        stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 2).isActive = true
        stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -2).isActive = true
        let center = stackView.centerXAnchor.constraint(equalTo: centerXAnchor)
        center.priority = .defaultLow
        center.isActive = true
    }

    private func configureImageView() {
        stackView.addArrangedSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
    }

    private func configureTitleLabel() {
        stackView.addArrangedSubview(titleLabel)
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        titleLabel.isHidden = true
    }
}
