<div align="center">
        <img src="https://github.com/fguzman82/CLIP-Finder2/assets/34175524/7c4dfb0d-076e-439b-9ae4-10ece7dfef2b" width="100" style="border: none;">
</div>


<h1 align="center">
   CLIP-Finder
</h1>


https://github.com/fguzman82/CLIP-Finder2/assets/34175524/d711f5d4-0629-483a-9e3a-ecc1b45a9b2f


CLIP-Finder is an iOS application that leverages advanced AI models to perform image similarity searches. It utilizes two CoreML models optimized for the Apple Neural Engine, ensuring efficient on-device processing. The app allows users to search for images from the photo gallery using natural language descriptions or live camera input. All searches are completely offline, providing a user-friendly interface for searching and profiling while taking full advantage of Apple's cutting-edge AI capabilities.

This project is based on Apple's [MobileCLIP](https://github.com/apple/ml-mobileclip) architecture. Details of the architecture can be found in the following [paper](https://arxiv.org/pdf/2311.17049). The selected subarchitecture is [MobileCLIP-S0](https://huggingface.co/apple/mobileclip_s0_timm), finding consistency with the latency times of the Image/Text encoders reported by the authors. The *ImageEncoder* is based on [FastViT](https://github.com/apple/ml-fastvit) with some minor modifications. The general architecture of the two approaches implemented in CLIP-Finder is presented below:

<div align="center">
  <img width="600" alt="Text Architecture" src="https://github.com/fguzman82/CLIP-Finder2/assets/34175524/fade6b3d-e40e-40a5-befa-eb78031ef236">
  <img width="600" alt="Video Architecture" src="https://github.com/fguzman82/CLIP-Finder2/assets/34175524/8d6ac3d8-5567-4b37-9d66-1e1001ee86e2">
</div>



## Features

- Text-based image search
- Image-based search using iPhone's front or rear camera
- Two CoreML models optimized for the Apple Neural Engine:
  - CLIP Image Model
  - CLIP Text Model
- GPU-accelerated image preprocessing using MPSGraph
- Similarity calculation using dot product in MPSGraph
- Model profiling for performance analysis across different compute units
- Cache management for optimized performance
- Tokenizer: Implementation in Swift based on the Tokenizer written in Python from [open_clip](https://github.com/mlfoundations/open_clip/blob/main/src/open_clip/tokenizer.py)

## Release
## <img src="https://developer.apple.com/assets/elements/icons/testflight/testflight-64x64_2x.png" width="40" height="40"> Try It Out
To experience these new features firsthand, join the TestFlight program:

[**TestFlight Link**](https://testflight.apple.com/join/eZ43s4s6)

## Components

1. **AI Models**: 
   - CLIP Image Model (CoreML, optimized for Apple Neural Engine)
   - CLIP Text Model (CoreML, optimized for Apple Neural Engine)

2. **Image Processing**:
   - Preprocessing: Utilizes MPSGraph for efficient GPU-based image preparation
   - Postprocessing: Employs MPSGraph for similarity calculations using dot product, and selects the photos with the highest similarity scores

3. **User Interface**:
   - Main view for search operations
   - Settings view for cache management and model profiling

4. **Data Management**:
   - Core Data for efficient storage and retrieval of processed image features
  
5. **Asynchronous Image Prediction (Turbo Mode)**

   CLIP-Finder2 now includes an experimental asynchronous image prediction feature, also known as "Turbo Mode". This feature can be activated through a button in the camera interface.

   - Faster image processing: Turbo Mode enables asynchronous camera prediction, potentially speeding up the image search process.
   - Activation: To activate, tap the "Turbo" button in the lower right corner of the camera interface.
   - For more information on asynchronous prediction in Core ML, refer to this WWDC 2023 session:
   [Improve Core ML integration with async prediction](https://developer.apple.com/videos/play/wwdc2023/10049/)

   ⚠️ WARNING: Turbo Mode is faster but may cause the app to freeze momentarily. Use with caution.

## Core ML Packages

This section describes the variations of the Core ML packages available. These packages are designed to provide different levels of performance and accuracy, suitable for a variety of applications. 

The Core ML packages are available at: 🤗 [MobileCLIP on HuggingFace](https://huggingface.co/fguzman82/MobileCLIP).
   
## Core ML Conversion Scripts

This section provides details on the CoreML conversion scripts used for converting models to the CoreML format. The scripts are available as Jupyter Notebooks and can be found in the repository.

### Scripts

1. **CLIPImageModel to CoreML** [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/drive/1ZHMzsJyAukBa4Jryv4Tmc_BOBmbQAjxf?usp=sharing)
   - This notebook demonstrates the process of converting a CLIP image model to CoreML format.

2. **CLIPTextModel to CoreML**  [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/drive/1PxzB8M0h2bf-uYpw7fIZImpGSVXUI7Ie?usp=sharing)
   - This notebook demonstrates the process of converting a CLIP text model to CoreML format.
  
## Search Methods

1. **Text Search**: Enter descriptive text to find matching images in your gallery
2. **Image Search**: Use either the front or rear camera of your iPhone to capture an image and find similar photos

## System Requirements

- iOS 17 or later
- iPhone with A12 Bionic chip or later (for optimal AI model performance on the Neural Engine)

## Important Notes

- It is recommended to turn off Low Power Mode for optimal performance, especially to fully utilize the Apple Neural Engine.
- The app requires permission to access your photo gallery and camera.
- 
## Batch Processing

<div align="center">
<img width="900" src="https://github.com/user-attachments/assets/7aea4ffd-411e-4cd6-85eb-786528d7a308">
</div>

CLIP-Finder implements efficient batch processing to handle large photo galleries:

- On app launch, the entire photo gallery is preprocessed using the **Neural Engine** with a batch size of 512 photos. This approach significantly speeds up the initial processing time.

- When new photos are added to the device's gallery, CLIP-Finder detects and processes only the new images upon the next app launch. This incremental processing ensures that the app stays up-to-date with the latest additions to your photo library without redundant calculations.

- Similarly, if photos are deleted from the device, CLIP-Finder updates its database accordingly during the next app launch. This cleanup process maintains the accuracy of the search results and optimizes storage usage.

Refer to this Blog for more details: 🤗 [Hugging Face Blog](https://huggingface.co/blog/fguzman82/coreml-async-batch-prediction)


## Settings

The Settings view provides two main functions:

1. **Clear Cache**: Removes all preprocessed image data to free up storage space
2. **Model Profiler**: Runs a performance analysis on both CoreML models across different computational units (CPU, GPU, Neural Engine, and combinations), allowing you to see the performance benefits of the Apple Neural Engine

This is the view for the CoreMLProfiler built-in app.

<div align="center">
<img width="300" src="https://github.com/fguzman82/CLIP-Finder2/assets/34175524/5fa8341a-a3ad-44a4-986c-59171ac45ce6" alt="IMG_2143">
</div>


## Acknowledgments

This project is based on the architecture of the [MobileCLIP](https://github.com/apple/ml-mobileclip), which is licensed under the MIT License. An acknowledgment is extended to the authors of the paper: Pavan Kumar Anasosalu Vasu, Hadi Pouransari, Fartash Faghri, Raviteja Vemulapalli, and Oncel Tuzel, for their valuable contributions.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

