//
//  SFDownloadDestination.swift
//  sufinc_network_module
//
//  Created by sunshine on 2023/7/21.
//

import UIKit
import Moya
 
public struct SKDownloadDestination {
    public let downloadDirURL: URL
    
    public init(downloadDirURL: URL) {
        self.downloadDirURL = downloadDirURL
    }
    
    func asMoyaDownloadDestination() -> DownloadDestination {
        return { temporaryURL, response in
            guard let suggestedFilename = response.suggestedFilename else {
                return (downloadDirURL.appendingPathComponent("sufinc_\(Int.random(in: 0...1000))"), [.createIntermediateDirectories, .removePreviousFile])
            }
            return (downloadDirURL.appendingPathComponent(suggestedFilename), [.createIntermediateDirectories, .removePreviousFile])
        }
    }
    
    
    /// Default `Destination` used by Alamofire to ensure all downloads persist. This `Destination` prepends
    /// `Alamofire_` to the automatically generated download name and moves it within the temporary directory. Files
    /// with this destination must be additionally moved if they should survive the system reclamation of temporary
    /// space.
    static let defaultDestination: DownloadDestination = { url, _ in
        (defaultDestinationURL(url), [])
    }

    /// Default `URL` creation closure. Creates a `URL` in the temporary directory with `Alamofire_` prepended to the
    /// provided file name.
    static let defaultDestinationURL: (URL) -> URL = { url in
        let filename = "Alamofire_\(url.lastPathComponent)"
        let destination = url.deletingLastPathComponent().appendingPathComponent(filename)

        return destination
    }
}
