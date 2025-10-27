//
//  ViewController.swift
//  SSL_TLS_CERT_PINNING
//
//  Created by MD RASHID IQUBAL on 26/10/25.
//

import UIKit
import Combine

class ViewController: UIViewController {
    
    let vm = PostViewModel(manager: NetworkManager(certName: "github"))
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        debugPrint(#function)
        vm.fetchData()
        
        // how to observe viewmodel user-data
        vm.$userData
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    debugPrint("finished successfully")
                case .failure(let failError):
                    debugPrint("failure error: \(failError)")
                }
            } receiveValue: { [weak self] user in
                guard self != nil else { return }
                if let data = user {
                    print("✅ Received userData:", data.emojisURL ?? "No emojisURL")
                    debugPrint(data)
                    // Update UI here
                } else {
                    print("⚠️ userData is nil")
                }
            }
            .store(in: &cancellables)
        
    }
}

