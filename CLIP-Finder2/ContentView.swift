//
//  ContentView.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 24/06/24.
//

import SwiftUI
import Photos

//struct ContentView: View {
//    @StateObject private var photoGalleryViewModel = PhotoGalleryViewModel()
//    @State private var searchText = ""
//    @State private var isPreviewActive = false
//    @State private var isCameraAuthorized = false
//    @FocusState private var isTextFieldFocused: Bool
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                VStack {
//                    HStack {
//                        TextField("Enter search text", text: $searchText)
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                            .focused($isTextFieldFocused)
//                            .onChange(of: searchText) { newValue in
//                                photoGalleryViewModel.processTextSearch(newValue)
//                            }
//                        
//                        Button(action: {
//                            isTextFieldFocused = false
//                            if isCameraAuthorized {
//                                isPreviewActive = true
//                            } else {
//                                photoGalleryViewModel.requestCameraAccess { authorized in
//                                    isCameraAuthorized = authorized
//                                    if authorized {
//                                        isPreviewActive = true
//                                    }
//                                }
//                            }
//                        }) {
//                            Image(systemName: "camera")
//                                .foregroundColor(.blue)
//                                .frame(width: 44, height: 44)
//                                .contentShape(Rectangle())
//                        }
//                        .accessibilityLabel("Open Camera")
//                    }
//                    .padding()
//                    
//                    if photoGalleryViewModel.topPhotoIDs.isEmpty {
//                        Text("No results found")
//                            .foregroundColor(.secondary)
//                            .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    } else {
//                        PhotoGalleryView(assets: photoGalleryViewModel.assets, topPhotoIDs: photoGalleryViewModel.topPhotoIDs)
//                    }
//                }
//                
//                if isPreviewActive {
//                    Color.black.opacity(0.01)  // Fondo transparente para detectar toques
//                        .edgesIgnoringSafeArea(.all)
//                        .onTapGesture {
//                            isPreviewActive = false
//                            photoGalleryViewModel.stopCamera()
//                        }
//                    
//                    CameraPreviewView(cameraManager: photoGalleryViewModel.cameraManager, photoGalleryViewModel: photoGalleryViewModel, isPreviewActive: $isPreviewActive)
//                        .frame(height: 300)
//                        .position(x: UIScreen.main.bounds.width / 2, y: 150)
//                }
//            }
//            .navigationTitle("CLIP-Finder")
//        }
//        .onAppear {
//            photoGalleryViewModel.requestPhotoLibraryAccess()
//        }
//        .onTapGesture {
//            isTextFieldFocused = false
//        }
//    }
//}

//struct ContentView: View {
//    @StateObject private var photoGalleryViewModel = PhotoGalleryViewModel()
//    @State private var searchText = ""
//    @State private var isPreviewActive = false
//    @State private var isCameraAuthorized = false
//    @FocusState private var isTextFieldFocused: Bool
//    @State private var orientation = UIDeviceOrientation.unknown
//    @State private var previousOrientation = UIDeviceOrientation.unknown
//
//    
//    var body: some View {
//        NavigationView {
//            GeometryReader { geometry in
//                VStack {
//                    HStack {
//                        TextField("Enter search text", text: $searchText)
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                            .focused($isTextFieldFocused)
//                            .onChange(of: searchText) { newValue in
//                                photoGalleryViewModel.processTextSearch(newValue)
//                            }
//                        
//                        Button(action: {
//                            isTextFieldFocused = false
//                            if isCameraAuthorized {
//                                isPreviewActive = true
//                            } else {
//                                photoGalleryViewModel.requestCameraAccess { authorized in
//                                    isCameraAuthorized = authorized
//                                    if authorized {
//                                        isPreviewActive = true
//                                    }
//                                }
//                            }
//                        }) {
//                            Image(systemName: "camera")
//                                .foregroundColor(.blue)
//                                .frame(width: 44, height: 44)
//                                .contentShape(Rectangle())
//                        }
//                        .accessibilityLabel("Open Camera")
//                    }
//                    .padding()
//                    
//                    if orientation.isLandscape {
//                        HStack {
////                            if isPreviewActive {
////                                CameraPreviewView(cameraManager: photoGalleryViewModel.cameraManager, photoGalleryViewModel: photoGalleryViewModel, isPreviewActive: $isPreviewActive, orientation: $orientation)
////                                    .frame(width: geometry.size.width * 0.4)
////                            }
//                            if isPreviewActive {
//                                CameraPreviewView(photoGalleryViewModel: photoGalleryViewModel, isPreviewActive: $isPreviewActive, orientation: $orientation)
//                                    .frame(width: geometry.size.width * 0.4)
//                            }
//                            
//                            if photoGalleryViewModel.topPhotoIDs.isEmpty {
//                                Text("No results found")
//                                    .foregroundColor(.secondary)
//                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                            } else {
//                                PhotoGalleryView(assets: photoGalleryViewModel.assets, topPhotoIDs: photoGalleryViewModel.topPhotoIDs, columns: isPreviewActive ? 4 : 7)
//                            }
//                        }
//                    } else {
////                        if isPreviewActive {
////                            CameraPreviewView(cameraManager: photoGalleryViewModel.cameraManager, photoGalleryViewModel: photoGalleryViewModel, isPreviewActive: $isPreviewActive, orientation: $orientation)
////                                .frame(height: 300)
////                        }
//                        if isPreviewActive {
//                            CameraPreviewView(photoGalleryViewModel: photoGalleryViewModel, isPreviewActive: $isPreviewActive, orientation: $orientation)
//                                .frame(height: 300)
//                        }
//                        
//                        if photoGalleryViewModel.topPhotoIDs.isEmpty {
//                            Text("No results found")
//                                .foregroundColor(.secondary)
//                                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        } else {
//                            PhotoGalleryView(assets: photoGalleryViewModel.assets, topPhotoIDs: photoGalleryViewModel.topPhotoIDs, columns: 4)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("CLIP-Finder")
//        }
//        .onAppear {
//            photoGalleryViewModel.requestPhotoLibraryAccess()
//            previousOrientation = UIDevice.current.orientation
//        }
//        .onRotate { newOrientation in
//            let oldOrientation = orientation
//            orientation = newOrientation
//            
//            if isPreviewActive && orientationChanged(from: oldOrientation, to: newOrientation) {
//                isPreviewActive = false
//                photoGalleryViewModel.stopCamera()
//            }
//        }
//        .onTapGesture {
//            isTextFieldFocused = false
//        }
//    }
//    private func orientationChanged(from oldOrientation: UIDeviceOrientation, to newOrientation: UIDeviceOrientation) -> Bool {
//        let oldIsLandscape = oldOrientation.isLandscape
//        let newIsLandscape = newOrientation.isLandscape
//        return oldIsLandscape != newIsLandscape
//    }
//}

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
                ZStack {
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
                                    PhotoGalleryView(assets: photoGalleryViewModel.assets, topPhotoIDs: photoGalleryViewModel.topPhotoIDs, columns: isPreviewActive ? 4 : 7)
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
                                PhotoGalleryView(assets: photoGalleryViewModel.assets, topPhotoIDs: photoGalleryViewModel.topPhotoIDs, columns: 4)
                            }
                        }
                        
                        if photoGalleryViewModel.isProcessing {
                            VStack {
                                ProgressView(value: photoGalleryViewModel.processingProgress) {
                                    Text("Processing Photos: \(photoGalleryViewModel.processedPhotosCount)/\(photoGalleryViewModel.totalPhotosCount)")
                                }
                                .progressViewStyle(LinearProgressViewStyle())
                                .padding()
                            }
                        }
                        
                    }
                    
