//
//  SupportAppView.swift
//  App
//
//  Created by joker on 2025-08-01.
//

import SwiftUI
import RevenueCat

struct SupportAppView: View {
    var body: some View {
        NavigationStack {
            Form {
                aboutSection
            }
        }
        .navigationTitle("Support App")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var aboutSection: some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 18) {
                    Text("Hi there!! My name is JJ and I love FOSS. WhereFam is one of my projects that i'm really proud about since everything made is P2P, from maps to location sharing therefore data's on device only. Let's be real I need to maintain the app, have to pay bills to make a living. If you're having a blast using WherFam, consider tossing a little tip. It'll make my day 🚀")
                }
            }
        }
    }
    
}

#Preview {
    SupportAppView()
}
