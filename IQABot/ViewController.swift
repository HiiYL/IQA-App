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
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
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
    @IBOutlet weak var answerLabel: UILabel!
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
        answerLabel.text = ""
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
                let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(
                    forJPEGSampleBuffer: imageDataSampleBuffer!, previewPhotoSampleBuffer: nil)
                if let unwrapped_img = imageData, let unwrapped_q = self.askTextField.text {
                    let img_resized = UIImageJPEGRepresentation((UIImage(data:unwrapped_img)?.resized(toWidth: 598))!, 1.0)
                    self.askTextField.text = ""
                    self.answerLabel.text = "❄️❄️❄️"
                    let parameters = [
                        "question": unwrapped_q
                    ]
                    Alamofire.upload(
                        multipartFormData: { multipartFormData in
                            multipartFormData.append(
                                img_resized!, withName: "file",
                                fileName: "picture.jpg", mimeType: "image/jpg")
                            for (key, value) in parameters {
                                multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
                            }
                    },
                        to: "https://65a68797.ngrok.io",
                        encodingCompletion: { encodingResult in
                            switch encodingResult {
                            case .success(let upload, _, _):
                                upload.responseJSON { response in
                                    
                                    if let JSON = response.result.value {
                                        print("JSON: \(JSON)")
                                    }
                                    if let jsonDict = response.result.value as? [String:Any] {
                                        if let answer = jsonDict["response"] as? String {
                                            self.answerLabel.text = answer
                                            print(answer)
                                        }
                                    }
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

