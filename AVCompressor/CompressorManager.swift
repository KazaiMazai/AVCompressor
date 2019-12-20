//
//  CompressorManager.swift
//  AVCompressor
//
//  Created by Sergey Kazakov on 29/11/2019.
//  Copyright © 2019 kazaimazai. All rights reserved.
//

import Foundation
import Photos

public class CompressorManager {
  public static let shared = CompressorManager()
  
  public var defaultOptions = EmptyCompressorExportOptions

  var currentDefaultOptions: CompressorExportOptions {
    return [] + defaultOptions
  }
  
  func exportVideoAsset(_ libraryAsset: PHAsset, options: CompressorExportOptions?, complete: @escaping ResultCompleteHandler<URL, Error>) {
    
    exportOriginalVideoAsset(libraryAsset, options: options) { [weak self] in
      switch $0 {
      case .success(let exportedURL):
        self?.performVideoResizeAt(exportedURL, options: options, complete: complete)
      case .failure(let error):
        complete(Result(error: error))
      }
    }
  }

  func resizeVideoFileAt(_ url: URL, options: CompressorExportOptions?, complete: @escaping ResultCompleteHandler<URL, Error>) {
    performVideoResizeAt(url, options: options, complete: complete)
  }
}


//MARK:- CompressorManager private stuff

extension CompressorManager {
  fileprivate func exportOriginalVideoAsset(_ libraryAsset: PHAsset, options: CompressorExportOptions?, complete: @escaping ResultCompleteHandler<URL, Error>) {
    guard libraryAsset.mediaType == .video else {
      complete(Result(error: CompressorError.assetTypeError))
      return
    }
    
    let options = currentDefaultOptions + (options ?? EmptyCompressorExportOptions)
    
    let assetLocalPath = options.resultFilePathURL.appendingPathComponent("\(options.resultFilename)")
    
    let fileManager = FileManager()
    try? fileManager.removeItem(at: assetLocalPath)
    
    let videoRequestOptions: PHVideoRequestOptions = PHVideoRequestOptions()
    videoRequestOptions.version = .current
    
    PHImageManager.default().requestExportSession(forVideo: libraryAsset, options: videoRequestOptions, exportPreset: options.assetExportPreset, resultHandler: { (session, info) in
      
      guard let session = session else { return }
      session.outputURL = assetLocalPath
      session.outputFileType = options.exportFileType
      session.shouldOptimizeForNetworkUse = options.shouldOptimizeForNetworkUse
      
      session.exportAsynchronously {
        switch session.status {
        case .unknown:
          break
        case .waiting:
          break
        case .exporting:
          break
        case .completed:
          complete(Result(value: assetLocalPath))
        case .failed:
          complete(Result(error: CompressorError.videoExportSessionError))
        case .cancelled:
          break
        @unknown default:
          complete(Result(error: CompressorError.videoExportSessionError))
        }
      }
    })
  }
  
  fileprivate func getOrientationForTrack(videoTrack: AVAssetTrack) -> UIImage.Orientation {
    let size = videoTrack.naturalSize
    let txf = videoTrack.preferredTransform
    
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
  
  fileprivate func getTranformationFor(_ videoTrackOrientation: UIImage.Orientation, naturalSize: CGSize, crop: CGPoint, scale: CGPoint) -> CGAffineTransform {
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
    default:
      finalTransform = CGAffineTransform(rotationAngle: 0.0)
    }
    
    return finalTransform
  }
  
