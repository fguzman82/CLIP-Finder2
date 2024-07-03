# CLIP-Profiler

CLIP-Profiler is an iOS application that leverages advanced AI models to perform image and text similarity searches. It utilizes two CoreML models optimized for the Apple Neural Engine, ensuring efficient on-device processing. The app provides a user-friendly interface for searching and profiling, making the most of Apple's cutting-edge AI capabilities.

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

## Components

1. **AI Models**: 
   - CLIP Image Model (CoreML, optimized for Apple Neural Engine)
   - CLIP Text Model (CoreML, optimized for Apple Neural Engine)

2. **Image Processing**:
   - Preprocessing: Utilizes MPSGraph for efficient GPU-based image preparation
   - Postprocessing: Employs MPSGraph for similarity calculations using dot product

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


## Installation

[Provide installation instructions here, e.g., TestFlight link or App Store availability]

## Usage

[Provide basic usage instructions here]

## Troubleshooting

[List common issues and their solutions]

## Privacy

CLIP-Profiler processes all data on-device, ensuring your photos and search queries remain private.

## Contributing

[If applicable, provide information on how others can contribute to the project]

## License

[Specify the license under which the app is released]

## Contact

[Provide contact information or links for support and inquiries]
