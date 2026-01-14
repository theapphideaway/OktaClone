//
//  OTPParser.swift
//  OktaClone
//
//  Created by ian schoenrock on 1/14/26.
//

import Foundation

struct OTPToken {
    let label: String
    let issuer: String
    let secret: Data
}

struct OTPParser {
    static func parse(uri: String) -> OTPToken? {
        guard let url = URL(string: uri),
              // this is the standard scheme
              url.scheme == "otpauth",
              url.host == "totp" else {
            print("❌ Invalid Scheme or Type. Only 'otpauth://totp' is supported.")
            return nil
        }
        
        // 1. Extract Label
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let label = path
        
        // 2. Extract Parameters
        // We need 'secret' and optional 'issuer'
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        // 3. Find the Secret String
        guard let secretString = queryItems.first(where: { $0.name == "secret" })?.value else {
            print("❌ Missing Secret Parameter")
            return nil
        }
        
        // 4. Decode Base32 (The Hard Part)
        guard let secretData = base32Decode(secretString) else {
            print("❌ Failed to decode Base32 secret")
            return nil
        }
        
        // 5. Find Issuer (Optional, default to label)
        let issuer = queryItems.first(where: { $0.name == "issuer" })?.value ?? label
        
        return OTPToken(label: label, issuer: issuer, secret: secretData)
    }
}

// --- BASE32 HELPER (Standard implementation) ---
// This converts the alphabet "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567" back into bytes
private func base32Decode(_ string: String) -> Data? {
    let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    var bits = 0
    var value = 0
    var data = Data()
    
    for char in string.uppercased() {
        guard let index = alphabet.firstIndex(of: char) else { continue }
        let val = alphabet.distance(from: alphabet.startIndex, to: index)
        
        value = (value << 5) | val
        bits += 5
        
        if bits >= 8 {
            let byte = UInt8((value >> (bits - 8)) & 0xFF)
            data.append(byte)
            bits -= 8
        }
    }
    return data
}
