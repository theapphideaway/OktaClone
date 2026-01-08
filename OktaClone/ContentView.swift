//
//  ContentView.swift
//  OktaClone
//
//  Created by ian schoenrock on 1/8/26.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var vm = TokenViewModel()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("\(vm.secondsRemaining)")
            Text("\(vm.code)")
            Text("\(vm.progress)")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
