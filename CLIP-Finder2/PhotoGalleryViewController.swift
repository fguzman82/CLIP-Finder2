//
//  PhotoGalleryViewController.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 24/06/24.
//

//import UIKit
//import Photos
//import CoreML
//
//class PhotoGalleryViewController: UIViewController {
//    private var collectionView: UICollectionView!
//    private var assets: [PHAsset] = []
//    private var model = DataModel()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupCollectionView()
//        setupClearCacheButton()
//        fetchPhotos()
//    }
//
//    private func setupCollectionView() {
//        let layout = UICollectionViewFlowLayout()
//        
//        let spacing: CGFloat = 2 // Espaciado entre elementos
//        layout.minimumInteritemSpacing = spacing
//        layout.minimumLineSpacing = spacing
//        let numberOfColumns: CGFloat = 3
//        let itemWidth = (view.frame.width - (numberOfColumns - 1) * spacing) / numberOfColumns
//        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
//       
//        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
//        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.identifier)
//        collectionView.dataSource = self
//        collectionView.delegate = self
//        view.addSubview(collectionView)
//    }
//    
//    private func setupClearCacheButton() {
//        let clearCacheButton = UIButton(type: .system)
//        clearCacheButton.setTitle("Clear Cache", for: .normal)
//        clearCacheButton.addTarget(self, action: #selector(clearCache), for: .touchUpInside)
//        
//        clearCacheButton.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(clearCacheButton)
//        
//        NSLayoutConstraint.activate([
//            clearCacheButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
//            clearCacheButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
//        ])
//    }
//
//    @objc private func clearCache() {
//        CoreDataManager.shared.deleteAllData()  //Delete all cache data
//        collectionView.reloadData()             //Reload collection to view changes
//    }
//    
//    private func fetchPhotos() {
//        PHPhotoLibrary.requestAuthorization { status in
//            if status == .authorized {
//                let fetchOptions = PHFetchOptions()
//                let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
//                allPhotos.enumerateObjects { asset, _, _ in
//                    self.assets.append(asset)
//                }
//                self.processAndCachePhotos()
//            }
//        }
//    }
//    
//    private func processAndCachePhotos() {
//        let imageManager = PHImageManager.default()
//        let options = PHImageRequestOptions()
//        options.isSynchronous = true
//        options.deliveryMode = .highQualityFormat
//
//        DispatchQueue.main.async {
//            let targetSize = CGSize(width: 256, height: 256)
//            
//            print("cache async")
//
//            for asset in self.assets {
//                let identifier = asset.localIdentifier
//
//                if let cachedVector = CoreDataManager.shared.fetchVector(for: identifier) {
//                    // Handle the cached vector as needed
//                    print("ID: \(identifier), Vector: \(cachedVector.toFloatArray())")
//                } else {
//                    imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
//                        if let image = image, let pixelBuffer = Preprocessing.preprocessImage(image, targetSize: targetSize), let vector = self.model.performInference(pixelBuffer) {
//                            CoreDataManager.shared.saveVector(vector, for: identifier)
//                            print("ID: \(identifier), Vector: \(vector.toFloatArray())")
//                        }
//                    }
//                }
//            }
//
//            self.collectionView.reloadData()
//        }
//    }
//}
//
//
//extension PhotoGalleryViewController: UICollectionViewDataSource, UICollectionViewDelegate {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return assets.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.identifier, for: indexPath) as! PhotoCell
//        let asset = assets[indexPath.item]
//        let identifier = asset.localIdentifier
//        if let vector = CoreDataManager.shared.fetchVector(for: identifier) {
//            // We can display the processed image if needed or other information
//        }
//        return cell
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let asset = assets[indexPath.item]
//        let imageManager = PHImageManager.default()
//        let options = PHImageRequestOptions()
//        options.isSynchronous = true
//        options.deliveryMode = .highQualityFormat
//        imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { image, _ in
//            if let image = image {
//                let imageViewController = ImageViewController()
//                imageViewController.image = image
//                self.present(imageViewController, animated: true, completion: nil)
//            }
//        }
//    }
//}
//
//class PhotoCell: UICollectionViewCell {
//    static let identifier = "PhotoCell"
//
//    private let imageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFill
//        imageView.clipsToBounds = true
//        return imageView
//    }()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        contentView.addSubview(imageView)
//        imageView.frame = contentView.bounds
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func setImage(_ image: UIImage) {
//        imageView.image = image
//    }
//}
