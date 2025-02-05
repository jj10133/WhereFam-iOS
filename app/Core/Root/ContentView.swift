//
//  ContentView.swift
//  App
//
//  Created by joker on 2025-01-13.
//

import SwiftUI
import ConcentricOnboarding

struct ContentView: View {
    
    var body: some View {
        Group {
//                ConcentricOnboardingView(pageContents:
//                                            [ (AnyView(FirstPageView()), Color(UIColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)))),
//                                              (AnyView(SecondPageView()), Color(UIColor(#colorLiteral(red: 1, green: 0.7349339692, blue: 0.5137254902, alpha: 1)))),
//                                              (AnyView(ThirdPageView()), Color(UIColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)))),
//                                              (AnyView(FourthPageView()), Color(UIColor(#colorLiteral(red: 1, green: 0.7349339692, blue: 0.5137254902, alpha: 1)))),
//                                              (AnyView(FifthPageView()), Color(UIColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)))),
//                                              (AnyView(SixthPageView()), Color(UIColor(#colorLiteral(red: 1, green: 0.7333333333, blue: 0.5137254902, alpha: 1))))
//                                            ])
//                .nextIcon("chevron.right")
                
            
            HomeView()

            
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(IPC())
}
