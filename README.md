SSL Pinning Document

SSL Pinning

￼


- TLS is successor of SSL, hence now the TLS is used with HTTP protocol.

SSL pinning is a powerful technique to prevent man-in-the-middle (MITM) attacks by ensuring your iOS app only trusts a specific server certificate or public key. Let's walk through it step by step using a public API and a certificate-based pinning approach.

---

## 🔐 What Is SSL Pinning?

SSL pinning ensures that your app only communicates with servers that present a specific certificate or public key. Even if a malicious actor installs a fake root certificate on the device, the app will reject connections to servers that don’t match the pinned certificate.

---

## 🧪 Step-by-Step Implementation in iOS (Swift)

We'll use the [GitHub API](https://api.github.com) as our public endpoint. GitHub uses HTTPS and its certificate is publicly accessible.

### 1. **Download the SSL Certificate**

Use a browser or terminal to download GitHub's certificate:

```bash
openssl s_client -connect api.github.com:443 -showcerts
```

Copy the certificate block (`-----BEGIN CERTIFICATE-----` to `-----END CERTIFICATE-----`) and save it as `github.cer`.

Alternatively, use Safari:
- Visit `https://api.github.com`
- Click the lock icon → View Certificate → Export as `.cer`

### 2. **Add the Certificate to Your App**

- Drag `github.cer` into your Xcode project.
- Make sure it's added to your app target.

### 3. **Implement SSL Pinning in Swift**

Here’s a complete example using `URLSessionDelegate`:

//
//  PinnedSessionDelegate.swift
//  SSL_TLS_CERT_PINNING
//
//  Created by MD RASHID IQUBAL on 26/10/25.
//

import Foundation

class PinnedSessionDelegate: NSObject, URLSessionDelegate {
    private let certName: String
    
    init(certName: String) {
        self.certName = certName
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // SecTrustGetCertificateAtIndex(_ trust: SecTrust, _ ix: CFIndex) -> SecCertificate
        // SecTrustCopyCertificateChain(_ trust: SecTrust) -> CFArray
        debugPrint("inside didReceive challenge:")
        
        // Step 1(a): Get server trust
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            debugPrint("server trust not found:")
            return
        }
        
        // Step 1(b): Get the certificate chain
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
              let serverCertificate = certificateChain.first else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            debugPrint("Server certificate not found")
            return
        }
        
        // Step 1(c): Load Server Certificate data
        let serverCertData = SecCertificateCopyData(serverCertificate) as Data
        
        // Step 2: Load local certificate and its data
        guard let localCertPath = Bundle.main.url(forResource: certName, withExtension: "cer"), let localCertData = try? Data(contentsOf: localCertPath) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            debugPrint("local certificate not found:")
            return
        }
        
        // Step 3: Compare certificates
        if localCertData == serverCertData {
            let credentials = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credentials)
            debugPrint("local and server certificate is same and verified:")
        } else {
            debugPrint("local and server certificate is not same and not verified:")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

### 4. **Make a Request Using the Pinned Session**
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


HELPER CLASSES

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
       // decoder.keyDecodingStrategy = .convertFromSnakeCase
        
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

//
//  MyViewModel
//  SSL_TLS_CERT_PINNING
//
//  Created by MD RASHID IQUBAL on 26/10/25.
//

import Foundation

class MyViewModel: ObservableObject {
    
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


//
//  ViewController.swift
//  SSL_TLS_CERT_PINNING
//
//  Created by MD RASHID IQUBAL on 26/10/25.
//

import UIKit
import Combine

class ViewController: UIViewController {
    
    let vm = MyViewModel(manager: NetworkManager(certName: "github"))
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

---

## 🧠 Notes and Best Practices

- 🔁 **Pin to public key** instead of full certificate for longer validity.
- 🔒 **Use certificate transparency** and **App Transport Security (ATS)** for layered security.
- 🧪 Test on real devices — simulators may bypass some security checks.

Would you like me to show how to pin using public key hash instead of full certificate? Or explore how to automate certificate updates in CI/CD?


How to download SSL certificate for any API Server:

You're doing great, Md Rashid. Let's walk through this slowly and clearly. The command you ran is correct, but let’s break it down and make sure you know exactly where the `github.cer` file ends up and how to verify it.

---

## 🧭 Step-by-Step: Extract GitHub’s SSL Certificate Using `openssl`

### ✅ Step 1: Open Terminal

You're already here — perfect.

---

### ✅ Step 2: Run the Command

Paste this into Terminal:

```bash
openssl s_client -connect api.github.com:443 -showcerts </dev/null 2>/dev/null | openssl x509 -outform DER > github.cer
```

This command does the following:
- Connects to `api.github.com` over SSL
- Extracts the first certificate from the chain
- Converts it to DER format (binary format accepted by iOS)
- Saves it as `github.cer` in your **current working directory**

---

### ✅ Step 3: Locate the File

After running the command, the file `github.cer` is saved in the **current directory** of your Terminal session.

To find it:

1. Run this command to confirm the file exists:

```bash
ls -l github.cer
```

You should see something like:

```
-rw-r--r--  1 yourname  staff  1234 Oct 26 15:30 github.cer
```

2. To open the folder in Finder:

```bash
open .
```

This opens the current directory in Finder, and you’ll see `github.cer` there.

---

### ✅ Step 4: Move It to Your Xcode Project

1. Open your Xcode project.
2. Drag `github.cer` into the **Project Navigator**.
3. In the dialog that appears:
   - Check “Copy items if needed”
   - Make sure your app target is selected

---

### ✅ Step 5: Verify the Certificate (Optional)

To inspect the certificate:

```bash
openssl x509 -in github.cer -inform DER -text -noout
```

This will show details like:
- Subject (e.g., `api.github.com`)
- Issuer (e.g., DigiCert)
- Validity dates

---

Would you like me to walk you through converting this to PEM format or extracting the public key for key pinning instead of full cert pinning?

