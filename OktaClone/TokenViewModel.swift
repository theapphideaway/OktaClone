//
//  TokenViewModel.swift
//  OktaClone
//
//  Created by ian schoenrock on 1/8/26.
//

import SwiftUI
import Combine

class TokenViewModel: ObservableObject {
    
    // The visual outputs
    @Published var code: String = "--- ---"
    @Published var progress: Double = 1.0
    @Published var secondsRemaining: Int = 30
    
    private var secret: Data?
    
    private var timer: AnyCancellable?
    
    init() {
        loadSecret()
        startTimer()
    }
    
    func loadSecret() {
        do {
            // Try to read from Keychain
            self.secret = try KeychainManager.read()
            print("Success: Loaded secret from Keychain")
        } catch {
            print("Keychain Empty or Error: \(error)")
            // For testing only: Generate a random key and save it
            // In the real app, this will come from the QR Code
            let testSecret = Data("12345678901234567890".utf8)
            try? KeychainManager.save(key: testSecret)
            self.secret = testSecret
            print("Saved new test secret to Keychain")
        }
    }
    
    func startTimer() {
        // We tick every 0.1 seconds for smooth animation
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.update()
            }
    }
    
    private func update() {
        let now = Date()
        let period: TimeInterval = 30
        
        guard let secret = secret else { return }
        
        // 1. Generate the Code
        if let newCode = TOTP.generate(secret: secret, time: now) {
            // Format it nicely (123 456)
            let firstChunk = newCode.prefix(3)
            let lastChunk = newCode.suffix(3)
            self.code = "\(firstChunk) \(lastChunk)"
        }
        
        // 2. Calculate Progress 
        let timeSinceEpoch = now.timeIntervalSince1970
        let remainder = timeSinceEpoch.truncatingRemainder(dividingBy: period)
        
        // Countdown: 30 minus how far we are
        let remaining = period - remainder
        
        self.secondsRemaining = Int(ceil(remaining))
        self.progress = remaining / period
    }
    
    
}
