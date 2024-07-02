//
//  CameraPreviewView.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 28/06/24.
//

import SwiftUI
import AVFoundation

//struct CameraPreviewView: View {
//    @ObservedObject var cameraManager: CameraManager
//    @Binding var isPreviewActive: Bool
//
//    var body: some View {
//        ZStack {
//            CameraPreview(session: cameraManager.session)
//                .overlay(
//                    HStack {
//                        Button(action: { isPreviewActive = false }) {
//                            Image(systemName: "xmark.circle")
//                                .foregroundColor(.white)
//                                .padding()
//                        }
//                        Spacer()
//                        Button(action: cameraManager.switchCamera) {
//                            Image(systemName: "camera.rotate")
//                                .foregroundColor(.white)
//                                .padding()
//                        }
//                    }.padding(),
//                    alignment: .top
//                )
//                .gesture(
//                    DragGesture(minimumDistance: 0)
//                        .onEnded { value in
//                            let viewSize = CGSize(width: UIScreen.main.bounds.width, height: 300)
//                            let pointOfInterest = CGPoint(x: value.location.x / viewSize.width,
//                                                          y: value.location.y / viewSize.height)
//                            cameraManager.focusAtPoint(pointOfInterest)
//                        }
//                )
//        }
//        .onAppear {
//            cameraManager.startRunning()
//        }
//        .onDisappear {
//            cameraManager.stopRunning()
//        }
//    }
//}

//struct CameraPreviewView: View {
//    @ObservedObject var cameraManager: CameraManager
//    @ObservedObject var photoGalleryViewModel: PhotoGalleryViewModel
//    @Binding var isPreviewActive: Bool
//    @State private var focusPoint: CGPoint?
//    @State private var showFocusCircle = false
//
//    var body: some View {
//        ZStack {
//            CameraPreview(session: cameraManager.session) { location in
//                let viewSize = CGSize(width: UIScreen.main.bounds.width, height: 300)
//                let pointOfInterest = CGPoint(x: location.x / viewSize.width,
//                                              y: location.y / viewSize.height)
//                cameraManager.focusAtPoint(pointOfInterest)
//                
//                focusPoint = location
//                showFocusCircle = true
//                
//                // Ocultar el círculo después de 1 segundo
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    showFocusCircle = false
//                }
//            }
//            .overlay(
//                ZStack {
//                    // Controles de cámara
//                    VStack {
//                        HStack {
//                            CameraButton(action: { isPreviewActive = false }, imageName: "xmark")
//                            Spacer()
//                            CameraButton(action: cameraManager.switchCamera, imageName: "arrow.triangle.2.circlepath")
//                        }
//                        .padding(.horizontal)
//                        .padding(.top)
//                        
//                        Spacer()
//                    }
//                    
//                    // Círculo de enfoque
//                    if showFocusCircle, let point = focusPoint {
//                        FocusCircleView(point: point)
//                    }
//                }
//            )
//        }
//        .onAppear {
//            photoGalleryViewModel.startCamera()
//        }
//        .onDisappear {
//            photoGalleryViewModel.stopCamera()
//        }
//    }
//}

