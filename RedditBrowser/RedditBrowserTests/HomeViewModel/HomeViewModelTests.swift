//
//  RedditBrowserTests.swift
//  RedditBrowserTests
//
//  Created by Paul Alvarez on 23/04/23.
//

import XCTest
import Combine
@testable import RedditBrowser

class HomeViewModelTests: XCTestCase {
    private var sut: HomeViewModel!

    private let viewDidLoadEvent = PassthroughSubject<Void, Never>()
    private let pullToRefreshEvent = PassthroughSubject<Void, Never>()
    private let settingsButtonTappedEvent = PassthroughSubject<Void, Never>()
    private let searchTextEvent = PassthroughSubject<String?, Never>()
    private let scrolledToBottomEvent = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        sut = .init()
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testSetDataSourceWhenViewDidLoadEventIsTriggered() {
        // Given
        let urlString = APIConstants.baseURL + RedditRequest.new.path
        let queryParamsString = ["?link_flair_text=Shitposting&limit=100",
                                 "?limit=100&link_flair_text=Shitposting"]
        let mockAPIClient = getMockAPIFromJSON(urlString: urlString,
                                               queryParamsString: queryParamsString,
                                               fileName: "newShitpostingPostsResponse")
        sut = .init(apiClient: mockAPIClient)
        let output = buildOutput()
        let expectation = XCTestExpectation(description: "Response received")

        // Then
        output.viewDidLoadPublisher.sink { _ in }.store(in: &cancellables)
        output.setDataSourcePublisher
            // setDataSourcePublisher uses CombineLatest for searchText AND posts (2)
            .dropFirst(2)
            .sink { posts in
                XCTAssertEqual(posts.count, 2)
                guard let secondPost = posts.first else { return }
                XCTAssert(secondPost.title.starts(with: "ciclistas de Chile,"))
                XCTAssertEqual(secondPost.commentsQuantity, "0")
                XCTAssertEqual(secondPost.imageURL, "https://www.reddit.com/r/chile/comments/135xq47/ciclistas_de_chile_qué_bici_me_recomendarían/")
                XCTAssertEqual(secondPost.score, "1")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        viewDidLoadEvent.send()
        wait(for: [expectation], timeout:  1)
    }

    func testSetDataSourceWhenPullToRefreshIsTriggered() {
        // Given
        let urlString = APIConstants.baseURL + RedditRequest.new.path
        let queryParamsString = ["?link_flair_text=Shitposting&limit=100",
                                 "?limit=100&link_flair_text=Shitposting"]
        let mockAPIClient = getMockAPIFromJSON(urlString: urlString,
                                               queryParamsString: queryParamsString,
                                               fileName: "newShitpostingPostsResponse")
        sut = .init(apiClient: mockAPIClient)
        let output = buildOutput()
        let viewDidLoadExpectation = XCTestExpectation()
        let pullToRefreshExpectation = XCTestExpectation()
        var viewDidLoaded = false

        [output.viewDidLoadPublisher,
         output.pullToRefreshPublisher].forEach { $0.sink { _ in }.store(in: &cancellables) }
        output.setDataSourcePublisher
            // setDataSourcePublisher uses CombineLatest for searchText AND posts (2)
            .dropFirst(2)
            .sink { posts in
                if !viewDidLoaded {
                    viewDidLoaded = true
                    viewDidLoadExpectation.fulfill()
                } else if !posts.isEmpty { // Ignores reseting the posts and searchText
                    // Then
                    XCTAssertEqual(posts.count, 2)
                    guard let secondPost = posts.first else { return }
                    XCTAssert(secondPost.title.starts(with: "ciclistas de Chile,"))
                    XCTAssertEqual(secondPost.commentsQuantity, "0")
                    XCTAssertEqual(secondPost.imageURL, "https://www.reddit.com/r/chile/comments/135xq47/ciclistas_de_chile_qué_bici_me_recomendarían/")
                    XCTAssertEqual(secondPost.score, "1")
                    pullToRefreshExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        viewDidLoadEvent.send()
        wait(for: [viewDidLoadExpectation], timeout:  1)

        // When
        pullToRefreshEvent.send()
        wait(for: [pullToRefreshExpectation], timeout: 1)
    }

    func testWhenSettingButtonIsTappedSettingButtonActionIsTriggered() {
        // Given
        let output = buildOutput()
        let expectation = XCTestExpectation(description: "Setting button action triggered")

        // Then
        output.showPermissionCarrouselPublisher
            .sink {
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        settingsButtonTappedEvent.send()
        wait(for: [expectation], timeout:  1)
    }

    func testSetDataSourceWhenSearchTextIsUpdated() {
        // Given
        let urlString = APIConstants.baseURL + RedditRequest.search.path
        debugPrint(urlString)
        let queryParamsString = ["?limit=100&link_flair_text=Shitposting&q=Valparaiso",
                                 "?link_flair_text=Shitposting&limit=100&q=Valparaiso",
                                 "?q=Valparaiso&limit=100&link_flair_text=Shitposting",
                                 "?limit=100&q=Valparaiso&link_flair_text=Shitposting",
                                 "?link_flair_text=Shitposting&q=Valparaiso&limit=100",
                                 "?q=Valparaiso&link_flair_text=Shitposting&limit=100"]

        let mockAPIClient = getMockAPIFromJSON(urlString: urlString,
                                               queryParamsString: queryParamsString,
                                               fileName: "searchValparaisoShitPostingPostsResponse")
        sut = .init(apiClient: mockAPIClient)
        let output = buildOutput()
        let expectation = XCTestExpectation(description: "Waiting for search response")

        // Then
        output.searchTextPublisher.sink { _ in }.store(in: &cancellables)
        output.setDataSourcePublisher
            .dropFirst(2)
            .sink { posts in
                if !posts.isEmpty { // Ignores reseting the posts and searchText
                    XCTAssertEqual(posts.count, 2)
                    guard let firstPost = posts.first else { return }
                    XCTAssert(firstPost.title.starts(with: "[Thamel] Sources:"))
                    XCTAssertEqual(firstPost.commentsQuantity, "42")
                    XCTAssertEqual(firstPost.imageURL, "https://twitter.com/PeteThamel/status/1644361619508477952")
                    XCTAssertEqual(firstPost.score, "236")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        searchTextEvent.send("Valparaiso")
        wait(for: [expectation], timeout: 1)
    }
}

// MARK: - HomeViewModelTests Helpers
extension HomeViewModelTests {
    private func buildOutput() -> HomeViewModel.Output {
        let input = HomeViewModel.Input(
            viewDidLoadPublisher: viewDidLoadEvent.eraseToAnyPublisher(),
            pullToRefreshPublisher: pullToRefreshEvent.eraseToAnyPublisher(),
            settingsButtonTappedPublisher: settingsButtonTappedEvent.eraseToAnyPublisher(),
            searchTextPublisher: searchTextEvent.eraseToAnyPublisher(),
            scrolledToBottomPublisher: scrolledToBottomEvent.eraseToAnyPublisher()
        )
        
        let output = sut.transform(input: input)
        return output
    }
}
