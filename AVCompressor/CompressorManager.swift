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
 
  fileprivate func performVideoResizeAt(_ url: URL, options: CompressorExportOptions?, complete: @escaping ResultCompleteHandler<URL, Error>) {
    
    let dirUrl = url.deletingLastPathComponent()
    
    let options = currentDefaultOptions + (options ?? EmptyCompressorExportOptions)
    
    let asset = AVAsset(url: url)
    let composition = AVMutableComposition()
    composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
    guard let videoTrack = asset.tracks(withMediaType: .video).first else {
      complete(Result(error: CompressorError.videoResizeError))
      return
    }
    
    let videoComposition = AVMutableVideoComposition()
    videoComposition.frameDuration = options.frameDuraton
    
    let originalSize = videoTrack.originalSizeForOrientation
    
    let composer = VideoTransformationComposer(originalSize: originalSize,
                                               cropPerCent: options.crop,
                                               resizeContentMode: options.resizeContentMode)
    
    let videoAffineTransform = videoTrack.affineTransformFor(crop: composer.transformationParameters.crop,
                                                           scale: composer.transformationParameters.scale)
     

    videoComposition.renderSize = composer.transformationParameters.targetSize
    
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
    
    
    let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    
    transformer.setTransform(videoAffineTransform, at: CMTime.zero)
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
