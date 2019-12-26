//
//  VideoTransformationComposerTests.swift
//  AVCompressorTests
//
//  Created by Sergey Kazakov on 24/12/2019.
//  Copyright © 2019 kazaimazai. All rights reserved.
//

import XCTest
@testable import AVCompressor


class VideoTransformationComposerAspectFillOnlyResizeTests: ParametrizedTestCase {
  func aspectFill(originalSize: CGSize, targetSize: CGSize) {
    
    let resizeContentMode = ResizeContentMode.aspectFill(targetSize)
    
    let transformationComposer = VideoTransformationComposer(originalSize: originalSize,
                                                             cropPerCent: Crop.zero,
                                                             resizeContentMode: resizeContentMode)
    
     let transformationParameters = transformationComposer.transformationParameters
    
    let inputWidth = originalSize.width
    let inputHeight = originalSize.height
    
    let resultOffsetX = transformationParameters.crop.x
    let resultOffsetY = transformationParameters.crop.y
    
    let resultRemainedWidth = inputWidth - resultOffsetX - (targetSize.width / transformationParameters.scale.x)
    let resultRemainedHeight = inputHeight - resultOffsetY - (targetSize.height / transformationParameters.scale.y)
    
    let totalCropX = resultOffsetX + resultRemainedWidth
    let totalCropY = resultOffsetY + resultRemainedHeight
    
     
    XCTAssertEqual(transformationParameters.targetSize, targetSize)
    
    //cropped video should be centered
    XCTAssertLessThanOrEqual(abs(resultOffsetX - resultRemainedWidth), 1)
    XCTAssertLessThanOrEqual(abs(resultOffsetY - resultRemainedHeight), 1)
    
    //at least any of cropX, cropY should be zero
    XCTAssertEqual(totalCropX * totalCropY, 0)
    
    
  }
  
  override class func _qck_testMethodSelectors() -> [_QuickSelectorWrapper] {
    
    //generate parameters
    
    let sizes = [50, 100, 200]
    var testsParameters: [(originalSize: CGSize, targetSize: CGSize)] = []
    var originalSizes: [CGSize] = []
    var targetSizes: [CGSize] = []
    
    for width in sizes {
      for height in sizes {
        originalSizes.append(CGSize(width: width, height: height))
        targetSizes.append(CGSize(width: width, height: height))
      }
    }
    
    for originalSize in originalSizes {
      for targetSize in targetSizes {
        testsParameters.append((originalSize: originalSize, targetSize: targetSize))
      }
    }
    
    return testsParameters.map { parameter in
      /// first we wrap our test method in block that takes TestCase instance
      let block: @convention(block) (Self) -> Void = { $0.aspectFill(originalSize: parameter.originalSize, targetSize: parameter.targetSize) }
      /// with help of ObjC runtime we add new test method to class
      let implementation = imp_implementationWithBlock(block)
      let selectorName = "test_\(parameter)"
      let selector = NSSelectorFromString(selectorName)
      class_addMethod(self, selector, implementation, "v@:")
      /// and return wrapped selector on new created method
      return _QuickSelectorWrapper(selector: selector)
    }
  }
}


class VideoTransformationComposerAspectFillOnlyCropTests: ParametrizedTestCase {
  func aspectFill(originalSize: CGSize, crop: Crop) {
    
    //only crop, no additional resize to fill occur
    let targetWidth = (originalSize.width * (1.0 - (crop.left + crop.right) / 100.0)).rounded()
    let targetHeight = (originalSize.height * (1.0 - (crop.top + crop.bottom) / 100.0)).rounded()
    
    let targetSize = CGSize(width: targetWidth,
                            height: targetHeight)
    
    let resizeContentMode = ResizeContentMode.aspectFill(targetSize)
    
    let transformationComposer = VideoTransformationComposer(originalSize: originalSize,
                                                             cropPerCent: crop,
                                                             resizeContentMode: resizeContentMode)
    
    
    let transformationParameters = transformationComposer.transformationParameters
    
    let inputWidth = originalSize.width
    let inputHeight = originalSize.height
    
    let resultOffsetX = transformationParameters.crop.x
    let resultOffsetY = transformationParameters.crop.y
    
    let resultRemainedWidth = inputWidth - resultOffsetX - (targetSize.width / transformationParameters.scale.x)
    let resultRemainedHeight = inputHeight - resultOffsetY - (targetSize.height / transformationParameters.scale.y)
    
    XCTAssertLessThanOrEqual(abs(resultOffsetX - (crop.left * originalSize.width / 100.0)).rounded(), 1)
    XCTAssertLessThanOrEqual(abs(resultOffsetY - (crop.top * originalSize.height / 100.0)).rounded(), 1)
    XCTAssertLessThanOrEqual(abs(resultRemainedWidth - (crop.right * originalSize.width / 100.0)).rounded(), 1)
    XCTAssertLessThanOrEqual(abs(resultRemainedHeight - (crop.bottom * originalSize.height / 100.0)).rounded(), 1)
    
    XCTAssertEqual(transformationParameters.targetSize, targetSize)
  }
  
