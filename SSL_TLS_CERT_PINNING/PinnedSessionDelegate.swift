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
