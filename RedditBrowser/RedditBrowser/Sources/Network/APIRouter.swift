//
//  APIRouter.swift
//  RedditBrowser
//
//  Created by Paul Alvarez on 25/04/23.
//

struct APIRouter {
    struct GetNew: Request {
        typealias ReturnType = GetNewResponse
        var method: HTTPMethod = .get
        var queryParams: [String : Any]?

        init(queryParams: APIParameters.GetNewParams) {
            self.queryParams = queryParams.asDictionary
        }
    }
}
