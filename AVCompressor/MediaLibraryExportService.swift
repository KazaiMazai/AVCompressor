//
//  MediaLibraryExportService.swift
//  Pibble
//
//  Created by Kazakov Sergey on 18.08.2018.
//  Copyright © 2018 com.kazai. All rights reserved.
//

import Foundation
import Photos
import AVKit

enum ExportedLibraryAsset {
  case photo(URL, original: URL?)
  case rawVideo(URL, requiredCrop: UIEdgeInsets)
  
  var fileURL: URL {
    switch self {
    case .photo(let url, _):
      return url
    case .rawVideo(let url, _):
      return url
    }
  }
  
  var additionalFileUrl: URL? {
    switch self {
    case .photo(_, let original):
      return original
    case .rawVideo:
      return nil
    }
  }
  
  var crop: UIEdgeInsets {
    switch self {
    case .photo(_):
      return UIEdgeInsets.zero
    case .rawVideo(_, let crop):
      return crop
    }
  }
  
  init(rawVideoURL: URL) {
    self = .rawVideo(rawVideoURL, requiredCrop: UIEdgeInsets.zero)
  }
  
  init(rawVideoURL: URL, withCropRequired: UIEdgeInsets) {
    self = .rawVideo(rawVideoURL, requiredCrop: withCropRequired)
  }
  
  init(exportedPhotoURL: URL) {
    self = .photo(exportedPhotoURL, original: nil)
  }
  
  init(exportedPhotoURL: URL, originalPhoto: URL) {
    self = .photo(exportedPhotoURL, original: originalPhoto)
  }
}


enum MediaProcessingPipelineError: LocalizedError {
  case uploadError(LocalizedError)
  case mediaLibraryExportError(Error)
  case photoExportError(Error)
  case photoSaveError
  case videoExportSessionError
  case assetTypeError
  case noAssetResourceError
  case unSupportedAssetTypeError
  
  case photoResizeError
  case operationInputNotFound
  case underlyingError(LocalizedError)
  case videoResizeError
  case couldNotObtainMediaToken
  
  var description: String {
    switch self {
    case .uploadError(let err):
      return err.errorDescription ?? ""
    case .underlyingError(let err):
      return err.errorDescription ?? ""
    case .operationInputNotFound:
      return ErrorStrings.MediaProcessingPipelineError.operationInputNotFound.localize()
    case .mediaLibraryExportError(let err):
      return ErrorStrings.MediaProcessingPipelineError.mediaLibraryExportError.localize(value: err.localizedDescription)
    case .photoExportError(let err):
      return ErrorStrings.MediaProcessingPipelineError.photoExportError.localize(value: err.localizedDescription)
    case .photoResizeError:
      return ErrorStrings.MediaProcessingPipelineError.photoResizeError.localize()
    case .videoExportSessionError:
      return ErrorStrings.MediaProcessingPipelineError.videoExportSessionError.localize()
    case .assetTypeError:
      return ErrorStrings.MediaProcessingPipelineError.assetTypeError.localize()
    case .noAssetResourceError:
      return ErrorStrings.MediaProcessingPipelineError.noAssetResourceError.localize()
    case .unSupportedAssetTypeError:
      return ErrorStrings.MediaProcessingPipelineError.unSupportedAssetTypeError.localize()
    case .videoResizeError:
      return ErrorStrings.MediaProcessingPipelineError.videoResizeError.localize()
    case .couldNotObtainMediaToken:
      return ErrorStrings.MediaProcessingPipelineError.couldNotObtainMediaToken.localize()
    case .photoSaveError:
      return ErrorStrings.MediaProcessingPipelineError.photoSaveError.localize()
    }
  }
}

enum ErrorStrings {
  enum MediaProcessingPipelineError: String {
    case operationInputNotFound = "Operation input not found"
    case mediaLibraryExportError = "Media library export error: %"
    case photoExportError = "Image export error: %"
    case photoResizeError = "Image resize error"
    case videoExportSessionError = "Video export session error"
    case assetTypeError = "Wrong asset type"
    case noAssetResourceError = "No asset resource found"
    case unSupportedAssetTypeError = "Asset type is not supported"
    case videoResizeError = "Video resize error"
    case couldNotObtainMediaToken = "Could not obtain uuid"
    case photoSaveError = "Could not save image"
    
    func localize() -> String {
      return rawValue
    }
    
    func localize(value: String) -> String {
      return rawValue
    }
  }
}


