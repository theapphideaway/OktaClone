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
    
    // The "Engine" inputs (Hardcoded for this week)
    // We use the test secret from RFC 6238 for now
    private let secret: Data = Data([
        0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30,
        0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30
    ])
    
    private var timer: AnyCancellable?
    
    init() {
        startTimer()
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
