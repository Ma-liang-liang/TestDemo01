//
//  SKAPIDefine.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/2/18.
//

import UIKit
import Alamofire

public enum SKHTTPMethod: String {
    case get, post, put, delete
    
    var alamofireMethod: Alamofire.HTTPMethod {
        Alamofire.HTTPMethod(rawValue: rawValue.uppercased())
    }
}

public struct SKUploadFile {
    public enum FileType {
        case data(Data)
        case file(URL)
    }
    
    public let data: FileType
    public let name: String
    public let fileName: String
    public let mimeType: String
    
    public init(data: Data, name: String, fileName: String, mimeType: String) {
        self.data = .data(data)
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
    
    public init(fileURL: URL, name: String, fileName: String, mimeType: String) {
        self.data = .file(fileURL)
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
}
