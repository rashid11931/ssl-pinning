//
//  JSONDeserialize.swift
//  SSL_TLS_CERT_PINNING
//
//  Created by MD RASHID IQUBAL on 26/10/25.
//

import Foundation

struct JSONParsing {
    
    static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> Result<T, NetworkError> {
        let decoder = JSONDecoder()
       // decoder.keyDecodingStrategy = .useDefaultKeys
       // decoder.keyDecodingStrategy = .convertFromSnakeCase // this line is required if we don't use DecodingKey protocol
        
        do {
            let decoded = try decoder.decode(T.self, from: data)
            return .success(decoded)
        } catch let decodingError as DecodingError {
            switch decodingError {
            case .typeMismatch(let type, let context):
                debugPrint("❌ Type mismatch for type \(type):", context.debugDescription)
                debugPrint("   Coding path:", context.codingPath)
                return .failure(.decodingFailed(decodingError))
                
            case .valueNotFound(let type, let context):
                debugPrint("❌ Value not found for type \(type):", context.debugDescription)
                debugPrint("   Coding path:", context.codingPath)
                return .failure(.decodingFailed(decodingError))
                
            case .keyNotFound(let key, let context):
                debugPrint("❌ Key '\(key.stringValue)' not found:", context.debugDescription)
                debugPrint("   Coding path:", context.codingPath)
                return .failure(.decodingFailed(decodingError))
                
            case .dataCorrupted(let context):
                debugPrint("❌ Data corrupted:", context.debugDescription)
                debugPrint("   Coding path:", context.codingPath)
                return .failure(.decodingFailed(decodingError))
                
            @unknown default:
                debugPrint("❌ Unknown decoding error:", decodingError.localizedDescription)
                return .failure(.decodingFailed(decodingError))
            }
        } catch {
            debugPrint("❌ Non-decoding error:", error.localizedDescription)
            return .failure(.decodingFailed(error))
        }
    }
    
    
    func encode() {
        
    }
}
