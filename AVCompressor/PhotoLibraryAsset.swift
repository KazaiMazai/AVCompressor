//
//  PhotoLibraryAsset.swift
//  AVCompressor
//
//  Created by Sergey Kazakov on 29/11/2019.
//  Copyright © 2019 kazaimazai. All rights reserved.
//

import Foundation
import Photos

struct PhotoLibraryAsset {
  var underlyingAsset: PHAsset
  
  
  init(asset: PHAsset) {
    self.underlyingAsset = asset
  }
}
