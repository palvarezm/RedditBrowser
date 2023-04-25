//
//  String+Extension.swift
//  RedditBrowser
//
//  Created by Paul Alvarez on 24/04/23.
//

import Foundation

extension String {
    // MARK: - Language string assets
    var localized: String {
        return NSLocalizedString(self, comment: "\(self)_comment")
    }
    
    func localized(_ args: CVarArg...) -> String {
        return String(format: localized, args)
    }
}
