//
//  PostViewModel.swift
//  SSL_TLS_CERT_PINNING
//
//  Created by MD RASHID IQUBAL on 26/10/25.
//

import Foundation

class PostViewModel: ObservableObject {
    
    @Published var userData: GitHubAPIEndpoints?
    
    let manager: NetworkManager
    
    init(manager: NetworkManager) {
        self.manager = manager
    }
    
    func fetchData() {
        manager.get(urlString: "https://api.github.com") { [weak self] (result: Result<GitHubAPIEndpoints, NetworkError>) in
            switch result {
            case .success(let endpoints):
                if let emojisURL = endpoints.emojisURL {
                    print("✅ Success: \(emojisURL)")
                } else {
                    print("⚠️ Success, but emojisURL is nil")
                }
                self?.userData = endpoints
            case .failure(let error):
                print("❌ Error:", error.description)
            }
        }
    }
    
}
