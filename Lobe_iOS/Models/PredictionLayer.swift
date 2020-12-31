//
//  PredictionLayer.swift
//  Lobe_iOS
//
//  Created by Elliot Boschwitz on 11/30/20.
//  Copyright © 2020 Microsoft. All rights reserved.
//

import Combine
import SwiftUI
import Vision

/// Backend logic for predicting classifiers for a given image.
class PredictionLayer: NSObject {
    @Published var classificationResult: VNClassificationObservation?
    var model: VNCoreMLModel?
    
    init(model: VNCoreMLModel?) {
        self.model = model
    }
    
    /// Prediction handler which updates `classificationResult` publisher.
    func getPrediction(forImage image: UIImage) {
        let requestHandler = createPredictionRequestHandler(forImage: image)
        let request = createModelRequest(
            /// Set classification result to publisher
            onComplete: { [weak self] request in
                guard let classifications = request.results as? [VNClassificationObservation],
                      !classifications.isEmpty else {
                    self?.classificationResult = nil
                    return
                }
                let topClassifications = classifications.prefix(1)
                self?.classificationResult = topClassifications[0]
            }, onError: { [weak self] error in
                print("Error getting predictions: \(error)")
                self?.classificationResult = nil
            })
        
        try? requestHandler.perform([request])
    }
    
    /// Creates request handler and formats image for prediciton processing.
    private func createPredictionRequestHandler(forImage image: UIImage) -> VNImageRequestHandler {
        /* Crop to square images and send to the model. */
        guard let cgImage = image.cgImage else {
            fatalError("Could not create cgImage in captureOutput")
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        let requestHandler = VNImageRequestHandler(ciImage: ciImage)
        return requestHandler
    }
    
    private func createModelRequest(onComplete: @escaping (VNRequest) -> (), onError: @escaping (Error) -> ()) -> VNCoreMLRequest {
        guard let model = model else {
            fatalError("Model not found in prediction layer")
        }

        let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
            if let error = error {
                onError(error)
            }
            onComplete(request)
        })
        return request
    }    
}