  override class func _qck_testMethodSelectors() -> [_QuickSelectorWrapper] {
    
    //generate parameters
    
    let sizes: [CGFloat] = [50, 100, 200]
    let cropAmounts: [CGFloat] = [5, 0]
    
    var testsParameters: [(originalSize: CGSize, crop: Crop)] = []
    var originalSizes: [CGSize] = []
    
    var crops: [Crop] = []
    
    for width in sizes {
      for height in sizes {
        originalSizes.append(CGSize(width: width, height: height))
      }
    }
    
    for top in cropAmounts {
      for bottom in cropAmounts {
        for left in cropAmounts {
          for right in cropAmounts {
            let crop = Crop(top: top, left: left, bottom: bottom, right: right)
            crops.append(crop)
          }
        }
      }
    }
    
    for originalSize in originalSizes {
      for crop in crops {
        testsParameters.append((originalSize: originalSize, crop: crop))
      }
    }
    
    return testsParameters.map { parameter in
      /// first we wrap our test method in block that takes TestCase instance
      let block: @convention(block) (Self) -> Void = { $0.aspectFill(originalSize: parameter.originalSize, crop: parameter.crop) }
      /// with help of ObjC runtime we add new test method to class
      let implementation = imp_implementationWithBlock(block)
      
      let selectorName = "test_\(parameter)"
      let selector = NSSelectorFromString(selectorName)
      class_addMethod(self, selector, implementation, "v@:")
      /// and return wrapped selector on new created method
      return _QuickSelectorWrapper(selector: selector)
    }
  }
}

