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
    @State private var orientation = UIDeviceOrientation.unknown
    @State private var previousOrientation = UIDeviceOrientation.unknown
    @State private var showingSettings = false
    

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    if photoGalleryViewModel.isGalleryEmpty {
                        Text("Your photo gallery is empty. Add some photos to use CLIP-Finder.")
                        .padding()
                    } else {
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
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .accessibilityLabel("Open Camera")
                        }
                        .padding()
                        
                        if orientation.isLandscape {
                            HStack {
                                if isPreviewActive {
                                    CameraPreviewView(photoGalleryViewModel: photoGalleryViewModel, isPreviewActive: $isPreviewActive, orientation: $orientation)
                                        .frame(width: geometry.size.width * 0.4)
                                }
                                
                                if photoGalleryViewModel.topPhotoIDs.isEmpty {
                                    Text("No results found")
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                } else {
                                    PhotoGalleryView(assetsByID: photoGalleryViewModel.assetsByID, topPhotoIDs: photoGalleryViewModel.topPhotoIDs, columns: isPreviewActive ? 4 : 7)
                                }
                            }
                        } else {
                            if isPreviewActive {
                                CameraPreviewView(photoGalleryViewModel: photoGalleryViewModel, isPreviewActive: $isPreviewActive, orientation: $orientation)
                                    .frame(height: 300)
                            }
                            
                            if photoGalleryViewModel.topPhotoIDs.isEmpty {
                                Text("No results found")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                PhotoGalleryView(assetsByID: photoGalleryViewModel.assetsByID, topPhotoIDs: photoGalleryViewModel.topPhotoIDs, columns: 4)
                            }
                        }
                        
                        if photoGalleryViewModel.isProcessing {
                            VStack {
                                ProgressView(value: photoGalleryViewModel.processingProgress) {
                                    Text("Preprocessing Photos (first launch only):")
                                    Text("\(photoGalleryViewModel.processedPhotosCount)/\(photoGalleryViewModel.totalPhotosCount)")
                                }
                                .progressViewStyle(LinearProgressViewStyle())
                                .padding()
                            }
                        }
                    }
                    
                }
            }
            .navigationTitle("CLIP-Finder")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    FilteredPhotoCountSelector(viewModel: photoGalleryViewModel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(photoGalleryViewModel: photoGalleryViewModel)
            }
        }
        .onAppear {
            photoGalleryViewModel.requestPhotoLibraryAccess()
            previousOrientation = UIDevice.current.orientation
        }
        .onRotate { newOrientation in
            let oldOrientation = orientation
            orientation = newOrientation
            
            if orientationChanged(from: oldOrientation, to: newOrientation) {
                isPreviewActive = false
//                photoGalleryViewModel.stopCamera()
            }
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
        .onChange(of: photoGalleryViewModel.isCameraActive) { newValue in
            if !newValue {
                isPreviewActive = false
            }
        }
    }

    private func orientationChanged(from oldOrientation: UIDeviceOrientation, to newOrientation: UIDeviceOrientation) -> Bool {
        let oldIsLandscape = oldOrientation.isLandscape
        let newIsLandscape = newOrientation.isLandscape
        return oldIsLandscape != newIsLandscape
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

extension UIDeviceOrientation {
    var isLandscape: Bool {
        return self == .landscapeLeft || self == .landscapeRight
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
    let assetsByID: [String: PHAsset]
    let topPhotoIDs: [String]
    let columns: Int

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: columns), spacing: 0.1) {
                ForEach(Array(topPhotoIDs.enumerated()), id: \.element) { index, photoID in
                    if let asset = assetsByID[photoID] {
                        PhotoGridItemView(asset: asset,
                                          index: index,
                                          photoIDs: topPhotoIDs,
                                          assetsByID: assetsByID)
                    }
                }
                .padding(0)
            }
        }
    }
}

struct PhotoGridItemView: View {
    let asset: PHAsset
    let index: Int
    let photoIDs: [String]
    let assetsByID: [String: PHAsset]
    @State private var thumbnailImage: UIImage?

    var body: some View {
        NavigationLink(destination: FullResolutionImageView(photoIDs: photoIDs, initialIndex: index, assetsByID: assetsByID)) {
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
    let photoIDs: [String]
    let initialIndex: Int
    let assetsByID: [String: PHAsset]
    @State private var currentIndex: Int
    @State private var currentImage: UIImage?
    @Environment(\.presentationMode) var presentationMode

    init(photoIDs: [String], initialIndex: Int, assetsByID: [String: PHAsset]) {
        self.photoIDs = photoIDs
        self.initialIndex = initialIndex
        self.assetsByID = assetsByID
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(photoIDs.indices, id: \.self) { index in
                if let asset = assetsByID[photoIDs[index]] {
                    SingleImageView(asset: asset, onImageLoaded: { image in
                        if index == currentIndex {
                            currentImage = image
                        }
                    })
                    .tag(index)
                }
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton, trailing: shareButton)
    }

    private var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        }
    }

    private var shareButton: some View {
        Button(action: shareImage) {
            Image(systemName: "square.and.arrow.up")
        }
    }

    private func shareImage() {
        guard let image = currentImage else { return }
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityViewController, animated: true, completion: nil)
        }
    }
}

struct SingleImageView: View {
    let asset: PHAsset
    let onImageLoaded: (UIImage) -> Void
    @State private var image: UIImage?
    @State private var isLoading = true

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
        .onAppear(perform: loadFullResolutionImage)
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
                    self.onImageLoaded(image)
                }
                self.isLoading = false
            }
        }
    }
}



struct FilteredPhotoCountSelector: View {
    @ObservedObject var viewModel: PhotoGalleryViewModel
    
    var body: some View {
        Menu {
            Text("Top Results to Display")
                .font(.headline)
            
            Divider()
            
            ForEach([50, 100, 200, 500, 1000], id: \.self) { count in
                Button(action: {
                    viewModel.updateFilteredPhotoCount(count)
                }) {
                    Text("\(count)")
                    if count > viewModel.assets.count {
                        Text("(All)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "photo.stack")
                Text("Top \(viewModel.numberOfFilteredPhotos)")
                if viewModel.numberOfFilteredPhotos >= viewModel.assets.count {
                    Text("(All)")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