fileprivate struct ImageExportSettings {
  let imageMaxWidth: CGFloat
  let imageMinWidth: CGFloat
  let imageMaxHeight: CGFloat
  let imageMinHeight: CGFloat
  
  let imageMinLandscapeAspectRatio: CGFloat // height/width
  let imageMaxPortraitAspectRatio: CGFloat    // height/width
  
  
  init(settings: MediaExportSettings) {
    imageMaxWidth = settings.imageMaxWidth
    imageMinWidth = settings.imageMinWidth
    imageMaxHeight = settings.imageMaxHeight
    imageMinHeight = settings.imageMinHeight
    
    imageMinLandscapeAspectRatio = settings.imageMinLandscapeAspectRatio
    imageMaxPortraitAspectRatio = settings.imageMaxPortraitAspectRatio
  }
  
  init(userPicSettings from: MediaExportSettings) {
    imageMaxWidth = from.userpicImageSize.width
    imageMinWidth = from.userpicImageSize.width
    imageMaxHeight = from.userpicImageSize.height
    imageMinHeight = from.userpicImageSize.height
    
    imageMinLandscapeAspectRatio = from.userPicImageMinLandscapeAspectRatio
    imageMaxPortraitAspectRatio = from.userPicImageMaxPortraitAspectRatio
  }
  
  init(originalSizeUsingSettingsRatio: MediaExportSettings) {
    imageMaxWidth = 8000
    imageMinWidth = originalSizeUsingSettingsRatio.imageMinWidth
    imageMaxHeight = 8000
    imageMinHeight = originalSizeUsingSettingsRatio.imageMinHeight
    
    imageMinLandscapeAspectRatio = originalSizeUsingSettingsRatio.imageMinLandscapeAspectRatio
    imageMaxPortraitAspectRatio = originalSizeUsingSettingsRatio.imageMaxPortraitAspectRatio
  }
}

class MediaLibraryExportService: MediaLibraryExportServiceProtocol {
  let settings: MediaExportSettings
  let videoCaptureSettings: CameraCaptureSettings
  
  init(settings: MediaExportSettings, videoCaptureSettings: CameraCaptureSettings) {
    self.settings = settings
    self.videoCaptureSettings = videoCaptureSettings
  }
  
  func cropImageWithCurrentExportSettingsRatio(_ image: UIImage, cropPerCent: UIEdgeInsets) -> UIImage? {
    let imageExportSettings = ImageExportSettings(originalSizeUsingSettingsRatio: settings)
    return image.resizedImageFor(imageExportSettings, cropPerCent: cropPerCent)
  }
  
  func resizeImageWithCurrentExportSettings(image: UIImage, cropPerCent: UIEdgeInsets) -> UIImage? {
    let imageExportSettings = ImageExportSettings(settings: settings)
    return image.resizedImageFor(imageExportSettings, cropPerCent: cropPerCent)
  }
  
  func resizeImageWithCurrentExportSettings(image: UIImage, cropPerCent: UIEdgeInsets, complete: @escaping (UIImage?) -> Void) {
    DispatchQueue.global(qos: .utility).async { [weak self] in
      let image = self?.resizeImageWithCurrentExportSettings(image: image, cropPerCent: cropPerCent)
      DispatchQueue.main.async {
        complete(image)
      }
    }
  }
  
  func saveAsJPGWithCurrentExportSettings(image: UIImage, name: String) -> URL? {
    let logoUrl = try? image.saveAsJPG(name, compression: settings.imageCompresion)
    return logoUrl
  }
  
  func saveAsJPGWithoutComression(image: UIImage, name: String) -> URL? {
    let logoUrl = try? image.saveAsJPG(name, compression: settings.imageOriginalCompresion)
    return logoUrl
  }
  
  func saveAsJPGWithCurrentExportSettings(image: UIImage, name: String, complete: @escaping (URL?) -> Void) {
    DispatchQueue.global(qos: .utility).async { [weak self] in
      let url = self?.saveAsJPGWithCurrentExportSettings(image: image, name: name)
      DispatchQueue.main.async {
         complete(url)
      }
    }
  }
  
  func exportAsset(_ mPhasset: LibraryAsset, complete: @escaping ResultCompleteHandler<ExportedLibraryAsset, MediaProcessingPipelineError>) {
    exportAsset(mPhasset, settings: settings, complete: complete)
  }
  
  func exportAssetForWallPurpose(_ mPhasset: LibraryAsset, complete: @escaping (Result<URL, MediaProcessingPipelineError>) -> ()) {
    guard let resource = PHAssetResource.assetResources(for: mPhasset.underlyingAsset).first else {
      complete(Result(error: MediaProcessingPipelineError.noAssetResourceError))
      return
    }
    
    let name = "\(UUID().uuidString)_\(resource.originalFilename)_EXPORTED"
    exportImageAssetForWall(mPhasset, name: name, settings: settings, complete: complete)
  }
  
  
  func exportAssetForUserpicPurpose(_ mPhasset: LibraryAsset, complete: @escaping ResultCompleteHandler<URL, MediaProcessingPipelineError>) {
  
    guard let resource = PHAssetResource.assetResources(for: mPhasset.underlyingAsset).first else {
      complete(Result(error: MediaProcessingPipelineError.noAssetResourceError))
      return
    }
    
    let name = "\(UUID().uuidString)_\(resource.originalFilename)_EXPORTED"
    exportImageAssetForUserpic(mPhasset, name: name, settings: settings, complete: complete)
  }
  