//struct CameraPreviewView: View {
//    @ObservedObject var cameraManager: CameraManager
//    @ObservedObject var photoGalleryViewModel: PhotoGalleryViewModel
//    @Binding var isPreviewActive: Bool
//    @Binding var orientation: UIDeviceOrientation
//    @State private var focusPoint: CGPoint?
//    @State private var showFocusCircle = false
//
//    var body: some View {
//        ZStack {
//            CameraPreview(session: cameraManager.session, orientation: $orientation) { location in
//                let viewSize = orientation.isLandscape ? CGSize(width: 300, height: UIScreen.main.bounds.height) : CGSize(width: UIScreen.main.bounds.width, height: 300)
//                let pointOfInterest = CGPoint(x: location.x / viewSize.width,
//                                              y: location.y / viewSize.height)
//                cameraManager.focusAtPoint(pointOfInterest)
//                
//                focusPoint = location
//                showFocusCircle = true
//                
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    showFocusCircle = false
//                }
//            }
//            .overlay(
//                ZStack {
//                    VStack {
//                        HStack {
//                            CameraButton(action: {
//                                isPreviewActive = false
//                                photoGalleryViewModel.stopCamera()
//                            }, imageName: "xmark")
//                            Spacer()
//                            CameraButton(action: cameraManager.switchCamera, imageName: "arrow.triangle.2.circlepath")
//                        }
//                        .padding(.horizontal)
//                        .padding(.top)
//                        
//                        Spacer()
//                    }
//                    
//                    if showFocusCircle, let point = focusPoint {
//                        FocusCircleView(point: point)
//                    }
//                }
//            )
//        }
//        .onAppear {
//            photoGalleryViewModel.startCamera()
//        }
//        .onDisappear {
//            photoGalleryViewModel.stopCamera()
//        }
//    }
//}

//struct CameraPreviewView: View {
//    @ObservedObject var cameraManager: CameraManager
//    @ObservedObject var photoGalleryViewModel: PhotoGalleryViewModel
//    @Binding var isPreviewActive: Bool
//    @Binding var orientation: UIDeviceOrientation
//    @State private var focusPoint: CGPoint?
//    @State private var showFocusCircle = false
//    @State private var isPaused: Bool = false
//    @State private var lastFrame: UIImage?
//
//    var body: some View {
//        ZStack {
//            if let lastFrame = lastFrame, isPaused {
//                Image(uiImage: lastFrame)
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//            } else {
//                CameraPreview(session: cameraManager.session, orientation: $orientation) { location in
//                    let viewSize = orientation.isLandscape ? CGSize(width: 300, height: UIScreen.main.bounds.height) : CGSize(width: UIScreen.main.bounds.width, height: 300)
//                    let pointOfInterest = CGPoint(x: location.x / viewSize.width,
//                                                  y: location.y / viewSize.height)
//                    cameraManager.focusAtPoint(pointOfInterest)
//                    
//                    focusPoint = location
//                    showFocusCircle = true
//                    
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                        showFocusCircle = false
//                    }
//                }
//            }
//            
//            VStack {
//                HStack {
//                    CameraButton(action: {
//                        isPreviewActive = false
//                        photoGalleryViewModel.stopCamera()
//                    }, imageName: "xmark")
//                    Spacer()
//                    CameraButton(action: cameraManager.switchCamera, imageName: "arrow.triangle.2.circlepath")
//                }
//                .padding(.horizontal)
//                .padding(.top)
//                
//                Spacer()
//                
//                CameraButton(action: {
//                    isPaused.toggle()
//                    if isPaused {
//                        photoGalleryViewModel.pauseCamera()
//                    } else {
//                        photoGalleryViewModel.resumeCamera()
//                    }
//                }, imageName: isPaused ? "play.circle.fill" : "pause.circle.fill")
//                .frame(width: 60, height: 60)
//            }
//            
//            if showFocusCircle, let point = focusPoint {
//                FocusCircleView(point: point)
//            }
//        }
//        .onAppear {
//            photoGalleryViewModel.startCamera()
//            photoGalleryViewModel.onFrameCaptured = { image in
//                if !self.isPaused {
//                    self.lastFrame = UIImage(ciImage: image)
//                }
//            }
//        }
//        .onDisappear {
//            photoGalleryViewModel.stopCamera()
//        }
//    }
//}

struct CameraPreviewView: View {
    @ObservedObject var photoGalleryViewModel: PhotoGalleryViewModel
    @Binding var isPreviewActive: Bool
    @Binding var orientation: UIDeviceOrientation
    @State private var focusPoint: CGPoint?
    @State private var showFocusCircle = false
    @State private var isPaused: Bool = false
    @State private var lastFrame: UIImage?

