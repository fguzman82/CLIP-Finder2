//
//  SettingsViews.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 30/06/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var photoGalleryViewModel: PhotoGalleryViewModel
    @State private var showingAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button(action: {
                        showingAlert = true
                    }) {
                        Text("Clear Photo Preprocessing Cache")
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Clear Cache"),
                    message: Text("Are you sure you want to clear the photo preprocessing cache? This action cannot be undone."),
                    primaryButton: .destructive(Text("Clear")) {
                        photoGalleryViewModel.reprocessPhotos()
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}