  func resizeVideoAt(_ url: URL, cropPerCent: UIEdgeInsets, complete: @escaping ResultCompleteHandler<URL, MediaProcessingPipelineError>) {
    let dirUrl = url.deletingLastPathComponent()
    
    let duration = settings.cameraCaptureSettings.maxDuration
    
    let asset = AVAsset(url: url)
    let composition = AVMutableComposition()
    composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
    
    guard let clipVideoTrack = asset.tracks(withMediaType: .video).first else {
      complete(Result(error: MediaProcessingPipelineError.videoResizeError))
      return
    }
    
    let videoComposition = AVMutableVideoComposition()
    videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
    videoComposition.renderSize = settings.videoTargetSize
    
    let videoMinDimension = min(clipVideoTrack.naturalSize.width, clipVideoTrack.naturalSize.height)
    let videoMaxDimension = max(clipVideoTrack.naturalSize.width, clipVideoTrack.naturalSize.height)
    let videoTrackOrientation = getOrientationForTrack(videoTrack: clipVideoTrack)
    
    var cropOffX: CGFloat = 0.0
    var cropOffY: CGFloat = 0.0
    
    var scaleX: CGFloat = 1.0
    var scaleY: CGFloat = 1.0
    
    let widthCropScale = (cropPerCent.left + cropPerCent.right) / 100
    let heightCropScale = (cropPerCent.top + cropPerCent.bottom) / 100
    
    var originalSize = CGSize.zero
    switch videoTrackOrientation {
    case .up, .down:
      originalSize = CGSize(width: videoMinDimension, height: videoMaxDimension)
    case .left, .right:
      originalSize = clipVideoTrack.naturalSize
    default:
      break
    }
    var targetSize = CGSize(width: (originalSize.width * (1.0 - widthCropScale)),
                                         height: (originalSize.height * (1.0 - heightCropScale)))
    
    cropOffX = (originalSize.width * cropPerCent.left / 100.0)
    cropOffY = (originalSize.height * cropPerCent.top / 100.0)
    
    var targetAspectRatio = targetSize.height / targetSize.width
    if targetAspectRatio > settings.videoMaxPortraitAspectRatio {
      let targetHeight = (targetSize.width * settings.videoMaxPortraitAspectRatio)
      cropOffY += ((targetSize.height - targetHeight) / 2)
      targetAspectRatio = settings.videoMaxPortraitAspectRatio
      targetSize = CGSize(width: targetSize.width, height: targetHeight)
    }
    
    if targetAspectRatio < settings.videoMinLandscapeAspectRatio {
      let targetWidth = targetSize.height / settings.videoMinLandscapeAspectRatio
      cropOffX = ((targetSize.width - targetWidth) / 2)
      targetAspectRatio = settings.videoMinLandscapeAspectRatio
      targetSize = CGSize(width: targetWidth, height: targetSize.height)
    }
    
    if targetSize.width < settings.videoMinSizes.width {
      scaleX = settings.videoMinSizes.width  / targetSize.width
      scaleY = settings.videoMinSizes.width  / targetSize.width
    }
    
    if targetSize.width > settings.videoMaxSizes.width {
      scaleX = settings.videoMaxSizes.width  / targetSize.width
      scaleY = settings.videoMaxSizes.width  / targetSize.width
    }
    
    let renderSizeWidth = (targetSize.width * scaleX).rounded()
    let renderSizeHeight = (targetSize.height * scaleY).rounded()
    
    videoComposition.renderSize = CGSize(width: renderSizeWidth, height: renderSizeHeight)
    
    cropOffX = cropOffX.rounded()
    cropOffY = cropOffY.rounded()

    let name = "\(videoComposition.renderSize.width)x\(videoComposition.renderSize.height)_RESIZED_\(url.lastPathComponent)"
    let outputURL = dirUrl.appendingPathComponent(name)
    try? FileManager.default.removeItem(at: outputURL)
    
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: duration)
    let t3 = CGAffineTransform(scaleX: scaleX, y: scaleY)
    
    let finalTransform: CGAffineTransform
    switch videoTrackOrientation {
    case .up:
      let t1 = CGAffineTransform(translationX: clipVideoTrack.naturalSize.height - cropOffX, y: 0.0 - cropOffY)
      let t2 = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
      finalTransform = (t2).concatenating(t1).concatenating(t3)
    case .down:
      let t1 = CGAffineTransform(translationX: 0 - cropOffX, y: clipVideoTrack.naturalSize.width - cropOffY) // not fixed width is the real height in upside down
      let t2 = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
      finalTransform = (t2).concatenating(t1).concatenating(t3)
    case .left:
      let t1 = CGAffineTransform(translationX: clipVideoTrack.naturalSize.width - cropOffX, y: clipVideoTrack.naturalSize.height - cropOffY)
      let t2 = CGAffineTransform(rotationAngle: CGFloat.pi)
      finalTransform = (t2).concatenating(t1).concatenating(t3)
    case .right:
      let t1 = CGAffineTransform(translationX: 0 - cropOffX, y: 0 - cropOffY );
      let t2 = CGAffineTransform(rotationAngle: 0.0)
      finalTransform = (t2).concatenating(t1).concatenating(t3)
    default:
      finalTransform = CGAffineTransform(rotationAngle: 0.0)
    }
    
