//
//  FileManger.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/16.
//
import Foundation

extension FileManager {
    /// 获取文档目录（Documents）
    static var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// 获取缓存目录（Caches）
    static var cachesDirectory: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    /// 获取临时目录（Temporary）
    static var tempDirectory: URL {
        return FileManager.default.temporaryDirectory
    }
    
    /// 获取应用支持目录（Application Support）
    static var applicationSupportDirectory: URL {
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }
    
    /// 获取或创建自定义文件夹（如果不存在则创建）
    static func getOrCreateDirectory(
        in directory: SearchPathDirectory = .documentDirectory,
        path: String
    ) -> URL? {
        let baseURL = FileManager.default.urls(for: directory, in: .userDomainMask)[0]
        let folderURL = baseURL.appendingPathComponent(path)
        
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            do {
                try FileManager.default.createDirectory(
                    at: folderURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                return folderURL
            } catch {
                print("Error creating directory: \(error.localizedDescription)")
                return nil
            }
        }
        return folderURL
    }
    
    /// 获取指定目录下的所有文件
    static func filesInDirectory(at url: URL) -> [URL]? {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            return fileURLs
        } catch {
            print("Error listing files: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 检查文件夹是否存在
    static func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}
