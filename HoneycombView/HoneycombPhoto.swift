//
//  HoneycombPhoto.swift
//  HoneycombViewExample
//
//  Created by suzuki_keishi on 2015/10/01.
//  Copyright © 2015 suzuki_keishi. All rights reserved.
//

import UIKit

// MARK: - HoneycombPhoto
open class HoneycombPhoto:NSObject {
    
    var underlyingImage:UIImage!
    
    override init() {
        super.init()
    }
    
    convenience init(image: UIImage){
        self.init()
        underlyingImage = image
    }
    
    // MARK: - class func
    class func photoWithImage(_ image: UIImage) -> HoneycombPhoto {
        return HoneycombPhoto(image: image)
    }
}
