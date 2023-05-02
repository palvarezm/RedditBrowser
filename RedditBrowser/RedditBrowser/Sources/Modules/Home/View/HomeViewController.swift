//
//  HomeViewController.swift
//  RedditBrowser
//
//  Created by Paul Alvarez on 25/04/23.
//

import UIKit
import Combine

class HomeViewController: UIViewController {
    // MARK: - Properties
    private lazy var settingsButton: UIButton = {
        let view = UIButton()
        view.configuration = .plain()
        view.configuration?.image = UIImage(systemName: "gearshape")
        view.tintColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var searchBar: UISearchBar = {
        let view = UISearchBar()
        view.placeholder = "search_bar_text_placeholder".localized
        view.searchBarStyle = .minimal
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var tableView: UITableView = {
        let view = UITableView()
        view.delegate = self
        view.dataSource = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let view = UIRefreshControl()
        return view
    }()

    private var viewModel: HomeViewModel
    @Published private var posts: [Post] = []

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let pullToRefreshSubject = PassthroughSubject<Void,Never>()
    private let settingsButtonTappedSubject = PassthroughSubject<Void, Never>()
    private let searchTextSubject = PassthroughSubject<String?, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Constants
    private enum Constants {
        static let viewBackgroundColor = UIColor.white
        // Margins
        static let settingsButtonTopMargin = 48.0
        static let settingsButtonLeadingMargin = 16.0
        static let searchControllerTopMargin = 12.0
        static let searchControllerHorizontalMargin = 16.0
        static let postsTableViewHorizontalMargin = 16.0
        static let postCellHeight = 400.0
    }

    // MARK: - Initializers
    init(viewModel: HomeViewModel = HomeViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecyle
    override func loadView() {
        super.loadView()
        bindings()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.viewBackgroundColor
        setup()
        viewDidLoadSubject.send()
        searchBar.sizeToFit()
    }

    // MARK: - Bindings
    private func bindings() {
        $posts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        let input = HomeViewModel.Input(
            viewDidLoadPublisher: viewDidLoadSubject.eraseToAnyPublisher(),
            pullToRefreshPublisher: pullToRefreshSubject.eraseToAnyPublisher(),
            settingsButtonTappedPublisher: settingsButtonTappedSubject.eraseToAnyPublisher(),
            searchTextPublisher: searchTextSubject.eraseToAnyPublisher())
        let output = viewModel.transform(input: input)

        [output.viewDidLoadPublisher, output.searchTextPublisher].forEach { $0.sink { _ in }.store(in: &cancellables) }

        output.setDataSourcePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.posts, on: self)
            .store(in: &cancellables)

        output.showPermissionCarrouselPublisher
            .sink { [weak self] _ in
                self?.goToPermissionsCarrouselViewController()
            }
            .store(in: &cancellables)

        output.pullToRefreshPublisher
            .sink { [weak self] _ in
                self?.refreshControl.endRefreshing()
            }
            .store(in: &cancellables)
    }

    // MARK: - Setup
    private func setup() {
        setupSettingsButton()
        setupSettingsButtonAction()
        setupSearchController()
        setupPostsTableView()
        setupRefreshControlAction()
    }

    private func setupSettingsButton() {
        view.addSubview(settingsButton)
        NSLayoutConstraint.activate([
            settingsButton.topAnchor.constraint(equalTo: view.topAnchor,
                                                constant: Constants.settingsButtonTopMargin),
            settingsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                    constant: Constants.settingsButtonLeadingMargin)
        ])
    }
    
    private func setupSearchController() {
        view.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(
                equalTo: settingsButton.bottomAnchor,
                constant: Constants.searchControllerTopMargin),
            searchBar.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Constants.searchControllerHorizontalMargin),
            searchBar.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constants.searchControllerHorizontalMargin),
        ])
    }

    private func setupPostsTableView() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                               constant: Constants.postsTableViewHorizontalMargin),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                constant: -Constants.postsTableViewHorizontalMargin),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.register(PostCell.self, forCellReuseIdentifier: PostCell.identifier)
        tableView.refreshControl = refreshControl
    }

    // MARK: - Actions
    private func setupSettingsButtonAction() {
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
    }

    @objc
    private func settingsButtonTapped() {
        settingsButtonTappedSubject.send()
    }

    private func goToPermissionsCarrouselViewController() {
        let permissionsCarrouselVC = PermissionsCarrouselViewController()
        present(permissionsCarrouselVC, animated: false)
    }

    private func setupRefreshControlAction() {
        refreshControl.addTarget(self, action: #selector(pullToRefreshTriggered), for: .valueChanged)
    }

    @objc
    private func pullToRefreshTriggered() {
        pullToRefreshSubject.send()
    }
}

// MARK: - UISearchBarDelegate
extension HomeViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTextSubject.send(searchText)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.identifier,
                                                       for: indexPath) as? PostCell else { return UITableViewCell() }

        let post = posts[indexPath.item]
        cell.configure(with: post)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Constants.postCellHeight
    }
}
