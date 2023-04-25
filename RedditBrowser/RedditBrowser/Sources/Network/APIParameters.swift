//
//  APIParameters.swift
//  RedditBrowser
//
//  Created by Paul Alvarez on 25/04/23.
//

struct APIParameters {
    struct GetNewParams: Encodable {
        var postsLimit: Int = APIConstants.postLimit
        var linkFlairText: String = APIConstants.memeCategory
        var page: String?

        private enum CodingKeys: String, CodingKey {
            case postsLimit = "limit"
            case linkFlairText = "link_flair_text"
            case page = "after"
        }
    }

    struct GetSearchedPostsParams: Encodable {
        var searchedText: String?
        var postsLimit: Int = APIConstants.postLimit
        var linkFlairText: String = APIConstants.memeCategory
        var page: String?

        private enum CodingKeys: String, CodingKey {
            case searchedText = "q"
            case postsLimit = "limit"
            case linkFlairText = "link_flair_text"
            case page = "after"
        }
    }
}
