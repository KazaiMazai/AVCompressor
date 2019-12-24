//
//  VideoTransformationParametersSource.swift
//  AVCompressor
//
//  Created by Sergey Kazakov on 22/12/2019.
//  Copyright © 2019 kazaimazai. All rights reserved.
//

import UIKit

typealias Scale = CGPoint
typealias CropOff = CGPoint

struct VideoTransformationParameters {
  let targetSize: CGSize
  let crop: CropOff
  let scale: Scale
}

class VideoTransformationComposer {
  let originalSize: CGSize
  let cropPerCent: Crop
  let resizeContentMode: ResizeContentMode
  
  lazy var transformationParameters: VideoTransformationParameters = {
    return getVideoTransformationParametersFor(originalSize, cropPerCent: cropPerCent, resizeContentMode: resizeContentMode)
  }()
  
  init(originalSize: CGSize, cropPerCent: Crop, resizeContentMode: ResizeContentMode) {
    self.originalSize = originalSize
    self.cropPerCent = cropPerCent
    self.resizeContentMode = resizeContentMode
  }
  
  fileprivate func getVideoTransformationParametersFor(_ originalSize: CGSize, cropPerCent: Crop, resizeContentMode: ResizeContentMode) -> VideoTransformationParameters {
    var cropOffX: CGFloat = 0.0
    var cropOffY: CGFloat = 0.0
    
    var scaleX: CGFloat = 1.0
    var scaleY: CGFloat = 1.0
    
    let widthCropScale = (cropPerCent.left + cropPerCent.right) / 100
    let heightCropScale = (cropPerCent.top + cropPerCent.bottom) / 100
    
    var targetSize = CGSize(width: (originalSize.width * (1.0 - widthCropScale)),
                            height: (originalSize.height * (1.0 - heightCropScale)))
    
    cropOffX = (originalSize.width * cropPerCent.left / 100.0)
    cropOffY = (originalSize.height * cropPerCent.top / 100.0)
    
    switch resizeContentMode {
    case .aspectFill(let targetSizeToFill):
      var targetAspectRatio = targetSize.height / targetSize.width
      let targetSizeToFillRatio = targetSizeToFill.height / targetSizeToFill.width
      
      if targetAspectRatio > targetSizeToFillRatio {
        let targetHeight = (targetSize.width * targetSizeToFillRatio)
        cropOffY += ((targetSize.height - targetHeight) / 2)
        targetAspectRatio = targetSizeToFillRatio
        targetSize = CGSize(width: targetSize.width, height: targetHeight)
        
        
        scaleX = targetSizeToFill.width  / targetSize.width
        scaleY = targetSizeToFill.width  / targetSize.width
      }
      
      if targetAspectRatio <= targetSizeToFillRatio {
        let targetWidth = targetSize.height / targetSizeToFillRatio
        cropOffX += ((targetSize.width - targetWidth) / 2)
        targetAspectRatio = targetSizeToFillRatio
        targetSize = CGSize(width: targetWidth, height: targetSize.height)
        
        scaleX = targetSizeToFill.height  / targetSize.height
        scaleY = targetSizeToFill.height  / targetSize.height
      }
      
    case .aspectFit(let targetSizeToFill):
      var targetAspectRatio = targetSize.height / targetSize.width
      let targetSizeToFillRatio = targetSizeToFill.height / targetSizeToFill.width
      
      if targetAspectRatio < targetSizeToFillRatio {
        let targetHeight = (targetSize.width * targetSizeToFillRatio)
        cropOffY -= ((targetSize.height - targetHeight) / 2)
        targetAspectRatio = targetSizeToFillRatio
        targetSize = CGSize(width: targetSize.width, height: targetHeight)
        
        
        scaleX = targetSizeToFill.width  / targetSize.width
        scaleY = targetSizeToFill.width  / targetSize.width
      }
      
      if targetAspectRatio >= utargetSizeToFillRatio {
        let targetWidth = targetSize.height / targetSizeToFillRatio
        cropOffX -= ((targetSize.width - targetWidth) / 2)
        targetAspectRatio = targetSizeToFillRatio
        targetSize = CGSize(width: targetWidth, height: targetSize.height)
        
        scaleX = targetSizeToFill.height  / targetSize.height
        scaleY = targetSizeToFill.height  / targetSize.height
      }
    case .aspectRatioBestFill(let limits):
      var targetAspectRatio = targetSize.height / targetSize.width
      if targetAspectRatio > limits.videoMaxPortraitAspectRatio {
        let targetHeight = (targetSize.width * limits.videoMaxPortraitAspectRatio)
        cropOffY += ((targetSize.height - targetHeight) / 2)
        targetAspectRatio = limits.videoMaxPortraitAspectRatio
        targetSize = CGSize(width: targetSize.width, height: targetHeight)
      }
      
      if targetAspectRatio < limits.videoMinLandscapeAspectRatio {
        let targetWidth = targetSize.height / limits.videoMinLandscapeAspectRatio
        cropOffX = ((targetSize.width - targetWidth) / 2)
        targetAspectRatio = limits.videoMinLandscapeAspectRatio
        targetSize = CGSize(width: targetWidth, height: targetSize.height)
      }
      
      if targetSize.width < limits.videoMinWidth {
        scaleX = limits.videoMinWidth  / targetSize.width
        scaleY = limits.videoMinWidth  / targetSize.width
      }
      
      if targetSize.width > limits.videoMaxWidth {
        scaleX = limits.videoMaxWidth  / targetSize.width
        scaleY = limits.videoMaxWidth  / targetSize.width
      }
    case .none:
      break
    }
    
    
    let renderSizeWidth = (targetSize.width * scaleX).rounded()
    let renderSizeHeight = (targetSize.height * scaleY).rounded()
    
    cropOffX = cropOffX.rounded()
    cropOffY = cropOffY.rounded()
    
    let renderSize = CGSize(width: renderSizeWidth, height: renderSizeHeight)
    
    
    let transformation = VideoTransformationParameters(targetSize: renderSize,
                                                       crop: CropOff(x: cropOffX, y: cropOffY),
                                                       scale: Scale(x: scaleX, y: scaleY))
    return transformation
  }
}


