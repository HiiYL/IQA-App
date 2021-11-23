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
import Speech

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
class ViewController: UIViewController, UITextFieldDelegate,SFSpeechRecognizerDelegate {
    
    let captureSession = AVCaptureSession()
    let stillImageOutput = AVCaptureStillImageOutput()
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    private let audioEngine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    
    
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var viewfinderView: UIView!
    // If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?

    @IBOutlet weak var askTextField: UITextField!
    @IBOutlet weak var answerLabel: UILabel!
    
    @IBAction func microphoneTapped(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.askTextField.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
                self.saveToCamera()
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        self.askTextField.text = "Say something, I'm listening!"
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        askTextField.delegate = self
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        let devices = AVCaptureDevice.devices()
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if ((device as AnyObject).hasMediaType(AVMediaType.video)) {
                // Finally check the position and confirm we've got the back camera
                if((device as AnyObject).position == AVCaptureDevice.Position.back) {
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
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice!))
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
        if let videoConnection = stillImageOutput.connection(with: AVMediaType.video) {
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(
                    forJPEGSampleBuffer: imageDataSampleBuffer!, previewPhotoSampleBuffer: nil)
                if let unwrapped_img = imageData, let unwrapped_q = self.askTextField.text {
                    let img_resized = (UIImage(data:unwrapped_img)?.resized(toWidth: 598))!.jpegData(compressionQuality: 1.0)
                    self.askTextField.text = ""
                    self.answerLabel.text = "❄️❄️❄️"
                    let parameters = [
                        "question": unwrapped_q
                    ]
                    AF.upload(
                        multipartFormData: { multipartFormData in
                            multipartFormData.append(
                                img_resized!, withName: "file",
                                fileName: "picture.jpg", mimeType: "image/jpg")
                            for (key, value) in parameters {
                                multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
                            }
                    },
                        //to: "https://65a68797.ngrok.io",
                        to: "http://140.109.135.211:5000"
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

