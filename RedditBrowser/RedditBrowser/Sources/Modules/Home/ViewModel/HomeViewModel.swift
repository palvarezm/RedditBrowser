//
//  HomeViewModel.swift
//  RedditBrowser
//
//  Created by Paul Alvarez on 25/04/23.
//

import Combine

class HomeViewModel {
    struct Input {
        let viewDidLoadPublisher: AnyPublisher<Void, Never>
        let searchTextPublisher: AnyPublisher<String?, Never>
    }

    struct Output {
        let viewDidLoadPublisher: AnyPublisher<Void, Never>
        let searchTextPublisher: AnyPublisher<Void, Never>
        let setDataSourcePublisher: AnyPublisher<[Post], Never>
    }

    private var apiClient: APIClient
    @Published private var posts: [Post] = []
    @Published private var searchText: String?
    private var cancellables: Set<AnyCancellable> = []

    init(apiClient: APIClient = APIClientImpl()) {
        self.apiClient = apiClient
    }

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
                .flatMap { (posts: [Post], searchText: String?) -> AnyPublisher<[Post], Never> in
                if let searchText = searchText, !searchText.isEmpty {
                    #warning("Implement search")
                    debugPrint("filter \(searchText)")
                    // TODO: Set posts to response data
                }
                return Just(posts).eraseToAnyPublisher()
            }.eraseToAnyPublisher()

        return .init(viewDidLoadPublisher: viewDidLoadPublisher,
                     searchTextPublisher: searchTextPublisher,
                     setDataSourcePublisher: setDataSourcePublisher)
    }

    private func fetchPosts() {
        apiClient.dispatch(APIRouter.GetNew(queryParams: APIParameters.GetNewParams()))
            .sink { _ in }
            receiveValue: { [weak self] response in
                self?.posts = response.data.posts
                    .filter { $0.postData.postHint == PostHint.image.rawValue }
                    .map { Post(from: $0.postData) }
            }.store(in: &cancellables)
    }
}
