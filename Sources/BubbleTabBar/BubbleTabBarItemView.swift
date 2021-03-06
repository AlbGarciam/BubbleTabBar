import UIKit

struct BubbleTabBarItem {
    let expandedIcon: UIImage
    let collapsedIcon: UIImage
    let title: String

    init(expandedIcon: UIImage, collapsedIcon: UIImage, title: String) {
        (self.expandedIcon, self.collapsedIcon, self.title) = (expandedIcon, collapsedIcon, title)
    }
}

protocol BubbleTabBarItemViewDelegate: AnyObject {
    func didTap(on itemView: BubbleTabBarItemView)
}

final class BubbleTabBarItemView: UIView {
    private lazy var imageView = UIImageView()
    private lazy var titleLabel = UILabel()
    private lazy var stackView = UIStackView(arrangedSubviews: [imageView, titleLabel])
    weak var delegate: BubbleTabBarItemViewDelegate?
    var isCollapsed: Bool { titleLabel.isHidden }
    private var expandedIcon: UIImage?
    private var collapsedIcon: UIImage?

    override var tintColor: UIColor! {
        didSet {
            backgroundColor = .clear
            imageView.tintColor = tintColor
            titleLabel.textColor = tintColor
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

    func setExpandedIcon(_ icon: UIImage) {
        expandedIcon = icon
        imageView.image = isCollapsed ? collapsedIcon : expandedIcon
    }

    func setCollapsedIcon(_ icon: UIImage) {
        collapsedIcon = icon
        imageView.image = isCollapsed ? collapsedIcon : expandedIcon
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
        titleLabel.accessibilityLabel = title
    }

    func setTitleFont(_ font: UIFont) {
        titleLabel.font = font
    }

    func collapse() {
        titleLabel.isHidden = true
        titleLabel.alpha = 0
        imageView.image = self.collapsedIcon
    }

    func expand() {
        titleLabel.isHidden = false
        titleLabel.alpha = 1
        imageView.image = self.expandedIcon
    }
}

private extension BubbleTabBarItemView {
    private func configure() {
        configureStackView()
        configureImageView()
        configureTitleLabel()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onViewTapped))
        isUserInteractionEnabled = true
        addGestureRecognizer(tapGesture)
    }

    private func configureStackView() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.setContentHuggingPriority(.required, for: .horizontal)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.spacing = Constants.spacing
        addSubview(stackView)
        stackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.horizontalPadding).isActive = true
        stackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.verticalPadding).isActive = true
    }

    private func configureImageView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.widthAnchor.constraint(equalToConstant: Constants.imageSize.width).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: Constants.imageSize.height).isActive = true
    }

    private func configureTitleLabel() {
        titleLabel.numberOfLines = 1
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.isHidden = true
    }

    @objc
    private func onViewTapped() {
        delegate?.didTap(on: self)
    }
}

private extension BubbleTabBarItemView {
    struct Constants {
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 10
        static let spacing: CGFloat = 6
        static let imageSize: CGSize = .init(width: 24, height: 24)
    }
}
