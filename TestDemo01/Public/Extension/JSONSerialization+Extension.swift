//
//  JSONSerialization+Extension.swift
//  DicosApp
//
//  Created by edy on 2021/8/2.
//

import UIKit


extension JSONSerialization {
    
   static func getDictionaryFromJSONData(jsonData: Data) -> [String: Any]? {
        
        var dict: [String: Any]?
        do {
            dict = try JSONSerialization.jsonObject(with:jsonData,options: .mutableContainers) as? [String : Any]
        } catch {
            
        }
        return dict
    }
    
   static func getArrayFromJSONData(jsonData: Data) -> [Any]? {
        
        var array: [Any]?
        do {
            array = try JSONSerialization.jsonObject(with:jsonData,options: .mutableContainers) as? [Any]
        } catch {
            
        }
        return array
    }
    
   static func getJSONStringFromDictionary(dictionary: [String: Any]) -> String {
          if !JSONSerialization.isValidJSONObject(dictionary) {
              print("无法解析出JSONString")
              return ""
          }
        var data: Data?
        do {
            data = try JSONSerialization.data(withJSONObject:dictionary,options: [])
        } catch {
            
        }
        let json = String(data: data ?? Data(), encoding: .utf8) ?? ""
        return json
      }
    
    //数组转json
   static func getJSONStringFromArray(array: [Any]) -> String {
         
        if !JSONSerialization.isValidJSONObject(array) {
            print("无法解析出JSONString")
            return ""
        }
        var data: Data?
        do {
            data = try JSONSerialization.data(withJSONObject:array,options: [])
        } catch {
        
        }
        let json = String(data: data ?? Data(), encoding: .utf8) ?? ""
        return json
    }
}
