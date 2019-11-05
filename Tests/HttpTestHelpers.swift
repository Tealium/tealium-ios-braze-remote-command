//
//  HttpTestHelpers.swift
//  TealiumBraze
//
//  Created by Jonathan Wong on 8/8/19.
//  Copyright © 2019 Jonathan Wong. All rights reserved.
//

import Foundation

struct RemoteCommandResponsePayload: Codable {
    var config: [String: String]
    var payload: [String: String]
}

class HttpTestHelpers {
    class func httpRequest(commandId: String, payload: [String: String]) -> URLRequest? {
        let url = "tealium://\(commandId)?request="
        
        let response = RemoteCommandResponsePayload(config: ["response_id": "00000"], payload: payload)
        
        let encoder = JSONEncoder()
        let json = try? encoder.encode(response)
        
        if let json = json, let encodedString = String(data: json, encoding: .utf8)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: "\(url)\(encodedString)") {
            return URLRequest(url: url)
        }
        
        return nil
    }
    
    class func httpRequest(commandId: String, config: [String: Any], payload: [String: Any]) -> URLRequest? {
        let url = "tealium://\(commandId)?request="
        let remoteCommandrc = ["config": config, "payload": payload] as [String: Any]
        let json = try! JSONSerialization.data(withJSONObject: remoteCommandrc, options: .prettyPrinted)
        if let encodedString = String(data: json, encoding: .utf8)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: "\(url)\(encodedString)") {
            print(encodedString)
            return URLRequest(url: url)
        }
        
        return nil
    }
    
    class func httpRequestDescription(commandId: String, config: [String: Any], payload: [String: Any]) -> String? {
        let url = "tealium://\(commandId)?request="
        let remoteCommandrc = ["config": config, "payload": payload] as [String: Any]
        let json = try! JSONSerialization.data(withJSONObject: remoteCommandrc, options: .prettyPrinted)
        if let encodedString = String(data: json, encoding: .utf8)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: "\(url)\(encodedString)") {
            print(encodedString)
            return URLRequest(url: url).description
        }
        
        return nil
    }
    
}
