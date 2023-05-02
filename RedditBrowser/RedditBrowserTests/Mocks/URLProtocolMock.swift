//
//  URLProtocolMock.swift
//  RedditBrowserTests
//
//  Created by Paul Alvarez on 2/05/23.
//

import Foundation

class URLProtocolMock: URLProtocol {
    static var testURLs = [URL?: Data]()

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if let url = request.url {
            if let data = URLProtocolMock.testURLs[url] {
                let httpResponse = HTTPURLResponse(url: url,
                                                   statusCode: 200,
                                                   httpVersion: "HTTP/1.1",
                                                   headerFields: nil)
                self.client?.urlProtocol(self, didReceive: httpResponse!, cacheStoragePolicy: .notAllowed)
                self.client?.urlProtocol(self, didLoad: data)
            }
        }

        self.client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}