//                    if isPreviewActive {
//                        Color.black.opacity(0.01)  // Fondo transparente para detectar toques
//                            .edgesIgnoringSafeArea(.all)
//                            .onTapGesture {
//                                photoGalleryViewModel.stopCamera()
//                                isPreviewActive = false
//                            }
//                    }
                }
            }
            .navigationTitle("CLIP-Finder")
            .toolbar {
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

// Extensión para detectar la rotación del dispositivo
extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

// Modificador para detectar la rotación del dispositivo
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

// Extensión para comprobar si la orientación es horizontal
extension UIDeviceOrientation {
    var isLandscape: Bool {
        return self == .landscapeLeft || self == .landscapeRight
    }
}

//    var body: some View {
//        NavigationView {
//            VStack {
//                HStack {
//                    TextField("Enter search text", text: $searchText)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .focused($isTextFieldFocused)
//                        .onChange(of: searchText) { newValue in
//                            photoGalleryViewModel.processTextSearch(newValue)
//                        }
//                    
//                    Button(action: {
//                        isTextFieldFocused = false
//                        if isCameraAuthorized {
//                            isPreviewActive = true
//                        } else {
//                            photoGalleryViewModel.requestCameraAccess { authorized in
//                                isCameraAuthorized = authorized
//                                if authorized {
//                                    isPreviewActive = true
//                                }
//                            }
//                        }
//                    }) {
//                        Image(systemName: "camera")
//                                .foregroundColor(.blue)
//                                .frame(width: 44, height: 44)  // Tamaño mínimo recomendado para objetivos táctiles
//                                .contentShape(Rectangle())
//                        }
//                        .accessibilityLabel("Open Camera")
//                }
//                .padding()
//                
//                if isPreviewActive {
//                    CameraPreviewView(cameraManager: photoGalleryViewModel.cameraManager, photoGalleryViewModel: photoGalleryViewModel, isPreviewActive: $isPreviewActive)
//                        .frame(height: 300)
//                }
//                
//                if photoGalleryViewModel.topPhotoIDs.isEmpty {
//                    Text("No results found")
//                        .foregroundColor(.secondary)
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                } else {
//                    PhotoGalleryView(assets: photoGalleryViewModel.assets, topPhotoIDs: photoGalleryViewModel.topPhotoIDs)
//                }
//            }
//            .navigationTitle("CLIP-Finder")
//            
//        }
//        .onAppear {
//            photoGalleryViewModel.requestPhotoLibraryAccess()
//        }
//        .onTapGesture {
//            isTextFieldFocused = false
//        }
//    }
//}

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

//struct PhotoGalleryView: View {
//    let assets: [PHAsset]
//    let topPhotoIDs: [String]
//
//    var body: some View {
//        ScrollView {
//            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 0.1) {
//                ForEach(topPhotoIDs, id: \.self) { photoID in
//                    if let asset = assets.first(where: { $0.localIdentifier == photoID }) {
//                        PhotoGridItemView(asset: asset)
//                    }
//                }
//                .padding(0)
//            }
//        }
//    }
//}

struct PhotoGalleryView: View {
    let assets: [PHAsset]
    let topPhotoIDs: [String]
    let columns: Int

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: columns), spacing: 0.1) {
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
