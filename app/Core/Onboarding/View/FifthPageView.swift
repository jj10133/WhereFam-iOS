//
//  FifthPageView.swift
//  App
//
//  Created by joker on 2025-01-12.
//

import SwiftUI




struct FifthPageView: View {
    var body: some View {
        VStack {
                    Text("Add a Family Member")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                    
                    Text("Here's how you can add family members to track them in real-time!")
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button(action: {
                        // Show demo or guide to add family member
                    }) {
                        Text("Add Family Member")
                            .font(.title2)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    
                    
//                    NavigationLink(destination: AppreciationView(userName: userName)) {
//                        Text("Got it! Show me more")
//                            .font(.title2)
//                            .foregroundColor(.blue)
//                    }
                }
                .padding()
    }
}

#Preview {
    FifthPageView()
}
