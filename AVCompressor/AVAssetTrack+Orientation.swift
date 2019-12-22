//
//  AVAssetTrack+Orientation.swift
//  AVCompressor
//
//  Created by Sergey Kazakov on 23/12/2019.
//  Copyright © 2019 kazaimazai. All rights reserved.
//

import AVKit

internal extension AVAssetTrack {
  func orientation() -> UIImage.Orientation {
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
  
  func originalSizeForVideoTrackOrinentation() -> CGSize {
    let videoTrackOrientation = orientation()
    
    let videoMinDimension = min(naturalSize.width, naturalSize.height)
    let videoMaxDimension = max(naturalSize.width, naturalSize.height)
    
    
    var originalSize = CGSize.zero
    switch videoTrackOrientation {
    case .up, .down:
      originalSize = CGSize(width: videoMinDimension, height: videoMaxDimension)
    case .left, .right:
      originalSize = naturalSize
    default:
      break
    }
    
    return originalSize
  }
}

