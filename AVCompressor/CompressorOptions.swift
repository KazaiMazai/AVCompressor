//
//  CompressorOptions.swift
//  AVCompressor
//
//  Created by Sergey Kazakov on 29/11/2019.
//  Copyright © 2019 kazaimazai. All rights reserved.
//

import Foundation
import CoreGraphics
import AVKit

public typealias CompressorExportOptions = [CompressorExportOptionsItem]
let EmptyCompressorExportOptions = [CompressorExportOptionsItem]()

public enum CompressorExportOptionsItem {
  case resizeContentMode(ResizeContentMode)
  case crop(Crop)
  case resultFilePath(pathURL: URL)
  case resultFilename(String)
  case exportFileType(AVFileType)
  case assetExportPreset(String)
  case shouldOptimizeForNetworkUse(Bool)
  case resizedFilenameSuffix(String)
  case shouldAddTargetSizeToFilename(Bool)
  case trim(CMTimeRange)
  case framesPerSecond(Int32)
}

public enum ResizeContentMode {
  case aspectFit(CGSize)
  case aspectFill(CGSize)
  case aspectRatioBestFill(AcceptedSizeSettings)
  case none
}

public enum AcceptedSizeSettings {
  case aspect(ratioLimits: Range<CGFloat>, widthLimits: Range<CGFloat>)
  
  var videoMinWidth: CGFloat {
    switch self {
    case .aspect(_, let widthLimits):
      return widthLimits.lowerBound
    }
  }
  
  var videoMaxWidth: CGFloat {
    switch self {
    case .aspect(_, let widthLimits):
      return widthLimits.upperBound
    }
  }
  
  var videoMaxPortraitAspectRatio: CGFloat {
    switch self {
    case .aspect(let ratioLimits, _):
      return ratioLimits.upperBound
    }
  }
  
  var videoMinLandscapeAspectRatio: CGFloat {
    switch self {
    case .aspect(let ratioLimits, _):
      return ratioLimits.lowerBound
    }
  }
}

public struct Crop {
  let top: CGFloat
  let left: CGFloat
  let bottom: CGFloat
  let right: CGFloat
  
  static let zero: Crop = Crop(top: 0, left: 0, bottom: 0, right: 0)
  
}

public enum ResultFilePath {
  case originalFilePath
  case url(URL)
}

public enum ResultFilename {
  case addSuffux(String)
}

public enum AssetExportPreset {
  
}


precedencegroup ItemComparisonPrecedence {
  associativity: none
  higherThan: LogicalConjunctionPrecedence
}

infix operator <== : ItemComparisonPrecedence

// This operator returns true if two `CompressorExportOptions` enum is the same, without considering the associated values.
func <== (lhs: CompressorExportOptionsItem, rhs: CompressorExportOptionsItem) -> Bool {
  switch (lhs, rhs) {
  case (.resizeContentMode, .resizeContentMode): return true
  case (.crop, .crop): return true
  case (.resultFilePath, .resultFilePath): return true
  default: return false
  }
}

extension Collection where Iterator.Element == CompressorExportOptionsItem {
  func lastMatchIgnoringAssociatedValue(_ target: Iterator.Element) -> Iterator.Element? {
    return reversed().first { $0 <== target }
  }
  
  func removeAllMatchesIgnoringAssociatedValue(_ target: Iterator.Element) -> [Iterator.Element] {
    return filter { !($0 <== target) }
  }
}

public extension Collection where Iterator.Element == CompressorExportOptionsItem {
  var resizeContentMode: ResizeContentMode {
    guard let resizeContentMode = lastMatchIgnoringAssociatedValue(.resizeContentMode(.none)),
      case .resizeContentMode(let resize) = resizeContentMode
    else {
      return .none
    }
    
    return resize
  }
  
  var crop: Crop {
    guard let cropping = lastMatchIgnoringAssociatedValue(.crop(.zero)),
      case .crop(let cropValue) = cropping
      else {
        return .zero
    }
    
    return cropValue
  }
  
  var assetExportPreset: String {
    guard let assetExportPreset = lastMatchIgnoringAssociatedValue(.assetExportPreset("")),
      case .assetExportPreset(let preset) = assetExportPreset
      else {
        return AVAssetExportPresetHighestQuality
    }
    
    return preset
  }
  
  var resultFilePathURL: URL {
    guard let resultFileInfo = lastMatchIgnoringAssociatedValue(.resultFilePath(pathURL: URL(fileURLWithPath: ""))),
      case .resultFilePath(let filePathURL) = resultFileInfo
      else {
        return URL(fileURLWithPath: NSTemporaryDirectory())
    }
    
    return filePathURL
  }
  
  var resultFilename: String {
    guard let filenameInfo = lastMatchIgnoringAssociatedValue(.resultFilename("")),
      case .resultFilename(let filename) = filenameInfo
      else {
        return UUID().uuidString
    }
    
    return filename
  }
  
  var exportFileType: AVFileType {
    guard let fileTypeInfo = lastMatchIgnoringAssociatedValue(.exportFileType(AVFileType.mp4)),
      case .exportFileType(let filetype) = fileTypeInfo
    else {
      return AVFileType.mp4
    }
    
    return filetype
  }
  
  var shouldOptimizeForNetworkUse: Bool {
    guard let shouldOptimizeForNetworkUseInfo = lastMatchIgnoringAssociatedValue(.shouldOptimizeForNetworkUse(true)),
      case .shouldOptimizeForNetworkUse(let boolValue) = shouldOptimizeForNetworkUseInfo
      else {
        return true
    }
    
    return boolValue
  }
  
  var resizedFilenameSuffix: String {
    guard let filenameInfo = lastMatchIgnoringAssociatedValue(.resizedFilenameSuffix("")),
      case .resizedFilenameSuffix(let suffix) = filenameInfo
      else {
        return "_resized"
    }
    
    return suffix
  }
  
  var shouldAddTargetSizeToFilename: Bool {
    guard let shouldAddTargetSizeToFilenameInfo = lastMatchIgnoringAssociatedValue(.shouldAddTargetSizeToFilename(true)),
      case .shouldAddTargetSizeToFilename(let boolValue) = shouldAddTargetSizeToFilenameInfo
      else {
        return true
    }
    
    return boolValue
  }
  
  var trim: CMTimeRange {
    guard let trimOptions = lastMatchIgnoringAssociatedValue(.trim(CMTimeRange(start: CMTime.zero, duration: CMTime.zero))),
      case .trim(let trimTimeRange) = trimOptions
    else {
        let duration = Double.infinity
        let infiniteDurationTime = CMTime(seconds: duration, preferredTimescale: preferredTimescale)
        
        return CMTimeRange(start: CMTime.zero, duration: infiniteDurationTime)
    }
    
    return trimTimeRange
  }
  
  var frameDuraton: CMTime {
    return CMTime(seconds: 1, preferredTimescale: preferredTimescale)
  }
  
  var preferredTimescale: CMTimeScale {
    return CMTimeScale(framesPerSecond)
  }
  
  var framesPerSecond: Int32 {
    guard let framesPerSecondOption = lastMatchIgnoringAssociatedValue(.framesPerSecond(30)),
      case .framesPerSecond(let fps) = framesPerSecondOption
      else {
        return 30
    }
    
    return fps
  }
}
