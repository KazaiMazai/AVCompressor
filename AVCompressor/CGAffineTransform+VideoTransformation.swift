//
//  CGAffineTransform+VideoTransformation.swift
//  AVCompressor
//
//  Created by Sergey Kazakov on 23/12/2019.
//  Copyright © 2019 kazaimazai. All rights reserved.
//

import Foundation
  
extension CGAffineTransform {
  init(_ videoTrackOrientation: VideoOrientation, naturalSize: CGSize, crop: CropOff, scale: Scale) {
    let cropOffX = crop.x
    let cropOffY = crop.y
    
    let scaleX = scale.x
    let scaleY = scale.y
    
    let t3 = CGAffineTransform(scaleX: scaleX, y: scaleY)
    
    let finalTransform: CGAffineTransform
    switch videoTrackOrientation {
    case .up:
      let t1 = CGAffineTransform(translationX: naturalSize.height - cropOffX, y: 0.0 - cropOffY)
      let t2 = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
      finalTransform = (t2).concatenating(t1).concatenating(t3)
    case .down:
      let t1 = CGAffineTransform(translationX: 0 - cropOffX, y: naturalSize.width - cropOffY) // not fixed width is the real height in upside down
      let t2 = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
      finalTransform = (t2).concatenating(t1).concatenating(t3)
    case .left:
      let t1 = CGAffineTransform(translationX: naturalSize.width - cropOffX, y: naturalSize.height - cropOffY)
      let t2 = CGAffineTransform(rotationAngle: CGFloat.pi)
      finalTransform = (t2).concatenating(t1).concatenating(t3)
    case .right:
      let t1 = CGAffineTransform(translationX: 0 - cropOffX, y: 0 - cropOffY );
      let t2 = CGAffineTransform(rotationAngle: 0.0)
      finalTransform = (t2).concatenating(t1).concatenating(t3)
    }
    
    self = finalTransform
  }
}

