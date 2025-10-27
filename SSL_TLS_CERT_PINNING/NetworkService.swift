//
//  NetworkService.swift
//  SSL_TLS_CERT_PINNING
//
//  Created by MD RASHID IQUBAL on 26/10/25.
//

import Foundation

final class NetworkManager {
    private let session: URLSession
    
    init(certName: String) {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        let delegate = PinnedSessionDelegate(certName: certName)
        self.session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }
    
    func get<T: Decodable>(urlString: String, completion: @escaping (Result<T, NetworkError>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        
        session.dataTask(with: request) { data, response, error in
            if let _ = error {
                completion(.failure(.sslPinningFailed))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.invalidStatusCode(httpResponse.statusCode)))
                return
            }
            
            guard let data = data, !data.isEmpty else {
                completion(.failure(.emptyData))
                return
            }
            
            if let rawJSON = try? JSONSerialization.jsonObject(with: data, options: []) {
                print("📦 Raw JSON:", rawJSON)
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON String:\n\(jsonString)")
            }
            
            let result = JSONParsing.decode(T.self, from: data)
            
            switch result {
            case .success(let endpoints):
                let user = endpoints as? GitHubAPIEndpoints
                print("✅ Decoded emojisURL:", user?.emojisURL ?? "nil")
            case .failure(let error):
                print("❌ Decoding failed:", error)
            }
            
            completion(result)
        }.resume()
    }
}



enum NetworkError: Error, CustomStringConvertible {
    case invalidURL
    case sslPinningFailed
    case invalidResponse
    case invalidStatusCode(Int)
    case emptyData
    case decodingFailed(Error)
    
    var description: String {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .sslPinningFailed: return "SSL pinning failed"
        case .invalidResponse: return "Invalid response"
        case .invalidStatusCode(let code): return "Unexpected status code: \(code)"
        case .emptyData: return "No data received"
        case .decodingFailed(let error): return "Decoding failed: \(error.localizedDescription)"
        }
    }
}