class VideoTransformationComposerAspectFillResizeWithCropTests: ParametrizedTestCase {
  func aspectFill(originalSize: CGSize, targetSize: CGSize, crop: Crop) {
    //step1 - perform crop only transformation
    
    let cropTargetWidth = (originalSize.width * (1.0 - (crop.left + crop.right) / 100.0)).rounded()
    let cropTargetHeight = (originalSize.height * (1.0 - (crop.top + crop.bottom) / 100.0)).rounded()
    
    let cropTargetSize = CGSize(width: cropTargetWidth,
                                height: cropTargetHeight)
    
    let cropResizeContentMode = ResizeContentMode.aspectFill(cropTargetSize)
    
    let cropTransformationComposer = VideoTransformationComposer(originalSize: originalSize,
                                                                 cropPerCent: crop,
                                                                 resizeContentMode: cropResizeContentMode)
    
    let cropTransformationParameters = cropTransformationComposer.transformationParameters
    
    let originalSizeInputWidthToCrop = originalSize.width
    let originalSizeInputHeightToCrop = originalSize.height
    
    let cropResultOffsetX = cropTransformationParameters.crop.x
    let cropResultOffsetY = cropTransformationParameters.crop.y
    
    let cropResultRemainedWidth = originalSizeInputWidthToCrop - cropResultOffsetX - (cropTargetSize.width / cropTransformationParameters.scale.x)
    let cropResultRemainedHeight = originalSizeInputHeightToCrop - cropResultOffsetY - (cropTargetSize.height / cropTransformationParameters.scale.y)
    
    
    XCTAssertLessThanOrEqual(abs(cropResultOffsetX - (crop.left * originalSize.width / 100.0)).rounded(), 1)
    XCTAssertLessThanOrEqual(abs(cropResultOffsetY - (crop.top * originalSize.height / 100.0)).rounded(), 1)
    XCTAssertLessThanOrEqual(abs(cropResultRemainedWidth - (crop.right * originalSize.width / 100.0)).rounded(), 1)
    XCTAssertLessThanOrEqual(abs(cropResultRemainedHeight - (crop.bottom * originalSize.height / 100.0)).rounded(), 1)
    
    XCTAssertEqual(cropTransformationParameters.targetSize, cropTargetSize)
    
    
    
    //step2 - resize cropped result
    
    let croppedResultResizeContentMode = ResizeContentMode.aspectFill(targetSize)
    
    let croppedResultTransformationComposer = VideoTransformationComposer(originalSize: cropTargetSize,
                                                                          cropPerCent: Crop.zero,
                                                                          resizeContentMode: croppedResultResizeContentMode)
    
    let croppedResultTransformationParameters = croppedResultTransformationComposer.transformationParameters
    
    let inputWidth = cropTargetSize.width
    let inputHeight = cropTargetSize.height
    
    let croppedResultOffsetX = croppedResultTransformationParameters.crop.x
    let croppedResultOffsetY = croppedResultTransformationParameters.crop.y
    
    let croppedResultRemainedWidth = inputWidth - croppedResultOffsetX - (targetSize.width / croppedResultTransformationParameters.scale.x)
    let croppedResultRemainedHeight = inputHeight - croppedResultOffsetY - (targetSize.height / croppedResultTransformationParameters.scale.y)
    
    
    
    XCTAssertEqual(croppedResultTransformationParameters.targetSize, targetSize)
  
    //at least any of cropX, cropY should be zero, because aspect fill resize should be centered
    XCTAssertEqual((croppedResultOffsetX + croppedResultRemainedWidth) * (croppedResultOffsetY + croppedResultRemainedHeight), 0)
    
    
    //step3 -  perform crop and resize at once
    
    let resizeContentMode = ResizeContentMode.aspectFill(targetSize)
    
    let transformationComposer = VideoTransformationComposer(originalSize: originalSize,
                                                             cropPerCent: crop,
                                                             resizeContentMode: resizeContentMode)
    
    let transformationParameters = transformationComposer.transformationParameters
    
    let originalSizeInputWidth = originalSize.width
    let originalSizeInputHeight = originalSize.height
    
    let resultOffsetX = transformationParameters.crop.x
    let resultOffsetY = transformationParameters.crop.y
    
    let resultRemainedWidth = originalSizeInputWidth - resultOffsetX - (targetSize.width / transformationParameters.scale.x)
    let resultRemainedHeight = originalSizeInputHeight - resultOffsetY - (targetSize.height / transformationParameters.scale.y)
    
    XCTAssertEqual(transformationParameters.targetSize, targetSize)
    
    //compare step1 + step2 with step3
    XCTAssertLessThanOrEqual(abs(resultOffsetX - (cropResultOffsetX + croppedResultOffsetX)), 1)
    XCTAssertLessThanOrEqual(abs(resultOffsetY - (cropResultOffsetY + croppedResultOffsetY)), 1)
    XCTAssertLessThanOrEqual(abs(resultRemainedWidth - (croppedResultRemainedWidth + cropResultRemainedWidth)).rounded(),1)
    XCTAssertLessThanOrEqual(abs(resultRemainedHeight - (croppedResultRemainedHeight + cropResultRemainedHeight)).rounded(), 1)
  }
  
  override class func _qck_testMethodSelectors() -> [_QuickSelectorWrapper] {
    
    //generate parameters
    
    let sizes: [CGFloat] = [50, 100, 200]
    let cropAmounts: [CGFloat] = [5, 0]
    
    var testsParameters: [(originalSize: CGSize, targetSize: CGSize, crop: Crop)] = []
    var originalSizes: [CGSize] = []
    var targetSizes: [CGSize] = []
    var crops: [Crop] = []
    
    for width in sizes {
      for height in sizes {
        originalSizes.append(CGSize(width: width, height: height))
        targetSizes.append(CGSize(width: width, height: height))
      }
    }
    
    for top in cropAmounts {
      for bottom in cropAmounts {
        for left in cropAmounts {
          for right in cropAmounts {
            let crop = Crop(top: top, left: left, bottom: bottom, right: right)
            crops.append(crop)
          }
        }
      }
    }
    
    for originalSize in originalSizes {
      for targetSize in targetSizes {
        for crop in crops {
          testsParameters.append((originalSize: originalSize, targetSize: targetSize, crop: crop))
        }
      }
    }
    
    return testsParameters.map { parameter in
      /// first we wrap our test method in block that takes TestCase instance
      let block: @convention(block) (Self) -> Void = { $0.aspectFill(originalSize: parameter.originalSize, targetSize: parameter.targetSize, crop: parameter.crop) }
      /// with help of ObjC runtime we add new test method to class
      let implementation = imp_implementationWithBlock(block)
      
      let selectorName = "test_\(parameter)"
      let selector = NSSelectorFromString(selectorName)
      class_addMethod(self, selector, implementation, "v@:")
      /// and return wrapped selector on new created method
      return _QuickSelectorWrapper(selector: selector)
    }
  }
}