    let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)
    
    transformer.setTransform(finalTransform, at: CMTime.zero)
    instruction.layerInstructions = [transformer]
    videoComposition.instructions = [instruction]
    
    guard let exporter = AVAssetExportSession(asset: asset, presetName: settings.videoTargetExportPreset) else {
      complete(Result(error: MediaProcessingPipelineError.videoExportSessionError))
      return
    }
    
    exporter.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: duration)
    exporter.videoComposition = videoComposition
    exporter.outputURL = outputURL
    exporter.outputFileType = settings.outputFileType
    
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
        complete(Result(error: MediaProcessingPipelineError.videoExportSessionError))
      case .cancelled:
        complete(Result(error: MediaProcessingPipelineError.videoExportSessionError))
      }
    })
  }
  /*
  func resizeVideoWithoutCrop(_ url: URL, complete: @escaping ResultCompleteHandler<URL, MediaProcessingPipelineError>) {
    let dirUrl = url.deletingLastPathComponent()
    
  
    let asset = AVAsset(url: url)
    
    let duration = settings.cameraCaptureSettings.maxDuration
    
    let composition = AVMutableComposition()
    composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
    
    guard let clipVideoTrack = asset.tracks(withMediaType: .video).first else {
      complete(Result(error: MediaProcessingPipelineError.videoResizeError))
      return
    }
    
    let videoComposition = AVMutableVideoComposition()
    videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
    videoComposition.renderSize = settings.videoTargetSize
    
    let videoMinDimension = min(clipVideoTrack.naturalSize.width, clipVideoTrack.naturalSize.height)
    let videoMaxDimension = max(clipVideoTrack.naturalSize.width, clipVideoTrack.naturalSize.height)
    let videoTrackOrientation = getOrientationForTrack(videoTrack: clipVideoTrack)
    
    var cropOffX: CGFloat = 0.0
    var cropOffY: CGFloat = 0.0
    
    var scaleX: CGFloat = 1.0
    var scaleY: CGFloat = 1.0
    
    switch videoTrackOrientation {
    case .up, .down:
      let originalSize = CGSize(width: videoMinDimension, height: videoMaxDimension)
      videoComposition.renderSize = originalSize
      
      let originalAspectRatio = originalSize.height / originalSize.width
      
      if originalSize.width < settings.videoMinSizes.width {
        scaleX = settings.videoMinSizes.width  / originalSize.width
        scaleY = settings.videoMinSizes.width  / originalSize.width
      }
      
      let sizeAfterScaleToMinSize = CGSize(width: originalSize.width * scaleX, height: originalSize.height * scaleY)
      
      if sizeAfterScaleToMinSize.width > settings.videoMaxSizes.width {
        let scaleToFitWidth = settings.videoMaxSizes.width  / sizeAfterScaleToMinSize.width
        scaleX = scaleX * scaleToFitWidth
        scaleY = scaleY * scaleToFitWidth
      }
      
      let sizeAfterScale = CGSize(width: originalSize.width * scaleX, height: originalSize.height * scaleY)
      videoComposition.renderSize = sizeAfterScale
      
      if originalAspectRatio > settings.videoMaxPortraitAspectRatio {
        let newHeigth = sizeAfterScale.width * settings.videoMaxPortraitAspectRatio
        
        cropOffY = ((sizeAfterScale.height - newHeigth) / 2) / scaleY
        videoComposition.renderSize = CGSize(width: sizeAfterScale.width, height: newHeigth)
      }
    case .left, .right:
      let originalSize = clipVideoTrack.naturalSize
      videoComposition.renderSize = originalSize
      
      let originalAspectRatio = originalSize.height / originalSize.width
      
      if originalSize.width < settings.videoMinSizes.width {
        scaleX = settings.videoMinSizes.width / originalSize.width
        scaleY = settings.videoMinSizes.width / originalSize.width
      }
      let sizeAfterScaleToMinSize = CGSize(width: originalSize.width * scaleX, height: originalSize.height * scaleY)
      videoComposition.renderSize = sizeAfterScaleToMinSize
      
      if originalAspectRatio < settings.videoMinLandscapeAspectRatio {
        let scaleToFitHeight = settings.videoMinSizes.height / sizeAfterScaleToMinSize.height
        
        scaleX = scaleX * scaleToFitHeight
        scaleY = scaleY * scaleToFitHeight
        
        let sizeAfterScale = CGSize(width: originalSize.width * scaleX, height: originalSize.height * scaleY)
        
        cropOffX = ((sizeAfterScale.width - settings.videoMaxSizes.width) / 2) / scaleX
        videoComposition.renderSize = sizeAfterScale
        
      } else {
        if sizeAfterScaleToMinSize.width > settings.videoMaxSizes.width {
          let scaleToFitWidth = settings.videoMaxSizes.width / sizeAfterScaleToMinSize.width
          scaleX = scaleX * scaleToFitWidth
          scaleY = scaleY * scaleToFitWidth
          
          let sizeAfterScale = CGSize(width: originalSize.width * scaleX, height: originalSize.height * scaleY)
          
          cropOffX = 0.0
          videoComposition.renderSize = sizeAfterScale
        }
      }
    default:
      break
    }
    
    let name = "\(videoComposition.renderSize.width)x\(videoComposition.renderSize.height)_RESIZED_\(url.lastPathComponent)"
    let outputURL = dirUrl.appendingPathComponent(name)
    try? FileManager.default.removeItem(at: outputURL)
    
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: duration)
    
//    instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTimeMakeWithSeconds(60, preferredTimescale: 30) )
    let t3 = CGAffineTransform(scaleX: scaleX, y: scaleY)
    
    let finalTransform: CGAffineTransform
    switch videoTrackOrientation {
    case .up:
      let t1 = CGAffineTransform(translationX: clipVideoTrack.naturalSize.height - cropOffX, y: 0.0 - cropOffY)
      let t2 = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
      finalTransform = (t2).concatenating(t1).concatenating(t3)
    case .down:
      let t1 = CGAffineTransform(translationX: 0 - cropOffX, y: clipVideoTrack.naturalSize.width - cropOffY ); // not fixed width is the real height in upside down
      let t2 = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
      finalTransform = (t2).concatenating(t1).concatenating(t3)
    case .left:
      let t1 = CGAffineTransform(translationX: clipVideoTrack.naturalSize.width - cropOffX, y: clipVideoTrack.naturalSize.height - cropOffY)
      let t2 = CGAffineTransform(rotationAngle: CGFloat.pi)
      finalTransform = (t2).concatenating(t1).concatenating(t3)
    case .right:
      let t1 = CGAffineTransform(translationX: 0 - cropOffX, y: 0 - cropOffY );
      let t2 = CGAffineTransform(rotationAngle: 0.0)
      finalTransform = (t2).concatenating(t1).concatenating(t3)
    default:
      finalTransform = CGAffineTransform(rotationAngle: 0.0)
    }
    
    let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)
    
    transformer.setTransform(finalTransform, at: CMTime.zero)
    instruction.layerInstructions = [transformer]
    videoComposition.instructions = [instruction]
    
    guard let exporter = AVAssetExportSession(asset: asset, presetName: settings.videoTargetExportPreset) else {
      complete(Result(error: MediaProcessingPipelineError.videoExportSessionError))
      return
    }
    
   
    exporter.timeRange = CMTimeRange(start: CMTime.zero, duration: duration)
    exporter.videoComposition = videoComposition
    exporter.outputURL = outputURL
    exporter.outputFileType = settings.outputFileType
    
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
        complete(Result(error: MediaProcessingPipelineError.videoExportSessionError))
      case .cancelled:
        complete(Result(error: MediaProcessingPipelineError.videoExportSessionError))
      }
    })
  }
 
 */
  /*
  func oldResizeVideoAt(_ url: URL, complete: @escaping ResultCompleteHandler<URL, MediaProcessingPipelineError>) {
    let dirUrl = url.deletingLastPathComponent()
    
    let name = "RESIZED_\(url.lastPathComponent)"
    let outputURL = dirUrl.appendingPathComponent(name)
    try? FileManager.default.removeItem(at: outputURL)
    
    let asset = AVAsset(url: url)
    let composition = AVMutableComposition()
    composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
    
    guard let clipVideoTrack = asset.tracks(withMediaType: .video).first else {
      complete(Result(error: MediaProcessingPipelineError.videoResizeError))
      return
    }
    
    let videoComposition = AVMutableVideoComposition()
    videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
    videoComposition.renderSize = settings.videoTargetSize
    
    let videoMinDimension = min(clipVideoTrack.naturalSize.width, clipVideoTrack.naturalSize.height)
    let videoMaxDimension = max(clipVideoTrack.naturalSize.width, clipVideoTrack.naturalSize.height)
    let cropOff = (videoMaxDimension - videoMinDimension) / 2 //Move crop rect to middle
    let videoTrackOrientation = getOrientationForTrack(videoTrack: clipVideoTrack)
  
    var cropOffX: CGFloat = 0.0
    var cropOffY: CGFloat = 0.0
    let cropWidth: CGFloat = videoMinDimension
    let cropHeight: CGFloat = videoMinDimension
    
    let scaleX = settings.videoTargetSize.width / cropWidth
    let scaleY = settings.videoTargetSize.height / cropHeight

    switch videoTrackOrientation {
    case .up:
      cropOffY = cropOff
    case .down:
      cropOffY = cropOff
    case .left:
      cropOffX = cropOff
    case .right:
      cropOffX = cropOff
    default:
      break
    }

    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTimeMakeWithSeconds(60, preferredTimescale: 30) );
    let t3 = CGAffineTransform(scaleX: scaleX, y: scaleY)
    
    let finalTransform: CGAffineTransform
    switch videoTrackOrientation {
    case .up:
      let t1 = CGAffineTransform(translationX: clipVideoTrack.naturalSize.height - cropOffX, y: 0.0 - cropOffY)
      let t2 = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
      finalTransform = (t2).concatenating(t1).concatenating(t3)
    case .down:
      let t1 = CGAffineTransform(translationX: 0 - cropOffX, y: clipVideoTrack.naturalSize.width - cropOffY ); // not fixed width is the real height in upside down
      let t2 = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
      finalTransform = (t2).concatenating(t1).concatenating(t3)
    case .left:
      let t1 = CGAffineTransform(translationX: clipVideoTrack.naturalSize.width - cropOffX, y: clipVideoTrack.naturalSize.height - cropOffY)
      let t2 = CGAffineTransform(rotationAngle: CGFloat.pi)
      finalTransform = (t2).concatenating(t1).concatenating(t3)
    case .right:
      let t1 = CGAffineTransform(translationX: 0 - cropOffX, y: 0 - cropOffY );
      let t2 = CGAffineTransform(rotationAngle: 0.0)
      finalTransform = (t2).concatenating(t1).concatenating(t3)
    default:
      finalTransform = CGAffineTransform(rotationAngle: 0.0)
    }
    
    let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)

    transformer.setTransform(finalTransform, at: CMTime.zero)
    instruction.layerInstructions = [transformer]
    videoComposition.instructions = [instruction]
    
    guard let exporter = AVAssetExportSession(asset: asset, presetName: settings.videoTargetExportPreset) else {
      complete(Result(error: MediaProcessingPipelineError.videoExportSessionError))
      return
    }
    exporter.videoComposition = videoComposition
    exporter.outputURL = outputURL
    exporter.outputFileType = settings.outputFileType
    
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
        complete(Result(error: MediaProcessingPipelineError.videoExportSessionError))
      case .cancelled:
        complete(Result(error: MediaProcessingPipelineError.videoExportSessionError))
      }
    })
  }
  */
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
  
  fileprivate func exportAsset(_ mPhasset: LibraryAsset, settings: MediaExportSettings, complete: @escaping ResultCompleteHandler<ExportedLibraryAsset, MediaProcessingPipelineError>) {
    
    guard let resource = PHAssetResource.assetResources(for: mPhasset.underlyingAsset).first else {
      complete(Result(error: MediaProcessingPipelineError.noAssetResourceError))
      return
    }
    
    let name = "\(UUID().uuidString)_\(resource.originalFilename)_EXPORTED"
    
    switch mPhasset.underlyingAsset.mediaType {
    case .unknown:
      complete(Result(error: MediaProcessingPipelineError.unSupportedAssetTypeError))
    case .image:
      exportImageAsset(mPhasset, name: name, settings: settings, complete: complete)
    case .video:
      exportVideoAsset(mPhasset, name: name, settings: settings, complete: complete)
    case .audio:
      complete(Result(error: MediaProcessingPipelineError.unSupportedAssetTypeError))
    }
  }
  
  fileprivate func exportImageAssetForWall(_ mPhasset: LibraryAsset, name: String, settings: MediaExportSettings, complete: @escaping ResultCompleteHandler<URL, MediaProcessingPipelineError>) {
//    guard mPhasset.mediaType == .image else {
//      complete(Result(error: MediaProcessingPipelineError.assetTypeError))
//      return
//    }
    
    let imageManager = PHCachingImageManager()
    let opt = PHImageRequestOptions()
    opt.resizeMode = .none
    opt.deliveryMode = .highQualityFormat
    opt.isNetworkAccessAllowed = true
    imageManager.requestImage(for: mPhasset.underlyingAsset,
                              targetSize: PHImageManagerMaximumSize,
                              contentMode: PHImageContentMode.default,
                              options: opt,
                              resultHandler:
      { (image: UIImage?, _) in
        let imageSettings = ImageExportSettings(settings: settings)
        
        guard let resizedImage = image?.resizedImageFor(imageSettings, cropPerCent: mPhasset.crop) else {
          complete(Result(error: MediaProcessingPipelineError.photoResizeError))
          return
        }
        
        do {
          let url = try resizedImage.saveAsJPG(name, compression: settings.imageCompresion)
          
          complete(Result(value: url))
          return
        } catch {
          complete(Result(error: MediaProcessingPipelineError.photoExportError(error)))
        }
    })
  }
  
  fileprivate func exportImageAssetForUserpic(_ mPhasset: LibraryAsset, name: String, settings: MediaExportSettings, complete: @escaping ResultCompleteHandler<URL, MediaProcessingPipelineError>) {
    
    
    
    let imageManager = PHCachingImageManager()
    let opt = PHImageRequestOptions()
    opt.resizeMode = .fast
    opt.deliveryMode = .highQualityFormat
    opt.isNetworkAccessAllowed = true
    
    imageManager.requestImage(for: mPhasset.underlyingAsset,
                              targetSize: PHImageManagerMaximumSize,
                              contentMode: PHImageContentMode.default,
                              options: opt,
                              resultHandler:
      { (image: UIImage?, _) in
        
        
        let imageSettings = ImageExportSettings(userPicSettings: settings)
        
        guard let resizedImage = image?.resizedImageFor(imageSettings, cropPerCent: mPhasset.crop) else {
          complete(Result(error: MediaProcessingPipelineError.photoResizeError))
          return
        }
        
        do {
          let url = try resizedImage.saveAsJPG(name, compression: settings.imageCompresion)
          complete(Result(value: url))
          return
        } catch {
          complete(Result(error: MediaProcessingPipelineError.photoExportError(error)))
        }
    })
  }
  
  fileprivate func exportImageAsset(_ mPhasset: LibraryAsset, name: String, settings: MediaExportSettings, complete: @escaping ResultCompleteHandler<ExportedLibraryAsset, MediaProcessingPipelineError>) {
    guard mPhasset.underlyingAsset.mediaType == .image else {
      complete(Result(error: MediaProcessingPipelineError.assetTypeError))
      return
    }
   
    let imageManager = PHCachingImageManager()
    let opt = PHImageRequestOptions()
    opt.resizeMode = .none
    opt.deliveryMode = .highQualityFormat
    opt.isNetworkAccessAllowed = true
    //opt.version = .original
    imageManager.requestImage(for: mPhasset.underlyingAsset,
                              targetSize: PHImageManagerMaximumSize,
                              contentMode: PHImageContentMode.default,
                              options: opt,
                              resultHandler:
      { (image: UIImage?, _) in
//        let imageSettings = mPhasset.shouldUseAsDigitalGood ?
//          ImageExportSettings(originalSizeUsingSettingsRatio: settings) :
//          ImageExportSettings(settings: settings)
        
        let imageSettings = ImageExportSettings(settings: settings)
        
        guard let resizedImage = image?.resizedImageFor(imageSettings, cropPerCent: mPhasset.crop) else {
          complete(Result(error: MediaProcessingPipelineError.photoResizeError))
          return
        }
        
        do {
          
          let url = try resizedImage.saveAsJPG(name, compression: settings.imageCompresion)
          
          guard mPhasset.shouldUseAsDigitalGood else {
            complete(Result(value: .photo(url, original: nil)))
            return
          }
          let originalImageName = "\(name)_original"
          let originalImageUrl = try image?.saveAsJPG(originalImageName, compression: settings.imageOriginalCompresion)
          complete(Result(value: .photo(url, original: originalImageUrl)))
          return
          
        } catch {
          complete(Result(error: MediaProcessingPipelineError.photoExportError(error)))
        }
    })
  }
  
  fileprivate func exportVideoAsset(_ mPhasset: LibraryAsset, name: String, settings: MediaExportSettings, complete: @escaping ResultCompleteHandler<ExportedLibraryAsset, MediaProcessingPipelineError>) {
    guard mPhasset.underlyingAsset.mediaType == .video else {
      complete(Result(error: MediaProcessingPipelineError.assetTypeError))
      return
    }
    
    let assetLocalPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(name).mp4")
    
    let fileManager = FileManager()
    try? fileManager.removeItem(at: assetLocalPath)
    
    let options: PHVideoRequestOptions = PHVideoRequestOptions()
    options.version = .current
    
    PHImageManager.default().requestExportSession(forVideo: mPhasset.underlyingAsset, options: options, exportPreset: settings.rawVideoFileExportPreset, resultHandler: { (session, info) in
      // if we just request video url asset and try upload to server
      // we will have problems with slow mo videos
      // also we will be on the main thread and access for video will expire, if we go to background
      // + size of video is very huge
      
      guard let session = session else { return }
      session.outputURL = assetLocalPath
      session.outputFileType = settings.outputFileType
      session.shouldOptimizeForNetworkUse = settings.shouldOptimizeForNetworkUse
      
      session.exportAsynchronously {
        switch session.status {
        case .unknown:
          break
        case .waiting:
          break
        case .exporting:
          break
        case .completed:
          complete(Result(value: .rawVideo(assetLocalPath, requiredCrop: mPhasset.crop)))
        case .failed:
          complete(Result(error: MediaProcessingPipelineError.videoExportSessionError))
        case .cancelled:
          break
        }
      }
    })
  }
}

