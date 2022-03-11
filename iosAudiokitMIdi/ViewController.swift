//
//  lamdmarkVC.swift
//  storyBoardTest
//
//  Created by dt on 12/01/2022.
//


import UIKit
import AVFoundation
import Vision
import AudioKit

class ViewController: UIViewController,  AVCaptureVideoDataOutputSampleBufferDelegate
{
    
    
    var request: VNDetectHumanBodyPoseRequest!
    var av:AVAudioEngine!
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
        preview.videoGravity = .resizeAspect
        return preview
    }()
    private let videoOutput = AVCaptureVideoDataOutput()
    var midi:MIDI!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        request = VNDetectHumanBodyPoseRequest(completionHandler: recognizeHumans)
        self.addCameraInput()
        self.addPreviewLayer()
        self.addVideoOutput()
        self.captureSession.startRunning()
        // Do any additional setup after loading the view.
        midi = MIDI()
        midi.openOutput()
        av = AVAudioEngine()
        midi.sendNoteOnMessage(noteNumber: 70, velocity: 100)
        
        
        
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.bounds
        //view.bringSubviewToFront(button)
    }
    
    
    
    func recognizeHumans(request:VNRequest, error: Error?){
        // print(request)
        var redBoxes = [CGRect]()
        var lines = [CGPoint]()
        guard let results = request.results as? [VNHumanBodyPoseObservation] else {
            return
        }
        
        var nose:VNRecognizedPoint?
        var neck:VNRecognizedPoint?
        //  print(results)
        for result in results{
            // print(result.boundingBox)
            // print(result.availableJointNames)
            //print(result.re)
            // print
            if let p = try?  result.recognizedPoint(.nose){
                let r = CGRect(x: p.x-0.01, y: p.y-0.01, width: 0.02, height: 0.02)
                
                redBoxes.append(r)
                nose = p
              //  print(nose!.location)
            }
            
            //             if let p = try? result.recognizedPoint(.leftWrist){
            //                 let r = CGRect(x: p.x-0.01, y: p.y-0.01, width: 0.02, height: 0.02)
            //
            //                 redBoxes.append(r)
            //             }
            if let p = try? result.recognizedPoint(.neck){
                let r = CGRect(x: p.x-0.01, y: p.y-0.01, width: 0.02, height: 0.02)
                neck = p
                redBoxes.append(r)
            }
            if let _ = nose{
                if let _ = neck{
                    
                    lines.append(nose!.location)
                    lines.append(neck!.location)
                }
            }
        }
        // let a = atan2f(x:Float()
        // show(boxGroups: [(color: UIColor.red.cgColor, boxes: redBoxes)])
        if(lines.isNotEmpty){
            show(lineGroups: [(color: UIColor.black.cgColor, lines: lines)])
        }
        
    }
    
    typealias ColoredBoxGroup = (color: CGColor, boxes: [CGRect])
    typealias LineGroup = (color: CGColor,  lines: [CGPoint])
    
    func show(boxGroups: [ColoredBoxGroup]) {
        DispatchQueue.main.async {
            let layer = self.previewLayer
            
            for boxGroup in boxGroups {
                let color = boxGroup.color
                for box in boxGroup.boxes {
                    
                    let rect = layer.layerRectConverted(fromMetadataOutputRect: box)
                    
                    //print(rect)
                    self.draw(rect: rect, color: color)
                }
            }
        }
    }
    var boxLayer = [CAShapeLayer]()
    func show(lineGroups: [LineGroup]) {
        DispatchQueue.main.async { [self] in
            
            self.removeBoxes()
            
            for lineGroup in lineGroups {
                let layer = CAShapeLayer()
                layer.frame = self.previewLayer.frame
                layer.opacity = 1
                layer.borderColor = lineGroup.color
                layer.borderWidth = 2.5
                let path = UIBezierPath()
                path.move(to: CGPoint(x: layer.frame.width - (layer.frame.width * lineGroup.lines[0].x), y: layer.frame.height - (layer.frame.height * lineGroup.lines[0].y)))
                path.addLine(to: CGPoint(x: layer.frame.width - (layer.frame.width * lineGroup.lines[1].x), y: layer.frame.height  - (layer.frame.height * lineGroup.lines[1].y)))
                layer.strokeColor = UIColor.black.cgColor
                // print(line)
                // print(previewLayer.frame)
                //print(lineScaled)
                layer.path = path.cgPath
                // layer.backgroundColor =
                // self.previewLayer.addSublayer(layer)
                midi.sendPitchBendMessage(value: UInt16(lineGroup.lines[0].x * 16384) )
                // print(UInt16(lineGroup.lines[0].x))
                
                self.boxLayer.append(layer)
                self.previewLayer.addSublayer(layer)
            }
        }
    }
    
    // Draw a box on screen. Must be called from main queue.
    
    func draw(rect: CGRect, color: CGColor) {
        let layer = CAShapeLayer()
        layer.opacity = 1
        layer.borderColor = color
        layer.borderWidth = 2.5
        //            let path = UIBezierPath()
        //                    path.move(to: CGPoint(x: 0, y: 0))
        //                    path.addLine(to: CGPoint(x: 200, y: 200))
        // layer.path = path.cgPath
        layer.strokeColor = UIColor.black.cgColor
        layer.frame = rect
        layer.frame.origin.y = self.view.frame.height - layer.frame.maxY
        // layer.isGeometryFlipped = true
        boxLayer.append(layer)
        self.previewLayer.addSublayer(layer)
    }
    
    func draw(rect: CGRect, start:CGPoint, end:CGPoint, color: CGColor) {
        let layer = CAShapeLayer()
        layer.opacity = 1
        layer.borderColor = color
        layer.borderWidth = 2.5
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: previewLayer.frame.width, y: previewLayer.frame.height))
        
        // print(line)
        // print(previewLayer.frame)
        //print(lineScaled)
        layer.path = path.cgPath
        layer.strokeColor = UIColor.black.cgColor
        layer.frame = previewLayer.frame
        // layer.frame.origin.y = self.view.frame.height - layer.frame.maxY
        // layer.isGeometryFlipped = true
        boxLayer.append(layer)
        self.previewLayer.addSublayer(layer)
    }
    
    // Remove all drawn boxes. Must be called on main queue.
    func removeBoxes() {
        for layer in boxLayer {
            layer.removeFromSuperlayer()
        }
        boxLayer.removeAll()
    }
    
    func scalePath(path: UIBezierPath, frame:CGRect) -> UIBezierPath {
        
        let w1: CGFloat = path.bounds.size.width
        let h1: CGFloat = path.bounds.size.height
        
        let w2: CGFloat = frame.width
        let h2: CGFloat = frame.height
        
        var s: CGFloat = 1.0
        
        // take the smaller one and scale 1:1 to fit (to keep the aspect ratio)
        if w2 <= h2 {
            s = w2 / w1
        } else {
            s = h2 / h1
        }
        
        path.apply(CGAffineTransform(scaleX: s, y: s))
        
        return (path)
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }
        // print("did receive image frame")
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: frame, orientation: .up, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            print(error)
        }
        // process image here
    }
    
    private func addCameraInput() {
        guard let device = AVCaptureDevice.default(for: .video) else { return
            
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    private func addPreviewLayer() {
        self.view.layer.addSublayer(self.previewLayer)
    }
    
    private func addVideoOutput() {
        self.videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "my.image.handling.queue"))
        self.captureSession.addOutput(self.videoOutput)
    }
    
    
}
