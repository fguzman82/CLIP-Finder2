<div align="center">
        <img src="https://github.com/fguzman82/CLIP-Finder2/assets/34175524/7c4dfb0d-076e-439b-9ae4-10ece7dfef2b" width="100" style="border: none;">
</div>


<h1 align="center">
   CLIP-Finder
</h1>



https://github.com/fguzman82/CLIP-Finder2/assets/34175524/d711f5d4-0629-483a-9e3a-ecc1b45a9b2f




CLIP-Finder is an iOS application that leverages advanced AI models to perform image similarity searches. It utilizes two CoreML models optimized for the Apple Neural Engine, ensuring efficient on-device processing. The app allows users to search for images from the photo gallery using natural language descriptions or live camera input. All searches are completely offline, providing a user-friendly interface for searching and profiling while taking full advantage of Apple's cutting-edge AI capabilities.

This project is based on Apple's [MobileCLIP](https://github.com/apple/ml-mobileclip) architecture. Details of the architecture can be found in the following [paper](https://arxiv.org/pdf/2311.17049). The selected subarchitecture is [MobileCLIP-S0](https://huggingface.co/apple/mobileclip_s0_timm), finding consistency with the latency times of the Image/Text encoders reported by the authors. The general architecture of the two approaches implemented in CLIP-Finder is presented below:

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

## Search Methods

1. **Text Search**: Enter descriptive text to find matching images in your gallery
2. **Image Search**: Use either the front or rear camera of your iPhone to capture an image and find similar photos

## System Requirements

- iOS 17 or later
- iPhone with A12 Bionic chip or later (for optimal AI model performance on the Neural Engine)

## Important Notes

- It is recommended to turn off Low Power Mode for optimal performance, especially to fully utilize the Apple Neural Engine.
- The app requires permission to access your photo gallery and camera.

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