    var body: some View {
        ZStack {
            if let lastFrame = lastFrame, isPaused {
                Image(uiImage: lastFrame)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                CameraPreview(session: photoGalleryViewModel.getCameraSession(), orientation: $orientation) { location in
                    let viewSize = orientation.isLandscape ? CGSize(width: 300, height: UIScreen.main.bounds.height) : CGSize(width: UIScreen.main.bounds.width, height: 300)
                    let pointOfInterest = CGPoint(x: location.x / viewSize.width,
                                                  y: location.y / viewSize.height)
                    photoGalleryViewModel.focusCamera(at: pointOfInterest)
                    
                    focusPoint = location
                    showFocusCircle = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showFocusCircle = false
                    }
                }
            }
            
            VStack {
                HStack {
                    CameraButton(action: {
                        isPreviewActive = false
                        photoGalleryViewModel.stopCamera()
                    }, imageName: "xmark")
                    Spacer()
                    CameraButton(action: photoGalleryViewModel.switchCamera, imageName: "arrow.triangle.2.circlepath")
                }
                .padding(.horizontal)
                .padding(.top)
                
                Spacer()
                
                CameraButton(action: {
                    photoGalleryViewModel.togglePause()
                }, imageName: photoGalleryViewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                .frame(width: 60, height: 60)
            }
            
            if showFocusCircle, let point = focusPoint {
                FocusCircleView(point: point)
            }
        }
        .onAppear {
            photoGalleryViewModel.startCamera()
            photoGalleryViewModel.onFrameCaptured = { image in
                self.lastFrame = UIImage(ciImage: image)
            }
        }
        .onDisappear {
            photoGalleryViewModel.stopCamera()
        }
    }
}

struct CameraButton: View {
    let action: () -> Void
    let imageName: String
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 45, height: 45)
                
                Image(systemName: imageName)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
        }
    }
}

//struct CameraPreviewView: View {
//    @ObservedObject var cameraManager: CameraManager
//    @ObservedObject var photoGalleryViewModel: PhotoGalleryViewModel
//    @Binding var isPreviewActive: Bool
//    @State private var focusPoint: CGPoint?
//    @State private var showFocusCircle = false
//    @State private var isPaused: Bool = false
//    @State private var lastFrame: CIImage?
//
//    var body: some View {
//        ZStack {
//            if let lastFrame = lastFrame, isPaused {
//                Image(uiImage: UIImage(ciImage: lastFrame))
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .frame(height: 300)
//            } else {
//                CameraPreview(session: cameraManager.session) { location in
//                    let viewSize = CGSize(width: UIScreen.main.bounds.width, height: 300)
//                    let pointOfInterest = CGPoint(x: location.x / viewSize.width,
//                                                  y: location.y / viewSize.height)
//                    cameraManager.focusAtPoint(pointOfInterest)
//                    
//                    focusPoint = location
//                    showFocusCircle = true
//                    
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                        showFocusCircle = false
//                    }
//                }
//            }
//            
//            VStack {
//                HStack {
//                    CameraButton(action: {
//                        isPreviewActive = false
//                        photoGalleryViewModel.stopCamera()
//                    }, imageName: "xmark")
//                    
//                    Spacer()
//                    
//                    CameraButton(action: {
//                        isPaused.toggle()
//                        if isPaused {
//                            photoGalleryViewModel.pauseCamera()
//                            if let lastFrame = lastFrame {
//                                photoGalleryViewModel.performImageSearch(from: lastFrame)
//                            }
//                        } else {
//                            photoGalleryViewModel.resumeCamera()
//                        }
//                    }, imageName: isPaused ? "play.circle.fill" : "pause.circle.fill")
//                    
//                    Spacer()
//                    
//                    CameraButton(action: cameraManager.switchCamera, imageName: "arrow.triangle.2.circlepath")
//                }
//                .padding(.horizontal)
//                .padding(.top)
//                
//                Spacer()
//            }
//            
//            if showFocusCircle, let point = focusPoint {
//                FocusCircleView(point: point)
//            }
//        }
//        .onAppear {
//            photoGalleryViewModel.startCamera()
//            photoGalleryViewModel.onFrameCaptured = { image in
//                lastFrame = image
//            }
//        }
//        .onDisappear {
//            photoGalleryViewModel.stopCamera()
//        }
//    }
//}
//
//struct CameraButton: View {
//    let action: () -> Void
//    let imageName: String
//
//    var body: some View {
//        Button(action: action) {
//            ZStack {
//                Circle()
//                    .fill(Color.black.opacity(0.5))
//                    .frame(width: 45, height: 45)
//
//                Image(systemName: imageName)
//                    .font(.system(size: 20))
//                    .foregroundColor(.white)
//            }
//        }
//    }
//}


