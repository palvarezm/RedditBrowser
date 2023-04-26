//
//  HomeViewModel.swift
//  RedditBrowser
//
//  Created by Paul Alvarez on 25/04/23.
//

import Combine
import Foundation

class HomeViewModel {
    struct Input {
        let viewDidLoadPublisher: AnyPublisher<Void, Never>
        let pullToRefreshPublisher: AnyPublisher<Void, Never>
        let settingsButtonTappedPublisher: AnyPublisher<Void, Never>
        let searchTextPublisher: AnyPublisher<String?, Never>
    }

    struct Output {
        let viewDidLoadPublisher: AnyPublisher<Void, Never>
        let pullToRefreshPublisher: AnyPublisher<Void, Never>
        let searchTextPublisher: AnyPublisher<Void, Never>
        let setDataSourcePublisher: AnyPublisher<[Post], Never>
        let showPermissionCarrouselPublisher: AnyPublisher<Void, Never>
    }

    private var apiClient: APIClient
    private var lastSearched: String = ""
    @Published private var posts: [Post] = []
    @Published private var searchText: String?
    private var cancellables: Set<AnyCancellable> = []

    init(apiClient: APIClient = APIClientImpl()) {
        self.apiClient = apiClient
    }

    // MARK: - Bindings
    func transform(input: Input) -> Output {
        let viewDidLoadPublisher: AnyPublisher<Void, Never> = input.viewDidLoadPublisher.handleEvents(receiveOutput: { [weak self] _ in
            self?.fetchPosts()
        }).flatMap {
            return Just(()).eraseToAnyPublisher()
        }.eraseToAnyPublisher()

        let searchTextPublisher: AnyPublisher<Void, Never> = input.searchTextPublisher.handleEvents(receiveOutput: { [weak self] searchText in
            self?.searchText = searchText
        }).flatMap { _ in
            return Just(()).eraseToAnyPublisher()
        }.eraseToAnyPublisher()

        let setDataSourcePublisher: AnyPublisher<[Post], Never> = Publishers.CombineLatest(
            $posts.compactMap { $0 },
            $searchText)
                .flatMapLatest { [weak self] (posts: [Post], searchText: String?) -> AnyPublisher<[Post], Never> in
                    if let searchText = searchText, !searchText.isEmpty, searchText != self?.lastSearched {
                        self?.lastSearched = searchText
                        self?.fetchSearchedPosts(searchText: searchText)
                    }
                return Just(posts).eraseToAnyPublisher()
                }.eraseToAnyPublisher()

        let settingsButtonTappedPublisher: AnyPublisher<Void, Never> = input.settingsButtonTappedPublisher.handleEvents(receiveOutput: { _ in
            
        }).flatMap {
            return Just(()).eraseToAnyPublisher()
        }.eraseToAnyPublisher()

        let pullToRefreshPublisher: AnyPublisher<Void, Never> = input.pullToRefreshPublisher
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.fetchPosts()
            })
            .flatMap {
                return Just(()).eraseToAnyPublisher()
            }.eraseToAnyPublisher()

        return .init(viewDidLoadPublisher: viewDidLoadPublisher,
                     pullToRefreshPublisher: pullToRefreshPublisher,
                     searchTextPublisher: searchTextPublisher,
                     setDataSourcePublisher: setDataSourcePublisher,
                     showPermissionCarrouselPublisher: settingsButtonTappedPublisher)
    }

    // MARK: - API Calls
    private func fetchPosts() {
        apiClient.dispatch(APIRouter.GetNew(queryParams: APIParameters.GetNewParams(),
                                            path: RedditRequest.new.path))
            .sink { _ in }
            receiveValue: { [weak self] response in
                self?.posts = response.data.posts
                    .filter { $0.postData.postHint == PostHint.image.rawValue }
                    .map { Post(from: $0.postData) }
            }.store(in: &cancellables)
    }
    private func fetchSearchedPosts(searchText: String) {
        apiClient.dispatch(APIRouter.GetSearchedPosts(
            queryParams: APIParameters.GetSearchedPostsParams(searchedText: searchText),
            path: RedditRequest.search.path))
            .sink { _ in }
            receiveValue: { [weak self] response in
                self?.posts = response.data.posts
                    .filter { $0.postData.postHint == PostHint.image.rawValue }
                    .map { Post(from: $0.postData) }
            }.store(in: &cancellables)
    }
}
