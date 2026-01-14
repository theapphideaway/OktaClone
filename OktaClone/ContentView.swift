//
//  ContentView.swift
//  OktaClone
//
//  Created by ian schoenrock on 1/8/26.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var vm = TokenViewModel()
    @State private var isScanning = false
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("\(vm.secondsRemaining)")
            Text("\(vm.code)")
            Text("\(vm.progress)")
            Button(action: { isScanning = true }) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .sheet(isPresented: $isScanning) {
                    QRScannerView { code in
                        // When code is found:
                        vm.handleScan(code: code)
                        isScanning = false // Close sheet
                    }
                }
    }
}

#Preview {
    ContentView()
}
