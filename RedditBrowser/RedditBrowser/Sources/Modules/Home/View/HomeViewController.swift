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

    private var viewModel: HomeViewModel
    @Published private var posts: [Post] = []

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let searchTextSubject = PassthroughSubject<String?, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Constants
    private enum Constants {
        static let viewBackgroundColor = UIColor.white
        // Margins
        static let settingsButtonTopMargin = 28.0
        static let settingsButtonLeadingMargin = 16.0
        static let searchControllerTopMargin = 12.0
        static let searchControllerHorizontalMargin = 16.0
        static let postsTableViewHorizontalMargin = 16.0
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

        let input = HomeViewModel.Input(viewDidLoadPublisher: viewDidLoadSubject.eraseToAnyPublisher(),
                                        searchTextPublisher: searchTextSubject.eraseToAnyPublisher())
        let output = viewModel.transform(input: input)

        [output.viewDidLoadPublisher, output.searchTextPublisher].forEach { $0.sink { _ in }.store(in: &cancellables) }

        output.setDataSourcePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] posts in
                self?.posts = posts
            }
            .store(in: &cancellables)
    }

    // MARK: - Setup
    private func setup() {
        setupSettingsButton()
        setupSearchController()
        setupPostsTableView()
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
        400.0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        String(format: "%d results found", posts.count)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}