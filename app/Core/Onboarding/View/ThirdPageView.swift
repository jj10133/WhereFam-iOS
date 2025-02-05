//
//  SecondPageView.swift
//  App
//
//  Created by joker on 2025-01-12.
//

import SwiftUI
import PhotosUI

struct ThirdPageView: View {
    @AppStorage("userImageData") var userImageData: String?

    @State private var userImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    
    
    var body: some View {
        VStack {
            
            Text("Ready to add your photo?")
                .font(.title)
                .fontWeight(.bold)
                .padding()
                .foregroundColor(Color(UIColor(#colorLiteral(red: 1, green: 0.7349339692, blue: 0.5137254902, alpha: 1))))
            
            
            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if let avatarImage = userImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color(UIColor(#colorLiteral(red: 1, green: 0.7349339692, blue: 0.5137254902, alpha: 1))), lineWidth: 2)
                            )
                            .padding()
                    } else {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                            .foregroundColor(Color(UIColor(#colorLiteral(red: 1, green: 0.7349339692, blue: 0.5137254902, alpha: 1))))
                            .overlay(
                                Circle()
                                    .stroke(Color(UIColor(#colorLiteral(red: 1, green: 0.7349339692, blue: 0.5137254902, alpha: 1))), lineWidth: 1)
                            )
                            .padding()
                    }
                    
                    
                    if userImage == nil {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .background(Color(UIColor(#colorLiteral(red: 1, green: 0.7349339692, blue: 0.5137254902, alpha: 1))))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color(UIColor(#colorLiteral(red: 1, green: 0.7349339692, blue: 0.5137254902, alpha: 1))), lineWidth: 1)
                            )
                            .padding(8)
                    }
                }
            }
            .padding()
        }
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                if let photosPickerItem = newItem,
                   let data = try? await photosPickerItem.loadTransferable(type: Data.self) {
                    if let image = UIImage(data: data) {
                        userImage = image
                        userImageData = data.base64EncodedString()
                    }
                }
            }
        }
    }
}




#Preview {
    ThirdPageView()
}
