//
//  ViewController.swift
//  ScreenRecordDemo
//
//  Created by Lennon Ling on 2018/7/1.
//  Copyright © 2018年 Lennon Ling. All rights reserved.
//

/**
 ReplayKit
 Within 8 minutes, the user's options will be remembered,that is, every 8 minutes, popup options selection box.
 */

import UIKit
import ReplayKit
import Photos

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func startRecord(_ sender: UIButton) {
        
        if !isSupportRecord() {
            showAlert(title: "Tips", message: "error, not support screen record")
            return
        }
        
        if isRecording() {
            showAlert(title: "Tips", message: "error, in recording screen")
            return
        }
        
        let recorder = RPScreenRecorder.shared()
        recorder.delegate = self
        
        let isMicrophoneEnabled = true // true or false
        
        if #available(iOS 10.0, *) {
            
            recorder.isMicrophoneEnabled = isMicrophoneEnabled
            
            recorder.startRecording { (error) in
                if error == nil {
                    print("start record success")
                } else {
                    print("start record failed")
                }
            }
            
        } else if #available(iOS 9.0, *) {
            
            recorder.startRecording(withMicrophoneEnabled: isMicrophoneEnabled) { (error) in
                // in the child thread
                if error == nil {
                    print("start record success")
                } else {
                    print("start record failed")
                }
            }
            
        } else {
            print("not support")
        }
        
        
    }
    
    @IBAction func stopRecord(_ sender: UIButton) {
        
        if !isRecording() {
            showAlert(title: "Tips", message: "error, no screen recording data")
            return
        }
        
        RPScreenRecorder.shared().stopRecording { [weak self] (previewController, error) in
            guard let previewVC = previewController else { return }
            guard let strongSelf = self else { return }
            if error != nil || previewController == nil {
                print("stop failed")
            } else {
                print("stop success")
                previewVC.previewControllerDelegate = self
                strongSelf.present(previewVC, animated: true, completion: {
                    
                })
            }
        }
        
    }
    
}

extension ViewController: RPScreenRecorderDelegate {
    
    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        print("screenRecorder.isAvailable = \(screenRecorder.isAvailable), screenRecorder.isRecording = \(screenRecorder.isRecording)")
    }
    
    // 11.0
    func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWith previewViewController: RPPreviewViewController?, error: Error?) {
        
    }
    // 9.0
    func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWithError error: Error, previewViewController: RPPreviewViewController?) {
        
    }

}

extension ViewController: RPPreviewViewControllerDelegate {
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        previewController.dismiss(animated: true, completion: nil)
    }
    
    func previewController(_ previewController: RPPreviewViewController, didFinishWithActivityTypes activityTypes: Set<String>) {
        if activityTypes.contains(UIActivityType.saveToCameraRoll.rawValue) {
            print("save")
            saveScreenVideo()
        } else {
            print("cancel save")
        }
    }
}

// MARK: Tools

extension ViewController {
    
    private func isSupportRecord() -> Bool {
        if RPScreenRecorder.shared().isAvailable, #available(iOS 9.0, *) {
            return true
        } else {
            return false
        }
    }
    
    private func isRecording() -> Bool {
        if RPScreenRecorder.shared().isRecording {
            return true
        } else {
            return false
        }
    }
    
    private func saveScreenVideo() {
        
        // TODO: get permissions first
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.includeAssetSourceTypes = PHAssetSourceType.init(rawValue: 0)
        
        let assetsFetchResults = PHAsset.fetchAssets(with: options)
        let asset = assetsFetchResults.firstObject
        guard let ass = asset else { return }
        let assetRescource = PHAssetResource.assetResources(for: ass).first
        
        guard let assetRes = assetRescource else { return }
        
        let filePath = screenVideoPath()
        
        let manager = PHAssetResourceManager.default()
        manager.writeData(for: assetRes, toFile: URL(fileURLWithPath: filePath), options: nil) { (error) in
            if error == nil {
                print("save to sandbox success")
            } else {
                print("save to sandbox failed")
            }
        }
        
    }
    
    private func screenVideoPath() -> String {
        let rootPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        let documentPath = "\(rootPath)/screenRecordFiles"
        let fileManager = FileManager.default
        let exist = fileManager.fileExists(atPath: documentPath)
        if !exist {
            do {
                try fileManager.createDirectory(atPath: documentPath, withIntermediateDirectories: true, attributes: nil)
            } catch {}
        }
        let filePath = documentPath + "/" + UUID().uuidString + ".mp4"
        return filePath
    }
    
    private func showAlert(title: String, message: String) {
        let action = UIAlertAction(title: "ok", style: .cancel, handler: nil)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(action)
        present(alert, animated: false, completion: nil)
    }
    
}

