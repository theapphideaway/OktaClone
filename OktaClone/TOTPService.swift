//
//  TOTPService.swift
//  OktaClone
//
//  Created by ian schoenrock on 1/8/26.
//

import Foundation
import CryptoKit

struct HOTP {

   static func generate(secret: Data, counter: UInt64, digits: Int = 6) -> String? {
       // 1. Convert Counter to Big Endian (Network Byte Order)
       // iOS is Little Endian, so we must flip the bytes for the network standard.
       var counterBigEndian = counter.bigEndian
    
       // We use "withUnsafeBytes" to safely read the raw memory of the integer
       let counterData = withUnsafeBytes(of: &counterBigEndian) { Data($0) }
    
       // 2. HMAC-SHA1 Hashing
       // We mix the Secret and the Counter to create a unique hash
       let key = SymmetricKey(data: secret)
       let hash = HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: key)
       
    
       // 3. Dynamic Truncation
       // We extract 4 bytes from the hash to create our integer
       let hashData = Data(hash)
       guard let lastByte = hashData.last else { return nil }
    
       // The last 4 bits of the last byte tell us WHERE to look (the offset)
       let offset = Int(lastByte & 0x0f)
    
       // We use Bitwise Left Shifts (<<) to move bytes into the correct slot
       var truncatedHash: UInt32 = 0
       truncatedHash |= UInt32(hashData[offset]) << 24
       truncatedHash |= UInt32(hashData[offset + 1]) << 16
       truncatedHash |= UInt32(hashData[offset + 2]) << 8
       truncatedHash |= UInt32(hashData[offset + 3])
    
       // 4. Clean up and Modulo
       truncatedHash = truncatedHash & 0x7fffffff // Remove sign bit
       let modulus = UInt32(pow(10.0, Float(digits)))
       let pinValue = truncatedHash % modulus
    
       return String(format: "%0*d", digits, pinValue)
   }
}

struct TOTP {
    static let period: TimeInterval = 30
    
    static func generate(secret: Data, time: Date) -> String? {
        // The TOTP Logic: Convert Time -> Counter
        let secondsPast1970 = time.timeIntervalSince1970
        let counter = UInt64(floor(secondsPast1970 / period))
        
        // Delegate the math to the HOTP Core
        let hotpReturnValue = HOTP.generate(secret: secret, counter: counter)
        return hotpReturnValue
    }
}
