//
//  QRScannerView.swift
//  OktaClone
//
//  Created by ian schoenrock on 1/14/26.
//

import SwiftUI
import AVFoundation

struct QRScannerView: UIViewRepresentable {
    
    // This closure will be called when a code is found
    var didFindCode: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        // Setup the Capture Session
        let captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return view }
        let videoInput: AVCaptureDeviceInput
            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch { return view }
            
            if (captureSession.canAddInput(videoInput)) { captureSession.addInput(videoInput) }
            
            let metadataOutput = AVCaptureMetadataOutput()
            if (captureSession.canAddOutput(metadataOutput)) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            
            // Start running
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
            }
            
            return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
            // This is called whenever the SwiftUI frame changes
            if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
                layer.frame = uiView.bounds
            }
        }
    
    // Our Bridge between UIKit Delegate and SwiftUI Closure
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRScannerView
        
        init(parent: QRScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                
                // We found a code!
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                
                // Send it back to SwiftUI
                parent.didFindCode(stringValue)
            }
        }
    }
}
