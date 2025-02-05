//
//  SixthPageView.swift
//  App
//
//  Created by joker on 2025-01-13.
//

import SwiftUI


struct SixthPageView: View {
//    @Environment(\.requestReview) var requestReview
    var body: some View {
        VStack {
            Text("You're all set, User!")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            Text("You can start tracking your loved ones and connect with them!")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
            //                    NavigationLink(destination: RatingRequestView()) {
            //                        Text("Leave a rating to help us improve!")
            //                            .font(.title2)
            //                            .foregroundColor(.blue)
            //                            .padding()
            //                    }
        }
        .padding()
        .onAppear {
            
        }
    }
}

#Preview {
    SixthPageView()
}