  fileprivate func originalSizeForVideoTrackOrinentation(videoTrackOrientation: UIImage.Orientation, naturalSize: CGSize) -> CGSize {
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
  
  fileprivate func performVideoResizeAt(_ url: URL, options: CompressorExportOptions?, complete: @escaping ResultCompleteHandler<URL, Error>) {
    
    let dirUrl = url.deletingLastPathComponent()
    
    let options = currentDefaultOptions + (options ?? EmptyCompressorExportOptions)
    
    let asset = AVAsset(url: url)
    let composition = AVMutableComposition()
    composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
    guard let clipVideoTrack = asset.tracks(withMediaType: .video).first else {
      complete(Result(error: CompressorError.videoResizeError))
      return
    }
    
    let videoComposition = AVMutableVideoComposition()
    videoComposition.frameDuration = options.frameDuraton
    
    let videoTrackOrientation = getOrientationForTrack(videoTrack: clipVideoTrack)
    
    var cropOffX: CGFloat = 0.0
    var cropOffY: CGFloat = 0.0
    
    var scaleX: CGFloat = 1.0
    var scaleY: CGFloat = 1.0
    
     
    let cropPerCent = options.crop
    
    let widthCropScale = (cropPerCent.left + cropPerCent.right) / 100
    let heightCropScale = (cropPerCent.top + cropPerCent.bottom) / 100
  
    let originalSize = originalSizeForVideoTrackOrinentation(videoTrackOrientation: videoTrackOrientation,
                                                             naturalSize: clipVideoTrack.naturalSize)
    
    var targetSize = CGSize(width: (originalSize.width * (1.0 - widthCropScale)),
                            height: (originalSize.height * (1.0 - heightCropScale)))
    
    cropOffX = (originalSize.width * cropPerCent.left / 100.0)
    cropOffY = (originalSize.height * cropPerCent.top / 100.0)
    
    switch options.resizeContentMode {
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
      
      if targetAspectRatio < targetSizeToFillRatio {
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
      
      if targetAspectRatio > targetSizeToFillRatio {
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
      fatalError("not implemented")
    }
    
    
    let renderSizeWidth = (targetSize.width * scaleX).rounded()
    let renderSizeHeight = (targetSize.height * scaleY).rounded()
    
    
    cropOffX = cropOffX.rounded()
    cropOffY = cropOffY.rounded()
    
    videoComposition.renderSize = CGSize(width: renderSizeWidth, height: renderSizeHeight)
    
    
    let targetSizeFilenameSuffix = "\(videoComposition.renderSize.width)x\(videoComposition.renderSize.height)"
    let filename = "\(options.resizedFilenameSuffix)\(url.lastPathComponent)"
    
    let name = options.shouldAddTargetSizeToFilename ?
        "\(targetSizeFilenameSuffix)\(filename)" :
        filename
     
    let outputURL = dirUrl.appendingPathComponent(name)
    try? FileManager.default.removeItem(at: outputURL)
    
    let instruction = AVMutableVideoCompositionInstruction()
    
    let assetDurationRange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
    let timeRange = options.trim.intersection(assetDurationRange)
    
    instruction.timeRange = timeRange
    
    let finalTransform: CGAffineTransform = getTranformationFor(videoTrackOrientation,
                                                                naturalSize: clipVideoTrack.naturalSize,
                                                                crop: CGPoint(x: cropOffX, y: cropOffY),
                                                                scale: CGPoint(x: scaleX, y: scaleY))
    
    let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)
    
    transformer.setTransform(finalTransform, at: CMTime.zero)
    instruction.layerInstructions = [transformer]
    videoComposition.instructions = [instruction]
    
    guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
      complete(Result(error: CompressorError.videoExportSessionError))
      return
    }
    
    exporter.timeRange = timeRange
    exporter.videoComposition = videoComposition
    exporter.outputURL = outputURL
    exporter.outputFileType = options.exportFileType
    
    exporter.exportAsynchronously(completionHandler: {
      switch exporter.status {
      case .unknown:
        break
      case .waiting:
        break
      case .exporting:
        break
      case .completed:
        complete(Result(value: outputURL))
      case .failed:
        complete(Result(error: CompressorError.videoExportSessionError))
      case .cancelled:
        complete(Result(error: CompressorError.videoExportSessionError))
      @unknown default:
        complete(Result(error: CompressorError.videoExportSessionError))
      }
    })
  }
}
