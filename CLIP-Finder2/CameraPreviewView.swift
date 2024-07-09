//
//  CameraPreviewView.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 28/06/24.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: View {
    @ObservedObject var photoGalleryViewModel: PhotoGalleryViewModel
    @Binding var isPreviewActive: Bool
    @Binding var orientation: UIDeviceOrientation
    @State private var focusPoint: CGPoint?
    @State private var showFocusCircle = false
    @State private var isPaused: Bool = false
    @State private var lastFrame: UIImage?
    @State private var showTurboModeAlert = false

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
                
                HStack {
                    Spacer()
                    CameraButton(action: {
                        photoGalleryViewModel.togglePause()
                    }, imageName: photoGalleryViewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                    .frame(width: 60, height: 60)
                    Spacer()
                    TurboButton(viewModel: photoGalleryViewModel, showAlert: $showTurboModeAlert)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            
            if showFocusCircle, let point = focusPoint {
                FocusCircleView(point: point)
            }
        }
        .alert(isPresented: $showTurboModeAlert) {
            Alert(
                title: Text("Activate Turbo Mode"),
                message: Text("Turbo Mode enables asynchronous CLIP image prediction. It's faster but may freeze the app (beta feature)."),
                primaryButton: .default(Text("Activate")) {
                    photoGalleryViewModel.toggleTurboMode()
                    photoGalleryViewModel.finalizeTurboToggle()
                },
                secondaryButton: .cancel {
                    photoGalleryViewModel.finalizeTurboToggle()
                }
            )
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
            Image(systemName: imageName)
                .font(.system(size: 30))
                .foregroundColor(.white)
                .frame(width: 45, height: 45)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
        }
    }
}

struct FocusCircleView: View {
    let point: CGPoint
    
    var body: some View {
        Circle()
            .stroke(Color.yellow, lineWidth: 2)
            .frame(width: 70, height: 70)
            .position(point)
    }
}

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

    private func updatePreviewLayerOrientation(_ previewLayer: AVCaptureVideoPreviewLayer) {
        guard let connection = previewLayer.connection else { return }
        
        if let device = AVCaptureDevice.default(for: .video) {
            let rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
            connection.videoRotationAngle = rotationCoordinator.videoRotationAngleForHorizonLevelCapture
        }
    }
    
//    private func updatePreviewLayerOrientation(_ previewLayer: AVCaptureVideoPreviewLayer) {
//        guard let connection = previewLayer.connection else { return }
//        
//        if let device = AVCaptureDevice.default(for: .video) {
//            let rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
//            
//            // Determinar si estamos usando la cámara frontal
//            let isFrontCamera = device.position == .front
//            
//            if isFrontCamera {
//                // Lógica específica para la cámara frontal
//                let angle = rotationCoordinator.videoRotationAngleForHorizonLevelCapture
//                
//                // Ajustar el ángulo para la cámara frontal
//                let adjustedAngle: CGFloat
//                switch UIDevice.current.orientation {
//                case .landscapeLeft:
//                    adjustedAngle = angle + 90
//                case .landscapeRight:
//                    adjustedAngle = angle + 90
//                case .portraitUpsideDown:
//                    adjustedAngle = angle + 90
//                default:
//                    adjustedAngle = angle
//                }
//                
//                connection.videoRotationAngle = adjustedAngle.truncatingRemainder(dividingBy: 360)
//                connection.isVideoMirrored = true
//            } else {
//                // Mantener la lógica existente para la cámara trasera
//                connection.videoRotationAngle = rotationCoordinator.videoRotationAngleForHorizonLevelCapture
//            }
//        }
//    }

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


struct TurboButton: View {
    @ObservedObject var viewModel: PhotoGalleryViewModel
    @Binding var showAlert: Bool

    var body: some View {
        Button(action: {
            if !viewModel.useAsyncImageSearch {
                viewModel.prepareTurboToggle()
                showAlert = true
            } else {
                viewModel.toggleTurboMode()
                viewModel.finalizeTurboToggle()
            }
        }) {
            ZStack {
                Circle()
                    .fill(viewModel.useAsyncImageSearch ? Color.yellow : Color.gray)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "bolt.fill")
                    .foregroundColor(viewModel.useAsyncImageSearch ? .black : .white)
                    .font(.system(size: 20))
            }
        }
        .overlay(
            Text("Turbo")
                .font(.system(size: 10))
                .foregroundColor(.white)
                .padding(2)
                .background(Color.black.opacity(0.6))
                .cornerRadius(4)
                .offset(y: 25)
        )
    }
}
