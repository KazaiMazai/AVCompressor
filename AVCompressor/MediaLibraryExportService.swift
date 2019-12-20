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

class MediaLibraryExportService {
  let settings: MediaExportSettings
  let videoCaptureSettings: CameraCaptureSettings
  
  init(settings: MediaExportSettings, videoCaptureSettings: CameraCaptureSettings) {
    self.settings = settings
    self.videoCaptureSettings = videoCaptureSettings
  }
 
  func exportAsset(_ mPhasset: LibraryAsset, complete: @escaping ResultCompleteHandler<ExportedLibraryAsset, MediaProcessingPipelineError>) {
    exportAsset(mPhasset, settings: settings, complete: complete)
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
      complete(Result(error: MediaProcessingPipelineError.unSupportedAssetTypeError))
    case .video:
      exportVideoAsset(mPhasset, name: name, settings: settings, complete: complete)
    case .audio:
      complete(Result(error: MediaProcessingPipelineError.unSupportedAssetTypeError))
    }
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
          complete(Result(value: ExportedLibraryAsset.rawVideo(assetLocalPath, requiredCrop: mPhasset.crop)))
        case .failed:
          complete(Result(error: MediaProcessingPipelineError.videoExportSessionError))
        case .cancelled:
          break
        }
      }
    })
  }
}

extension UIEdgeInsets {
  fileprivate func ceilInsets() -> UIEdgeInsets {
    return UIEdgeInsets(top: ceil(top), left: ceil(left), bottom: ceil(bottom), right: ceil(right))
  }
}


extension PHAsset {
  func exportToFile(with options: [CompressorExportOptionsItem]?) {
    
  }
}


