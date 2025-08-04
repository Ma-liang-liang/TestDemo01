//
//  DCMultiPartFormData.swift
//  DicosApp
//
//  Created by edy on 2021/7/31.
//

import UIKit
import Moya

/// 上传 "multipart/form-data".
public struct SKMultiPartFormData {
    public enum FormDataProvider {
        case data(Foundation.Data)
        case file(URL)
        case stream(InputStream, UInt64)
    }
    
    public init(provider: FormDataProvider, name: String, fileName: String? = nil, mimeType: String? = nil) {
        self.provider = provider
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
    
    public let provider: FormDataProvider
    
    public let name: String
    
    public let fileName: String?
    
    public let mimeType: String?
    
    func asMoyaMultipartFormData() -> Moya.MultipartFormData {
        var formDataProvider: Moya.MultipartFormData.FormDataProvider
        switch provider {
        case .data(let content):
            formDataProvider = .data(content)
        case .file(let url):
            formDataProvider = .file(url)
        case .stream(let stream, let number):
            formDataProvider = .stream(stream, number)
        }
        
        let formData = Moya.MultipartFormData(provider: formDataProvider,
                                              name: name,
                                              fileName: fileName,
                                              mimeType: mimeType)
        return formData
    }
}