struct FocusCircleView: View {
    let point: CGPoint
    
    var body: some View {
        Circle()
            .stroke(Color.yellow, lineWidth: 2)
            .frame(width: 70, height: 70)
            .position(point)
    }
}

//struct CameraPreview: UIViewRepresentable {
//    let session: AVCaptureSession
//    var onTap: (CGPoint) -> Void
//
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 300))
//        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
//        previewLayer.frame = view.bounds
//        previewLayer.videoGravity = .resizeAspectFill
//        view.layer.addSublayer(previewLayer)
//        
//        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
//        view.addGestureRecognizer(tapGesture)
//        
//        return view
//    }
//
//    func updateUIView(_ uiView: UIView, context: Context) {}
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    class Coordinator: NSObject {
//        var parent: CameraPreview
//
//        init(_ parent: CameraPreview) {
//            self.parent = parent
//        }
//
//        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
//            let location = gesture.location(in: gesture.view)
//            parent.onTap(location)
//        }
//    }
//}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    @Binding var orientation: UIDeviceOrientation
    var onTap: (CGPoint) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
            updatePreviewLayerOrientation(previewLayer)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

//    private func updatePreviewLayerOrientation(_ previewLayer: AVCaptureVideoPreviewLayer) {
//        guard let connection = previewLayer.connection else { return }
//        
//        if let device = AVCaptureDevice.default(for: .video) {
//            let rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
//            connection.videoRotationAngle = rotationCoordinator.videoRotationAngleForHorizonLevelCapture
//        }
//    }
    
    private func updatePreviewLayerOrientation(_ previewLayer: AVCaptureVideoPreviewLayer) {
        guard let connection = previewLayer.connection else { return }
        
        if let device = AVCaptureDevice.default(for: .video) {
            let rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
            
            // Determinar si estamos usando la cámara frontal
            let isFrontCamera = device.position == .front
            
            if isFrontCamera {
                // Lógica específica para la cámara frontal
                let angle = rotationCoordinator.videoRotationAngleForHorizonLevelCapture
                
                // Ajustar el ángulo para la cámara frontal
                let adjustedAngle: CGFloat
                switch UIDevice.current.orientation {
                case .landscapeLeft:
                    adjustedAngle = angle + 90
                case .landscapeRight:
                    adjustedAngle = angle + 90
                case .portraitUpsideDown:
                    adjustedAngle = angle + 90
                default:
                    adjustedAngle = angle
                }
                
                connection.videoRotationAngle = adjustedAngle.truncatingRemainder(dividingBy: 360)
                connection.isVideoMirrored = true
            } else {
                // Mantener la lógica existente para la cámara trasera
                connection.videoRotationAngle = rotationCoordinator.videoRotationAngleForHorizonLevelCapture
            }
        }
    }

    class Coordinator: NSObject {
        var parent: CameraPreview

        init(_ parent: CameraPreview) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            parent.onTap(location)
        }
    }
}
