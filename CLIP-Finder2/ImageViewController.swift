//
//  ImageViewController.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 24/06/24.
//

import UIKit

class ImageViewController: UIViewController {
    var image: UIImage?
    private var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupImageView()
        setupGestures()
        setupShareButton()
    }

    private func setupImageView() {
        imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = view.bounds
        imageView.isUserInteractionEnabled = true
        view.addSubview(imageView)
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        view.addGestureRecognizer(tapGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        imageView.addGestureRecognizer(pinchGesture)
    }

    private func setupShareButton() {
        let shareButton = UIButton(type: .system)
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.tintColor = .white
        shareButton.addTarget(self, action: #selector(shareImage), for: .touchUpInside)
        
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shareButton)
        
        NSLayoutConstraint.activate([
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shareButton.widthAnchor.constraint(equalToConstant: 50),
            shareButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }

        view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
        gesture.scale = 1
    }

    @objc private func shareImage() {
        guard let image = image else { return }
        
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
            if let error = activityError {
                print("Activity error: \(error.localizedDescription)")
            } else if completed {
                print("Activity completed successfully")
            } else {
                print("Activity canceled")
            }
        }
        present(activityViewController, animated: true, completion: nil)
    }
}

