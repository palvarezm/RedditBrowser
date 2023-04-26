//
//  APIRouter.swift
//  RedditBrowser
//
//  Created by Paul Alvarez on 25/04/23.
//

struct APIRouter {
    struct GetNew: Request {
        typealias ReturnType = GetPostsResponse
        var method: HTTPMethod = .get
        var path: String = ""
        var queryParams: [String : Any]?

        init(queryParams: APIParameters.GetNewParams, path: String) {
            self.path = path
            self.queryParams = queryParams.asDictionary
        }
    }

    struct GetSearchedPosts: Request {
        typealias ReturnType = GetPostsResponse
        var method: HTTPMethod = .get
        var path: String = ""
        var queryParams: [String : Any]?

        init(queryParams: APIParameters.GetSearchedPostsParams, path: String) {
            self.queryParams = queryParams.asDictionary
            self.path = path
        }
    }
}
