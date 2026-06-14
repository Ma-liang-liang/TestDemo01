//
//  SKPropertyWrapper.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/5.
//

import UIKit
import SmartCodable

@propertyWrapper
struct UserDefaultCodable<T: SmartCodable> {
    let key: String
    let defaultValue: T

    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            guard let content = UserDefaults.standard.string(forKey: key),
                  let value = T.deserialize(from: content) else {
                return defaultValue
            }
            return value
        }
        set {
            
            if let content = newValue.toJSONString() {
                UserDefaults.standard.set(content, forKey: key)
                UserDefaults.standard.synchronize()
            }
        }
    }
}



struct UserProfile: SmartCodable {
    init() {}
    
    var name = ""
    var age = 0
}

struct Settings {
    
    @UserDefaultCodable("userProfile", defaultValue: UserProfile())
    static var userProfile: UserProfile
}

func testUser() {
    // 设置值
    var user = UserProfile()
    user.name = "Joy"
    user.age = 12
    Settings.userProfile = user

    // 获取值
    print("User profile: \(Settings.userProfile)") // 输出: User profile: UserProfile(name: "John", age: 30)

}
