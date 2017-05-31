//
//  ViewController.swift
//  IQABot
//
//  Created by Hii Yong Lian on 31/5/17.
//  Copyright © 2017 Hii Yong Lian. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire

extension UIImage {
    
    func scaleImage(toSize newSize: CGSize) -> UIImage? {
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = .high
            let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
            context.concatenate(flipVertical)
            context.draw(self.cgImage!, in: newRect)
            let newImage = UIImage(cgImage: context.makeImage()!)
            UIGraphicsEndImageContext()
            return newImage
        }
        return nil
    }
}
class ViewController: UIViewController, UITextFieldDelegate {
    
    let captureSession = AVCaptureSession()
    let stillImageOutput = AVCaptureStillImageOutput()
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    
    @IBOutlet weak var viewfinderView: UIView!
    // If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?

    @IBOutlet weak var askTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        askTextField.delegate = self
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        let devices = AVCaptureDevice.devices()
        // Loop through all the capture devices on this phone
        for device in devices! {
            // Make sure this particular device supports video
            if ((device as AnyObject).hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if((device as AnyObject).position == AVCaptureDevicePosition.back) {
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        if captureDevice != nil {
            beginSession()
        }
        
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        saveToCamera()
        //imageData = saveToCamera()
        //let imageData = UIImagePNGRepresentation(image)!
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        //navigationItem.title = textField.text
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing.
        //saveButton.isEnabled = false
    }
    
    func beginSession() {
        //configureDevice()
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        } catch _ {
            //Error handling, if needed
        }
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.viewfinderView.layer.addSublayer(previewLayer!)
        previewLayer?.frame = self.viewfinderView.layer.frame
        captureSession.startRunning()
        
        if captureSession.canAddOutput(stillImageOutput) {
            captureSession.addOutput(stillImageOutput)
        }
        
    }
    
    
    func saveToCamera() {
        if let videoConnection = stillImageOutput.connection(withMediaType: AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                if let unwrapped_img = imageData {
//                    Alamofire.upload(unwrapped, to: "http://192.168.1.102:5000").responseJSON { response in
//                        debugPrint(response)
//                    }
                    if let unwrapped_q = self.askTextField.text {
                        self.askTextField.text = ""
                        let parameters = [
                            "question": unwrapped_q
                        ]
                        Alamofire.upload(
                            multipartFormData: { multipartFormData in
                                multipartFormData.append(
                                    unwrapped_img, withName: "file",
                                    fileName: "picture.png", mimeType: "image/png")
                                for (key, value) in parameters {
                                    multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
                                }
                        },
                            to: "http://192.168.1.102:5000",
                            encodingCompletion: { encodingResult in
                                switch encodingResult {
                                case .success(let upload, _, _):
                                    upload.responseJSON { response in
                                        debugPrint(response)
                                    }
                                case .failure(let encodingError):
                                    print(encodingError)
                                }
                        }
                        )
                    }
                }
            }
        }
    }
    func configureDevice() {
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
            } catch _ {
                //Error handling, if needed
            }
            device.focusMode = .locked
            device.unlockForConfiguration()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

