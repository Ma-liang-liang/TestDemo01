//
//  DCBaseModel.swift
//  DicosApp
//
//  Created by edy on 2021/8/1.
//

import UIKit
import SmartCodable

class SKBaseModel: SmartCodable {
   
    var code  = ""
   
    var message = ""
   
//    var data : Any?
   
    required init() {}
}

extension SKBaseModel {
   
    var generalCode: String {
        return code
    }
    
    var generalMessage: String {
        return message
    }
}

