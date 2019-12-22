//
//  Compressor.swift
//  AVCompressor
//
//  Created by Sergey Kazakov on 29/11/2019.
//  Copyright © 2019 kazaimazai. All rights reserved.
//

import Foundation
import Photos

public final class Compressor<Base> {
  public let base: Base
  public init(_ base: Base) {
    self.base = base
  }
}

public protocol CompressorСompatible {
  associatedtype CompatibleType
  var compressor: CompatibleType { get }
}

public extension CompressorСompatible {
  var compressor: Compressor<Self> {
    return Compressor(self)
  }  
}

extension PHAsset: CompressorСompatible { }

extension AVAssetTrack: CompressorСompatible { }

extension CGAffineTransform: CompressorСompatible { }
