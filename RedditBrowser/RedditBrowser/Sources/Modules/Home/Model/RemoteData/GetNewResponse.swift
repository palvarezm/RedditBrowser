//
//  GetNewResponse.swift
//  RedditBrowser
//
//  Created by Paul Alvarez on 25/04/23.
//

enum PostHint: String {
    case image = "image"
}

struct GetNewResponse: Codable {
    var data: Data

    struct Data: Codable {
        var after: String
        var posts: [Post]

        enum CodingKeys: String, CodingKey {
            case after
            case posts = "children"
        }

        struct Post: Codable {
            var postData: Data

            struct Data: Codable {
                var title: String
                var imageURL: String
                var score: Int
                var commentsQuantity: Int
                var postHint: String?

                enum CodingKeys: String, CodingKey {
                    case title, score
                    case imageURL = "url"
                    case commentsQuantity = "num_comments"
                    case postHint = "post_hint"
                }
            }

            enum CodingKeys: String, CodingKey {
                case postData = "data"
            }
        }
    }
}
