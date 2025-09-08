//
//  ThirdPageView.swift
//  App
//
//  Created by joker on 2025-01-12.
//

import SwiftUI

struct SecondPageView: View {
    @AppStorage("userName") var userName: String = ""
    
    var body: some View {
        
        VStack {
            Text("What's your name?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
            
            
            TextField("Enter your name", text: $userName)
                .padding(.horizontal)
                .frame(height: 50)
                .background(Color(.systemBackground))
                .foregroundColor(.primary)
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(.white, lineWidth: 2)
                )
                .padding(.horizontal)
            
        }
        .padding()
    }
}

#Preview {
    SecondPageView()
}
