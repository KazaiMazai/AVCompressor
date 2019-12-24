//
//  VideoTransformationComposerTests.swift
//  AVCompressorTests
//
//  Created by Sergey Kazakov on 24/12/2019.
//  Copyright © 2019 kazaimazai. All rights reserved.
//

import XCTest
@testable import AVCompressor


class VideoTransformationComposerAspectFillTests: ParametrizedTestCase {
  func aspectFill(originalSize: CGSize, targetSize: CGSize) {
    //given
    let resizeContentMode = ResizeContentMode.aspectFill(targetSize)
    
    let transformationComposer = VideoTransformationComposer(originalSize: originalSize,
                                                             cropPerCent: Crop.zero,
                                                             resizeContentMode: resizeContentMode)
    
    //when
    let transformationParameters = transformationComposer.transformationParameters
    
    
    //then
    
    XCTAssertEqual(transformationParameters.targetSize, targetSize)
    XCTAssertEqual((originalSize.width -  (2 * transformationParameters.crop.x)) * transformationParameters.scale.x, targetSize.width)
    XCTAssertEqual((originalSize.height - (2 * transformationParameters.crop.y)) * transformationParameters.scale.y, targetSize.height)
  }
  
  override class func _qck_testMethodSelectors() -> [_QuickSelectorWrapper] {
    /// For this example we create 3 runtime tests "test_a", "test_b" and "test_c" with corresponding parameter
    
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
      let block: @convention(block) (VideoTransformationComposerAspectFillTests) -> Void = { $0.aspectFill(originalSize: parameter.originalSize, targetSize: parameter.targetSize) }
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
