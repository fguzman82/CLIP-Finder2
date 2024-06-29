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
    @State private var searchText = ""
    @State private var isPreviewActive = false
    @State private var isCameraAuthorized = false
    @FocusState private var isTextFieldFocused: Bool


//    var body: some View {
//        NavigationView {
//            VStack {
//                SearchBar(text: $searchText, onSearch: {
//                    photoGalleryViewModel.processTextSearch(searchText)
//                })
//                .padding()
//                
//                PhotoGalleryView(assets: photoGalleryViewModel.assets, topPhotoIDs: photoGalleryViewModel.topPhotoIDs)
//            }
//            .navigationTitle("Photo Gallery")
//        }
//        .onAppear {
//            photoGalleryViewModel.requestPhotoLibraryAccess()
//        }
//    }
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Enter search text", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isTextFieldFocused)
                        .onChange(of: searchText) { newValue in
                            photoGalleryViewModel.processTextSearch(newValue)
                        }
                    
                    Button(action: {
                        isTextFieldFocused = false
                        if isCameraAuthorized {
                            isPreviewActive = true
                        } else {
                            photoGalleryViewModel.requestCameraAccess { authorized in
                                isCameraAuthorized = authorized
                                if authorized {
                                    isPreviewActive = true
                                }
                            }
                        }
                    }) {
                        Image(systemName: "camera")
                                .foregroundColor(.blue)
                                .frame(width: 44, height: 44)  // Tamaño mínimo recomendado para objetivos táctiles
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Open Camera")
                }
                .padding()
                
                if isPreviewActive {
                    CameraPreviewView(cameraManager: photoGalleryViewModel.cameraManager, photoGalleryViewModel: photoGalleryViewModel, isPreviewActive: $isPreviewActive)
                        .frame(height: 300)
                }
                
                if photoGalleryViewModel.topPhotoIDs.isEmpty {
                    Text("No results found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    PhotoGalleryView(assets: photoGalleryViewModel.assets, topPhotoIDs: photoGalleryViewModel.topPhotoIDs)
                }
            }
            .navigationTitle("CLIP-Finder")
            
        }
        .onAppear {
            photoGalleryViewModel.requestPhotoLibraryAccess()
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var onSearch: () -> Void

    var body: some View {
        HStack {
            TextField("Enter search text", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: onSearch) {
                Text("Search")
            }
        }
    }
}

struct PhotoGalleryView: View {
    let assets: [PHAsset]
    let topPhotoIDs: [String]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 0.1) {
                ForEach(topPhotoIDs, id: \.self) { photoID in
                    if let asset = assets.first(where: { $0.localIdentifier == photoID }) {
                        PhotoGridItemView(asset: asset)
                    }
                }
                .padding(0)
            }
        }
    }
}

//struct PhotoGridItemView: View {
//    let asset: PHAsset
//    @State private var image: UIImage?
//
//    var body: some View {
//        if let image = image {
//            NavigationLink(destination: ImageView(image: image)) {
//                Image(uiImage: image)
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .frame(width: 100, height: 100)
//                    .clipped()
//            }
//        } else {
//            Color.gray
//                .frame(width: 100, height: 100)
//                .onAppear {
//                    loadImage()
//                }
//        }
//    }
//
//    private func loadImage() {
//        let imageManager = PHImageManager.default()
//        let options = PHImageRequestOptions()
//        options.isSynchronous = false
//        options.deliveryMode = .highQualityFormat
//        let targetSize = CGSize(width: 100, height: 100)
//        
//        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { result, _ in
//            if let result = result {
//                image = result
//            }
//        }
//    }
//}
struct PhotoGridItemView: View {
    let asset: PHAsset
    @State private var thumbnailImage: UIImage?

    var body: some View {
        NavigationLink(destination: FullResolutionImageView(asset: asset)) {
            if let image = thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
            } else {
                Color.gray
                    .frame(width: 100, height: 100)
                    .onAppear {
                        loadThumbnailImage()
                    }
            }
        }
    }

    private func loadThumbnailImage() {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.isSynchronous = false
        manager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: option) { image, _ in
            if let image = image {
                self.thumbnailImage = image
            }
        }
    }
}

struct FullResolutionImageView: View {
    let asset: PHAsset
    @State private var image: UIImage?
    @State private var isLoading = true
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                ProgressView()
            } else {
                Text("Failed to load image")
            }
        }
        .navigationTitle("Full Resolution Image")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        })
        .onAppear {
            loadFullResolutionImage()
        }
    }
    
    private func loadFullResolutionImage() {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.deliveryMode = .highQualityFormat
        option.isSynchronous = false
        option.isNetworkAccessAllowed = true
        
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: option) { image, info in
            DispatchQueue.main.async {
                if let image = image {
                    self.image = image
                }
                self.isLoading = false
            }
        }
    }
}

//struct ImageView: View {
//    let image: UIImage
//
//    var body: some View {
//        Image(uiImage: image)
//            .resizable()
//            .aspectRatio(contentMode: .fit)
//            .navigationTitle("Image Viewer")
//            .navigationBarTitleDisplayMode(.inline)
//    }
//}
