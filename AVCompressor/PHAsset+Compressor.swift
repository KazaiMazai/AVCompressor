//
//  PHAsset+AVCompressor.swift
//  AVCompressor
//
//  Created by Sergey Kazakov on 20/12/2019.
//  Copyright © 2019 kazaimazai. All rights reserved.
//

import Foundation
import Photos

extension Compressor where Base: PHAsset {
  func export(with options: CompressorExportOptions?, complete: @escaping ResultCompleteHandler<URL, Error>) {
    let options = CompressorManager.shared.currentDefaultOptions + (options ?? EmptyCompressorExportOptions)
    
    CompressorManager.shared.exportVideoAsset(base, options: options, complete: complete)
  }
}