fileprivate extension UIImage {
  func saveAsJPG(_ name: String, compression: CGFloat) throws -> URL {
    let assetLocalPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(name).jpg")
    
    let fileManager = FileManager()
    try? fileManager.removeItem(at: assetLocalPath)
    
    try self.jpegData(compressionQuality: compression)?.write(to: assetLocalPath)
    return assetLocalPath
  }
  
  fileprivate func cropRectForPerCentInsets(_ perCentInsets: UIEdgeInsets) -> CGRect {
    let left = perCentInsets.left * size.width / 100
    let top = perCentInsets.top * size.height / 100
    
    let right = perCentInsets.right * size.width / 100
    let bottom = perCentInsets.bottom * size.height / 100
    
    let newOrigin = CGPoint(x: left, y: top)
    let newWidth = size.width - left - right
    let newHeight = size.height - top - bottom
    let newSize = CGSize(width: newWidth, height: newHeight)
    return CGRect(origin: newOrigin, size: newSize)
  }
  
  fileprivate func cropping(to rect: CGRect) -> UIImage? {
    var rect = rect
    rect.origin.x *= scale
    rect.origin.y *= scale
    rect.size.width *= scale
    rect.size.height *= scale
    
    guard let imageRef = cgImage?.cropping(to: rect) else {
      return nil
    }
    
    let image = UIImage(cgImage: imageRef, scale: scale, orientation: imageOrientation)
    return image
  }
  
  fileprivate func resizedImageFor(_ settings: ImageExportSettings, cropPerCent: UIEdgeInsets) -> UIImage? {
    var image: UIImage?
    let width: CGFloat
    let height: CGFloat
    let ceiledCropPerCent = cropPerCent.ceilInsets()
    if !ceiledCropPerCent.bottom.isZero ||
      !ceiledCropPerCent.top.isZero ||
       !ceiledCropPerCent.left.isZero ||
      !ceiledCropPerCent.right.isZero {
      
      let cropRect = cropRectForPerCentInsets(ceiledCropPerCent)
      guard let cropedImage = cropping(to: cropRect) else {
        return nil
      }
      
      image = cropedImage
      width = cropedImage.size.width
      height = cropedImage.size.height
    } else {
      image = self
      width = size.width
      height = size.height
    }
    
    let originalImageAspectRatio = height / width
    
    let resizeWidth = width < settings.imageMinWidth ? settings.imageMinWidth : width
    image = image?.scaledToFit(newWidth: resizeWidth)
    
    guard originalImageAspectRatio >= settings.imageMinLandscapeAspectRatio else {
      guard let image = image?.scaledToFit(newHeight: settings.imageMinHeight) else {
        return nil
      }
      
      let newHeight = image.size.height
      let newWidth = ceil(image.size.height / settings.imageMinLandscapeAspectRatio)
      
      let offsetX = ceil((image.size.width - newWidth) / 2.0)
      let rect = CGRect(x: offsetX, y: 0, width: newWidth, height: newHeight)
      
      guard let imageRef = image.cgImage?.cropping(to: rect) else {
        return nil
      }
      
      return UIImage(cgImage:imageRef)
    }
    
    if width > settings.imageMaxWidth {
      image = image?.scaledToFit(newWidth: settings.imageMaxWidth)
    }
    
    guard let scaledImage = image else {
      return nil
    }
    
    let scaledImageHeight = scaledImage.size.height
    guard originalImageAspectRatio <= settings.imageMaxPortraitAspectRatio else {
      let newHeight = ceil(scaledImage.size.width * settings.imageMaxPortraitAspectRatio)
      let offsetY = ceil((scaledImageHeight - newHeight) / 2.0)
      let rect = CGRect(x: 0, y: offsetY, width: scaledImage.size.width, height: newHeight)
      guard let cgImage = scaledImage.cgImage else {
        return nil
      }
      
      guard let imageRef = cgImage.cropping(to: rect) else {
        return nil
      }
      
      return UIImage(cgImage:imageRef)
    }
    
    return scaledImage
  }
  
  fileprivate func scaledToFit(newHeight: CGFloat) -> UIImage? {
    let width: CGFloat = size.width
    let height: CGFloat = size.height
    
    let ratio = width / height
    let newWidth = newHeight * ratio
    
    let canvasSize = CGSize(width: floor(newWidth), height: CGFloat(floor(newHeight)))
    UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
    defer { UIGraphicsEndImageContext() }
    draw(in: CGRect(origin: .zero, size: canvasSize))
    guard let image = UIGraphicsGetImageFromCurrentImageContext(),
      let cgImage = image.cgImage else {
        return nil
    }
    return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
  }
  
  fileprivate func scaledToFit(newWidth: CGFloat) -> UIImage? {
    let width: CGFloat = size.width
    let height: CGFloat = size.height
    
    let ratio = height / width
    let newHeight = newWidth * ratio
    
    let canvasSize = CGSize(width: ceil(newWidth), height: CGFloat(ceil(newHeight)))
    UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
    defer { UIGraphicsEndImageContext() }
    draw(in: CGRect(origin: .zero, size: canvasSize))
    guard let image = UIGraphicsGetImageFromCurrentImageContext(),
      let cgImage = image.cgImage else {
        return nil
    }
    return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
  }
}

extension UIEdgeInsets {
  fileprivate func ceilInsets() -> UIEdgeInsets {
    return UIEdgeInsets(top: ceil(top), left: ceil(left), bottom: ceil(bottom), right: ceil(right))
  }
}
