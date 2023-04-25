//
//  PermissionsCarrouselViewController.swift
//  RedditBrowser
//
//  Created by Paul Alvarez on 23/04/23.
//

import UIKit
import Combine

// MARK: - PermissionViewType
enum PermissionViewType: Int {
    case requestCamera
    case requestNotifications
    case requestLocations

    var permissionType: PermissionType {
        switch self {
        case .requestCamera: return .camera
        case .requestNotifications: return .notifications
        case .requestLocations: return .location
        }
    }

    var permissionImage: UIImage? {
        switch self {
        case .requestCamera: return UIImage(named: "camera_permission")
        case .requestNotifications: return UIImage(named: "notification_permission")
        case .requestLocations: return UIImage(named: "location_permission")
        }
    }

    var titleLabel: String {
        switch self {
        case .requestCamera: return "request_camera_permission_title_label".localized
        case .requestNotifications: return "request_notifications_permission_title_label".localized
        case .requestLocations: return "request_location_permission_title_label".localized
        }
    }

    var descriptionLabel: String {
        switch self {
        case .requestCamera: return "request_camera_permission_description_label".localized
        case .requestNotifications: return "request_notifications_permission_description_label".localized
        case .requestLocations: return "request_location_permission_description_label".localized
        }
    }

    var allowButtonLabel: String {
        switch self {
        case .requestCamera: return "request_camera_permission_allow_button".localized
        case .requestNotifications: return "request_notifications_permission_allow_button".localized
        case .requestLocations: return "request_location_permission_allow_button".localized
        }
    }
}

