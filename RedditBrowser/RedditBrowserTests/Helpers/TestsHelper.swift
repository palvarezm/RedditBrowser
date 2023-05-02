//
//  TestsHelper.swift
//  RedditBrowserTests
//
//  Created by Paul Alvarez on 2/05/23.
//

import XCTest
@testable import RedditBrowser

extension XCTestCase {
    func loadJSONDataFromFile(named fileName: String) throws -> Data {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: fileName, withExtension: "json") else {
            throw NSError(domain: "File \(fileName).json not found", code: 1, userInfo: nil)
        }

        return try Data(contentsOf: url)
    }

    func getMockAPIFromJSON(urlString: String, queryParamsString: [String], fileName: String) -> APIClient {
        let urls = queryParamsString.map { URL(string: urlString + $0) }
        do {
            let jsonData = try loadJSONDataFromFile(named: fileName)
            urls.forEach { URLProtocolMock.testURLs.updateValue(jsonData, forKey: $0) }
        } catch {
            XCTFail("Error loading JSON data: \(error.localizedDescription)")
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]

        let session =  URLSession(configuration: config)

        let dispatcher = NetworkDispatcher(urlSession: session)
        return APIClient(networkDispatcher: dispatcher)
    }
}
