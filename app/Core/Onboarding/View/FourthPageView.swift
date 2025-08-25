//
//  FourthPageView.swift
//  App
//
//  Created by joker on 2025-01-12.
//

import SwiftUI

struct FourthPageView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "paperplane.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .foregroundColor(.white)
                .padding(.bottom, 32)
            
            
            Text("Would you like to find family and friends nearby?")
                .font(.system(size: 28, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding()
            
            Text("Start sharing your location now")
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .frame(width: 140)
                .padding()
            
            
            
            Button(action: {
                LocationManager.shared.requestLocation()
            }) {
                Text("Continue")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.white)
                    .foregroundColor(Color(UIColor(#colorLiteral(red: 1, green: 0.7349339692, blue: 0.5137254902, alpha: 1))))
                    .cornerRadius(10)
            }
            .padding()
            
            Spacer()
        }
    }
}

#Preview {
    FourthPageView()
}
