//
//  Result.swift
//  AVCompressor
//
//  Created by Sergey Kazakov on 20/12/2019.
//  Copyright © 2019 kazaimazai. All rights reserved.
//

import Foundation

typealias ResultCompleteHandler<T, E: Error> = (Result<T, E>) -> ()

enum Result<T, Error: Swift.Error> {
  case success(T)
  case failure(Error)
  
  init(value: T) {
    self = .success(value)
  }
  
  init(error: Error) {
    self = .failure(error)
  }
}
