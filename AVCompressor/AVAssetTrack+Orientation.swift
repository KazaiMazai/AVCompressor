//
//  AVAssetTrack+Orientation.swift
//  AVCompressor
//
//  Created by Sergey Kazakov on 23/12/2019.
//  Copyright © 2019 kazaimazai. All rights reserved.
//

import AVKit

extension AVAssetTrack {
  var orientationForPreferredTransform: VideoOrientation {
    let size = naturalSize
    let txf = preferredTransform
    
    if size.width == txf.tx && size.height == txf.ty {
      return .left
    }
    
    if txf.tx == 0 && txf.ty == 0 {
      return .right
    }
    
    if txf.tx == 0 && txf.ty == size.width {
      return .down
    }
    
    return .up
  }
  
  var originalSizeForOrientation: CGSize {
    let videoTrackOrientation = orientationForPreferredTransform
    
    let videoMinDimension = min(naturalSize.width, naturalSize.height)
    let videoMaxDimension = max(naturalSize.width, naturalSize.height)
    
    
    var originalSize = CGSize.zero
    switch videoTrackOrientation {
    case .up, .down:
      originalSize = CGSize(width: videoMinDimension, height: videoMaxDimension)
    case .left, .right:
      originalSize = naturalSize
    }
    
    return originalSize
  }
  
  func affineTransformFor(crop: CropOff, scale: Scale) -> CGAffineTransform {
    let videoTrackOrientation = orientationForPreferredTransform
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
    
    return finalTransform
  }
}

