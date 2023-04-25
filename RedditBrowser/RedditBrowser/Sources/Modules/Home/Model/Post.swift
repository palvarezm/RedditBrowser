//
//  Post.swift
//  RedditBrowser
//
//  Created by Paul Alvarez on 25/04/23.
//

import Foundation

struct Post {
    let imageURL: String
    let title: String
    let score: String
    let commentsQuantity: String

    init(from response: GetPostsResponse.Data.Post.Data) {
        self.imageURL = response.imageURL
        self.title = response.title
        self.score = "\(response.score)"
        self.commentsQuantity = "\(response.commentsQuantity)"
    }
}
