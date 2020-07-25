//
//  CALayer+SketchShadow.swift
//  Sound
//
//  Created by Alberto García-Muñoz on 01/09/2019.
//  Copyright © 2019 SoundApp. All rights reserved.
//

import UIKit

extension CALayer {
    func applyShadow(
        color: CGColor?,
        alpha: Float = 1,
        x: CGFloat = 0,
        y: CGFloat = 0,
        blur: CGFloat = 10,
        spread: CGFloat = 0)
    {
        shadowColor = color
        shadowOpacity = alpha
        shadowOffset = CGSize(width: x, height: y)
        shadowRadius = blur / 2.0
        if spread == 0 {
            shadowPath = nil
        } else {
            let dx = -spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            shadowPath = UIBezierPath(rect: rect).cgPath
        }
    }
}
