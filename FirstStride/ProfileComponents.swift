//
//  ProfileComponents.swift
//  FirstStride
//
//  Created by douglas miranda on 12/1/25.
//

import SwiftUI
import FirebaseAuth

// MARK: HEADER CARD
struct ProfileHeaderCard: View {
    @Binding var image: UIImage?
    @Binding var isUploading: Bool
    var name: String
    var email: String?
    var onImageTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {

            Button { onImageTap() } label: {
                VStack {
                    if let img = image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 120))
                            .foregroundColor(.gray)
                    }

                    if isUploading {
                        ProgressView("Uploading…")
                            .font(.caption)
                    }
                }
            }

            VStack(spacing: 4) {
                Text(name)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(email ?? "")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        )
        .padding(.horizontal)
    }
}

// MARK: SECTION CARD COMPONENT
struct ProfileSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Image(systemName: icon)
                    .foregroundColor(.red)
                    .font(.title2)

                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()
            }

            content
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        )
        .padding(.horizontal)
    }
}
