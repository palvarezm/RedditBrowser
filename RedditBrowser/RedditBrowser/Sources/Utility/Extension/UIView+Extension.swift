//
//  UIView+Extension.swift
//  RedditBrowser
//
//  Created by Paul Alvarez on 25/04/23.
//

import UIKit

extension UIView {
    func fadeTransition(for duration: CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.fade
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
}