// MARK: - PermissionsCarrouselViewController
class PermissionsCarrouselViewController: UIViewController {
    // MARK: - Properties
    private lazy var permissionImageView: UIImageView = {
        let view = UIImageView()
        view.image = viewModel.type?.permissionImage
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.text = viewModel.type?.titleLabel
        view.font = UIFont.boldSystemFont(ofSize: Constants.titleLabelFontSize)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var descriptionLabel: UILabel = {
        let view = UILabel()
        view.text = viewModel.type?.descriptionLabel
        view.numberOfLines = 0
        view.textAlignment = .center
        view.font = view.font.withSize(Constants.descriptionLabelFontSize)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var allowButton: UIButton = {
        let view = UIButton()
        view.configuration = .bordered()
        view.configuration?.title = viewModel.type?.allowButtonLabel
        view.configuration?.baseForegroundColor = .white
        view.clipsToBounds = true
        view.layer.cornerRadius = Constants.buttonCornerRadius
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var cancelButton: UIButton = {
        let view = UIButton()
        view.configuration = .bordered()
        view.configuration?.baseBackgroundColor = Constants.viewBackgroundColor
        view.configuration?.baseForegroundColor = .gray
        view.configuration?.title = "request_permission_cancel_button".localized
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var viewModel: PermissionsCarrouselViewModel
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let allowButtonTappedSubject = PassthroughSubject<Void, Never>()
    private let cancelButtonTappedSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Constants
    private enum Constants {
        static let viewBackgroundColor = UIColor.white
        // Margins
        static let imageTopMargin = 100.0
        static let titleLabelTopMargin = 48.0
        static let descriptionLabelTopMargin = 12.0
        static let descriptionLabelHorizontalMargin = 64.0
        static let allowButtonTopMargin = 50.0
        static let buttonHorizontalMargin = 95.0
        static let cancelButtonTopMargin = 12.0
        // Button
        static let buttonCornerRadius = 24.0
        static let buttonHeight = 48.0
        static let buttonGradientStartPoint = CGPoint(x: 0.0, y: 1.0)
        static let buttonGradientEndPoint = CGPoint(x: 1.0, y: 0.0)
        static let buttonTopGradientColor = UIColor.red
        static let buttonBottomGradientColor = UIColor.orange
        // Font
        static let titleLabelFontSize = 24.0
        static let descriptionLabelFontSize = 16.0
        // Animation
        static let fadeTime = 0.35
    }

    // MARK: - Initializers
    init(viewModel: PermissionsCarrouselViewModel = PermissionsCarrouselViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Lifecycle
    override func loadView() {
        super.loadView()
        bindings()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewDidLoadSubject.send()
        view.backgroundColor = Constants.viewBackgroundColor
        setup()
    }

    override func viewDidLayoutSubviews() {
        applyGradientToAllowButton()
    }

    // MARK: - Bindings
    private func bindings() {
        let input = PermissionsCarrouselViewModel.Input(
            viewDidLoadPublisher: viewDidLoadSubject.eraseToAnyPublisher(),
            allowButtonTappedPublisher: allowButtonTappedSubject.eraseToAnyPublisher(),
            cancelButtonTappedPublisher: cancelButtonTappedSubject.eraseToAnyPublisher())
        let output = viewModel.transform(input: input)

        output.setViewTypePublisher
            .sink { [weak self] viewType in
                self?.configureViewType(viewType: viewType)
            }
            .store(in: &cancellables)

        output.changeViewTypePublisher
            .sink { [weak self] viewType in
                if let viewType = viewType {
                    self?.configureViewType(viewType: viewType)
                } else {
                    self?.goToHomeViewController()
                }
            }
            .store(in: &cancellables)

        [output.allowButtonTappedPublisher, output.cancelButtonTappedPublisher].forEach {
            $0.sink { _ in }
            .store(in: &cancellables)
        }
    }

    // MARK: - Setup
    private func setup() {
        setupPermissionImageView()
        setupTitleLabel()
        setupDescriptionLabel()
        setupAllowButton()
        setupAllowButtonAction()
        setupCancelButton()
        setupCancelButtonAction()
    }
    
    private func setupPermissionImageView() {
        view.addSubview(permissionImageView)
        NSLayoutConstraint.activate([
            permissionImageView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor,
                                                     constant: Constants.imageTopMargin),
            permissionImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupTitleLabel() {
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: permissionImageView.bottomAnchor,
                                            constant: Constants.titleLabelTopMargin),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupDescriptionLabel() {
        view.addSubview(descriptionLabel)
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                  constant: Constants.descriptionLabelTopMargin),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                       constant: Constants.descriptionLabelHorizontalMargin),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                       constant: -Constants.descriptionLabelHorizontalMargin),
            
        ])
    }
    
    private func setupAllowButton() {
        view.addSubview(allowButton)
        NSLayoutConstraint.activate([
            allowButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor,
                                             constant: Constants.allowButtonTopMargin),
            allowButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                 constant: Constants.buttonHorizontalMargin),
            allowButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                 constant: -Constants.buttonHorizontalMargin),
            allowButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight)
        ])
    }

    private func setupCancelButton() {
        view.addSubview(cancelButton)
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: allowButton.bottomAnchor,
                                              constant: Constants.cancelButtonTopMargin),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                  constant: Constants.buttonHorizontalMargin),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                   constant: -Constants.buttonHorizontalMargin),
            cancelButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight)
        ])
    }

    // MARK: - Style
    private func applyGradientToAllowButton() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = allowButton.bounds
        gradientLayer.colors = [Constants.buttonTopGradientColor.cgColor,
                                Constants.buttonBottomGradientColor.cgColor]
        gradientLayer.startPoint = Constants.buttonGradientStartPoint
        gradientLayer.endPoint = Constants.buttonGradientEndPoint
        gradientLayer.locations = [0.0, 1.0]
        allowButton.layer.insertSublayer(gradientLayer, at: 0)
    }

    // MARK: - ConfigureViewType
    private func configureViewType(viewType: PermissionViewType) {
        [permissionImageView, titleLabel, descriptionLabel, allowButton].forEach { $0.fadeTransition(for: Constants.fadeTime) }
        permissionImageView.image = viewType.permissionImage
        titleLabel.text = viewType.titleLabel
        descriptionLabel.text = viewType.descriptionLabel
        allowButton.configuration?.title = viewType.allowButtonLabel
    }

    // MARK: - Actions
    private func setupAllowButtonAction() {
        allowButton.addTarget(self, action: #selector(didTapAllowButton), for: .touchUpInside)
    }

    private func setupCancelButtonAction() {
        cancelButton.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
    }

    @objc
    private func didTapAllowButton() {
        allowButtonTappedSubject.send()
    }

    @objc
    private func didTapCancelButton() {
        cancelButtonTappedSubject.send()
    }

    private func goToHomeViewController() {
        let homeVC = HomeViewController()
        homeVC.modalPresentationStyle = .fullScreen
        present(homeVC, animated: false)
    }
}
