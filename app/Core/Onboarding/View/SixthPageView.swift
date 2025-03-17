//
//  SixthPageView.swift
//  App
//
//  Created by joker on 2025-01-13.
//

import SwiftUI


struct SixthPageView: View {
    var body: some View {
        VStack {
            Text("You're all set, \(UserDefaults.standard.string(forKey: "userName") ?? "")")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
            
            Text("You can start finding your people and connect with them!")
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding()
        }
        .padding()
    }
}

#Preview {
    SixthPageView()
}
