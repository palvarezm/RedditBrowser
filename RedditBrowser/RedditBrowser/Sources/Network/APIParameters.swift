//
//  APIParameters.swift
//  RedditBrowser
//
//  Created by Paul Alvarez on 25/04/23.
//

struct APIParameters {
    struct GetNewParams: Encodable {
        var format: String = "json"
        var page: String?
        var postsLimit: Int = APIConstants.postLimit
        var linkFlairText: String = APIConstants.memeCategory

        private enum CodingKeys: String, CodingKey {
            case format
            case postsLimit = "limit"
            case page = "after"
            case linkFlairText = "link_flair_text"
        }
    }
}
