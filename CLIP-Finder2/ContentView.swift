//
//  ContentView.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 24/06/24.
//

import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var photoGalleryViewModel = PhotoGalleryViewModel()

    var body: some View {
        NavigationView {
            PhotoGalleryView(assets: photoGalleryViewModel.assets)
                .navigationTitle("Photo Gallery")
        }
        .onAppear {
            photoGalleryViewModel.requestPhotoLibraryAccess()
        }
    }
}

struct PhotoGalleryView: View {
    let assets: [PHAsset]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 2) {
                ForEach(assets, id: \.localIdentifier) { asset in
                    PhotoGridItemView(asset: asset)
                }
            }
        }
    }
}

struct PhotoGridItemView: View {
    let asset: PHAsset
    @State private var image: UIImage?

    var body: some View {
        if let image = image {
            NavigationLink(destination: ImageView(image: image)) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
            }
        } else {
            Color.gray
                .frame(width: 100, height: 100)
                .onAppear {
                    loadImage()
                }
        }
    }

    private func loadImage() {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        let targetSize = CGSize(width: 100, height: 100)
        
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { result, _ in
            if let result = result {
                image = result
            }
        }
    }
}

struct ImageView: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .navigationTitle("Image Viewer")
            .navigationBarTitleDisplayMode(.inline)
    }
}
