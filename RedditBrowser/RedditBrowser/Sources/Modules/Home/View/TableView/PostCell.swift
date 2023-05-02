//
//  PostCell.swift
//  RedditBrowser
//
//  Created by Paul Alvarez on 25/04/23.
//

import Combine
import UIKit
import SDWebImage

class PostCell: UITableViewCell {
    // MARK: - Properties
    private lazy var containerCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var postImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleToFill
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var postInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var scoreStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .fillEqually
        view.spacing = Constants.scoreStackViewSpacing
        view.tintColor = .gray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var upButton: UIButton = {
        let view = UIButton()
        view.configuration = .plain()
        view.configuration?.image = UIImage(systemName: "chevron.up")
        return view
    }()

    private lazy var downButton: UIButton = {
        let view = UIButton()
        view.configuration = .plain()
        view.configuration?.image = UIImage(systemName: "chevron.down")
        return view
    }()

    private lazy var scoreLabel: UILabel = {
        let view = UILabel()
        view.font = view.font.withSize(16.0)
        view.textAlignment = .center
        view.tintColor = .gray
        return view
    }()

    private lazy var commentsStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.spacing = Constants.commentsStackViewSpacing
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var commentsImage: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(systemName: "text.bubble.fill")
        view.tintColor = .gray
        return view
    }()

    private lazy var commentsQuantityLabel: UILabel = {
        let view = UILabel()
        view.textColor = .gray
        return view
    }()

    static let identifier = String(describing: PostCell.self)
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Constants
    private enum Constants {
        // Distances
        static let containerCardViewPadding = 16.0
        static let postInfoViewPadding = 16.0
        static let titleLabelLeadingMargin = 16.0
        static let commentsViewTopMargin = 24.0
        static let scoreStackViewSpacing = 2.0
        static let commentsStackViewSpacing = 12.0
        // CardView
        static let cardViewCornerRadius = 20.0
        static let cardViewShadowColor = UIColor.gray
        static let cardViewShadowOffset = CGSize(width: 5.0, height: 5.0)
        static let cardViewShadowRadius = 6.0
        static let cardViewShadowOpacity: Float = 5.0
        // Image
        static let postImageHeight = 210.0
    }

    // MARK: - Lifecycle
    override func layoutSubviews() {
        containerCardView.layer.cornerRadius = Constants.cardViewCornerRadius
        containerCardView.layer.shadowColor = Constants.cardViewShadowColor.cgColor
        containerCardView.layer.shadowOffset = Constants.cardViewShadowOffset
        containerCardView.layer.shadowRadius = Constants.cardViewShadowRadius
        containerCardView.layer.shadowOpacity = Constants.cardViewShadowOpacity
    }

    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setup() {
        self.selectionStyle = .none
        setupContainerCardView()
        setupPostImageView()
        setupPostInfoView()
        setupScoreStackView()
        setupTitleLabel()
        setupCommentsStackView()
    }

    private func setupContainerCardView() {
        addSubview(containerCardView)
        NSLayoutConstraint.activate([
            containerCardView.topAnchor.constraint(equalTo: topAnchor,
                                                   constant: Constants.containerCardViewPadding),
            containerCardView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                       constant: Constants.containerCardViewPadding),
            containerCardView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                        constant: -Constants.containerCardViewPadding),
            containerCardView.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                      constant: -Constants.containerCardViewPadding)
        ])
    }

    private func setupPostImageView() {
        containerCardView.addSubview(postImageView)
        NSLayoutConstraint.activate([
            postImageView.topAnchor.constraint(equalTo: containerCardView.topAnchor),
            postImageView.leadingAnchor.constraint(equalTo: containerCardView.leadingAnchor),
            postImageView.trailingAnchor.constraint(equalTo: containerCardView.trailingAnchor),
            postImageView.heightAnchor.constraint(equalToConstant: Constants.postImageHeight)
        ])
    }

    private func setupPostInfoView() {
        containerCardView.addSubview(postInfoView)
        NSLayoutConstraint.activate([
            postInfoView.topAnchor.constraint(equalTo: postImageView.bottomAnchor),
            postInfoView.leadingAnchor.constraint(equalTo: postImageView.leadingAnchor),
            postInfoView.trailingAnchor.constraint(equalTo: postImageView.trailingAnchor),
            postInfoView.bottomAnchor.constraint(equalTo: containerCardView.bottomAnchor,
                                                 constant: Constants.postInfoViewPadding)
        ])
    }

    private func setupScoreStackView() {
        postInfoView.addSubview(scoreStackView)
        NSLayoutConstraint.activate([
            scoreStackView.topAnchor.constraint(equalTo: postInfoView.topAnchor,
                                                constant: Constants.postInfoViewPadding),
            scoreStackView.leadingAnchor.constraint(equalTo: postInfoView.leadingAnchor,
                                                    constant: Constants.postInfoViewPadding),
            scoreStackView.bottomAnchor.constraint(lessThanOrEqualTo: containerCardView.bottomAnchor)
        ])
        scoreStackView.addArrangedSubview(upButton)
        scoreStackView.addArrangedSubview(scoreLabel)
        scoreStackView.addArrangedSubview(downButton)
    }
    
    private func setupTitleLabel() {
        postInfoView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: postInfoView.topAnchor,
                                            constant: Constants.postInfoViewPadding),
            titleLabel.leadingAnchor.constraint(equalTo: scoreStackView.trailingAnchor,
                                                constant: Constants.titleLabelLeadingMargin),
            titleLabel.trailingAnchor.constraint(equalTo: postInfoView.trailingAnchor,
                                                 constant: -Constants.postInfoViewPadding)
        ])
    }
    
    private func setupCommentsStackView() {
        postInfoView.addSubview(commentsStackView)
        NSLayoutConstraint.activate([
            commentsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                   constant: Constants.postInfoViewPadding),
            commentsStackView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            commentsStackView.bottomAnchor.constraint(lessThanOrEqualTo: containerCardView.bottomAnchor,
                                                      constant: -Constants.postInfoViewPadding)
        ])
        commentsStackView.addArrangedSubview(commentsImage)
        commentsStackView.addArrangedSubview(commentsQuantityLabel)
    }
    
    // MARK: - Configuration
    public func configure(with post: Post) {
        self.titleLabel.text = post.title
        self.scoreLabel.text = post.score
        self.commentsQuantityLabel.text = post.commentsQuantity
        guard let imageURL = URL(string: post.imageURL) else { return }

//        getImage(for: imageURL)
        postImageView.sd_setImage(with: imageURL)
    }

    func getImage(for url: URL) {
        URLSession.shared
            .dataTaskPublisher(for: url)
            .receive(on: DispatchQueue.global())
         .sink { _ in }
        receiveValue: { [weak self] value in
            guard let image = UIImage(data: value.data) else { return }
            DispatchQueue.main.async {
                self?.postImageView.image = image
            }
        }.store(in: &cancellables)
    }
}
