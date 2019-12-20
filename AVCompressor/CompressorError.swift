//
//  CompressorError.swift
//  AVCompressor
//
//  Created by Sergey Kazakov on 29/11/2019.
//  Copyright © 2019 kazaimazai. All rights reserved.
//

import Foundation

enum CompressorError: Error {
  case assetTypeError
  case videoExportSessionError
  case videoResizeError
}
