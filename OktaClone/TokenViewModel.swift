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
    @Published var hasToken: Bool = false
    
    private var secret: Data?
    
    private var timer: AnyCancellable?
    
    init() {
        reset()
        
        loadSecret()
        startTimer()
    }
    
    func handleScan(code: String) {
        // Use your Parser!
        guard let token = OTPParser.parse(uri: code) else {
            print("❌ Invalid QR Code")
            return
        }
        
        // Save the real secret
        print("✅ Scanned: \(token.label)")
        try? KeychainManager.save(key: token.secret)
        
        // Reload
        self.secret = token.secret
        update()
    }
    
    func loadSecret() {
        do {
            // Try to read from Keychain
            self.secret = try KeychainManager.read()
            self.hasToken = true
            print("Success: Loaded secret from Keychain")
        } catch {
            print("Keychain Empty or Error: \(error)")
            print("No secret found. Waiting for user to scan.")
            self.hasToken = false
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
    
    func reset() {
        try? KeychainManager.delete()
        self.secret = nil
        self.hasToken = false
        self.timer?.cancel()
        self.code = "--- ---"
    }
    
}
