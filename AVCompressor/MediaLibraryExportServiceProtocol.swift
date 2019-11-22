//
//  MediaLibraryExportServiceProtocol.swift
//  Pibble
//
//  Created by Kazakov Sergey on 18.08.2018.
//  Copyright © 2018 com.kazai. All rights reserved.
//

import UIKit
import Photos


protocol MediaLibraryExportServiceProtocol {
  var settings: MediaExportSettings { get }
  
  var videoCaptureSettings: CameraCaptureSettings { get }
  
  func exportAsset(_ mPhasset: LibraryAsset, complete: @escaping ResultCompleteHandler<ExportedLibraryAsset, MediaProcessingPipelineError>)
  
  func exportAssetForUserpicPurpose(_ mPhasset: LibraryAsset, complete: @escaping ResultCompleteHandler<URL, MediaProcessingPipelineError>)
  
  func exportAssetForWallPurpose(_ mPhasset: LibraryAsset, complete: @escaping ResultCompleteHandler<URL, MediaProcessingPipelineError>)
  
  func resizeVideoAt(_ url: URL, cropPerCent: UIEdgeInsets, complete: @escaping ResultCompleteHandler<URL, MediaProcessingPipelineError>)
  
  func resizeImageWithCurrentExportSettings(image: UIImage, cropPerCent: UIEdgeInsets) -> UIImage?
  
  func cropImageWithCurrentExportSettingsRatio(_ image: UIImage, cropPerCent: UIEdgeInsets) -> UIImage?
  
  func saveAsJPGWithCurrentExportSettings(image: UIImage, name: String) -> URL?
  
  func saveAsJPGWithoutComression(image: UIImage, name: String) -> URL?
  
  func resizeImageWithCurrentExportSettings(image: UIImage, cropPerCent: UIEdgeInsets, complete: @escaping (UIImage?) -> Void)
  
  func saveAsJPGWithCurrentExportSettings(image: UIImage, name: String, complete: @escaping (URL?) -> Void)
}
