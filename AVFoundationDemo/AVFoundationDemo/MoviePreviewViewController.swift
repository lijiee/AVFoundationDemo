//
//  MoviePreviewViewController.swift
//  AVFoundationDemo
//
//  Created by 李杰 on 2019/3/20.
//  Copyright © 2019 李杰. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
class MoviePreviewViewController: UIViewController {
    var captureSession : AVCaptureSession?
    var previewLayer : AVCaptureVideoPreviewLayer?
    var captureMovieFileOutPut:AVCaptureMovieFileOutput?
    var captureConnection : AVCaptureConnection?
    var captureVideoDevice : AVCaptureDevice?
    var captureViedoDeviceInput : AVCaptureDeviceInput?
    var captureAudioDevice : AVCaptureDevice?
    var captureAudioDeviceInput : AVCaptureDeviceInput?
    var timer : Timer?
    var timerInteger = 0
    var videoUrl : URL?
    var canSave : Bool?
    var player : AVPlayer?
    var playItem : AVPlayerItem?
    var playerLayer:AVPlayerLayer?
    var isPlay : Bool?
    

    
    @IBOutlet weak var previewButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        getAuthorizeStatus()
    self.previewButton.isHidden = true
        // Do any additional setup after loading the view.
    }
    // #MARK 获取授权
    func getAuthorizeStatus() {
        var authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus == .restricted || authStatus == .denied {
            showMessage(string: "应用相机权限受限,请在设置中启用")
            return
        }
        authStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if authStatus == .restricted || authStatus == .denied {
            showMessage(string: "麦克风权限受限,请在设置中启用")
            return
        }
            //开启上下文
        captureSession = AVCaptureSession.init()
        if captureSession?.canSetSessionPreset(.high) ?? false {
            captureSession?.sessionPreset = .high
        }else{
            captureSession?.sessionPreset = .hd1280x720
        }
        captureSession?.beginConfiguration()
        //开启视频配置
        let devices = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified).devices
        for device in devices {
            if device.position == .front{
                self.captureVideoDevice = device
            }
        }
        self.captureVideoDevice = AVCaptureDevice.default(for: AVMediaType.video)
        do {
            try self.captureViedoDeviceInput = AVCaptureDeviceInput(device: self.captureVideoDevice!)
            if (self.captureSession?.canAddInput(captureViedoDeviceInput!))! {
                self.captureSession?.addInput(captureViedoDeviceInput!)
            }
        } catch  {
            
        }
        self.captureMovieFileOutPut = AVCaptureMovieFileOutput.init()
        if (self.captureSession?.canAddOutput(self.captureMovieFileOutPut!))! {
            self.captureSession?.addOutput(self.captureMovieFileOutPut!)
        }
        self.captureConnection = self.captureMovieFileOutPut?.connection(with: .video)
        self.captureConnection?.videoScaleAndCropFactor = (self.captureConnection?.videoMaxScaleAndCropFactor)!
        if captureConnection?.isVideoStabilizationSupported ?? false {
            captureConnection?.preferredVideoStabilizationMode = .auto
        }
        
        self.captureAudioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
        do {
            try self.captureAudioDeviceInput = AVCaptureDeviceInput(device: self.captureAudioDevice!)
            if (self.captureSession?.canAddInput(captureAudioDeviceInput!))! {
                self.captureSession?.addInput(captureAudioDeviceInput!)
            }
        } catch  {
            
        }
        previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
        previewLayer?.videoGravity = .resizeAspect
        previewLayer?.frame = self.view.frame
        self.view.layer.addSublayer(previewLayer!)
        captureSession?.commitConfiguration()
        captureSession?.startRunning()
        self.view.bringSubviewToFront(self.saveButton)
        self.view.bringSubviewToFront(self.recordButton)
        self.view.bringSubviewToFront(self.previewButton)
        self.view.bringSubviewToFront(self.timeLabel)


    }

    func showMessage(string : String) {
        let alertVC = UIAlertController.init(title: "tishi", message: string, preferredStyle: .alert)
        let action = UIAlertAction.init(title: "nihao", style: UIAlertAction.Style.default, handler: nil)
        alertVC.addAction(action)
        self.present(alertVC, animated: true, completion: nil)
    }
    @IBAction func saveAction(_ sender: Any) {
        self.timer?.invalidate()
        captureSession?.stopRunning()
        captureMovieFileOutPut?.stopRecording()
    }
    @IBAction func previewAction(_ sender: Any) {
        previewLayer?.removeFromSuperlayer()
        playItem = AVPlayerItem.init(url: self.videoUrl!)
        player = AVPlayer.init(playerItem: playItem!)
        playerLayer = AVPlayerLayer.init(player: player!)
        playerLayer?.frame = self.view.frame
        playerLayer?.videoGravity = .resizeAspect
        self.view.layer.masksToBounds = true
        self.view.layer.addSublayer(playerLayer!)
        self.view.bringSubviewToFront(self.saveButton)
        self.view.bringSubviewToFront(self.recordButton)
        self.view.bringSubviewToFront(self.previewButton)

        self.player?.play()

        
    }
    @IBAction func recordAction(_ sender: Any) {

        self.timer = Timer.init(timeInterval: 1, repeats: true, block: { (timer) in
            self.timerInteger = self.timerInteger  + 1
            self.timeLabel.text = "\(String(describing: self.timerInteger))"
        })
        RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.common)
        
        let url = NSURL.fileURL(withPath: NSTemporaryDirectory() + "hh.mov")
        captureMovieFileOutPut?.startRecording(to: url, recordingDelegate: self)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
extension MoviePreviewViewController : AVCaptureFileOutputRecordingDelegate{
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        self.videoUrl = outputFileURL;
       self.saveViedo(url: outputFileURL)
    }
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        
    }
    func saveViedo(url : URL) {
        let status = PHPhotoLibrary.authorizationStatus()
        if  status == .restricted ||  status == .denied {
            showMessage(string: "T##String")
            return
        }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            DispatchQueue.main.async(execute: {
                self.previewButton.isHidden = false

            })
        }) { (bo, error) in
            
        }
        
        
        
    }
    
}
