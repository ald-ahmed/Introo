//
//  AudioRecorder.swift
//  Intro
//
//  Created by Ahmed Al Dulaimy on 6/30/18.
//  Copyright © 2018 Intro. All rights reserved.
//

import Foundation
import AudioKit
import Alamofire

extension ViewController {
 

    //    when I press the record circle
    @objc func record() {

        if (self.noOneConnectedToMe || self.progressTimer == nil){
            return;
        }

        startRecording();
        
    }
    
    
    //    when I the recording timer is over
    @objc func stop() {
        
        print ("\n\n recording button got the stop command")
        
        if (self.noOneConnectedToMe || self.progressTimer == nil){
            return;
        }
        
        if (audioRecorder == nil){
            print("audio was never recording")
            return;
        }
        
        audioRecorder.stop()
        finishRecording(success: true);
        
        self.stopTimer()
        
    }
    
    func startRecording() {
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            
            print("recording!")
            if (audioFilename != nil){
                try FileManager.default.removeItem(at: audioFilename)
            }
            
            let uuid = UUID().uuidString
            audioFilename = getDocumentsDirectory().appendingPathComponent(uuid+".m4a");
            print("recording to "+uuid)
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
//            self.stopTimer()
            
        } catch {
            print("error while recording! ")
            finishRecording(success: false)
        }
        
    }
    
    func finishRecording(success: Bool) {
        
        if (success){
            uploadToStorage(dataURL: audioFilename, sessionID: connectedSessionID)
        }

        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
        
        audioRecorder = nil
        audioPlayer?.stop()
        audioFile = nil
        audioPlayer = nil
        AudioKit.output = nil
        try! AudioKit.stop()
        
    }
    
    func playAudio(url: URL){
        
        self.nameLabel.isHidden = false;
        self.waveform.isHidden = false;

        AKSettings.playbackWhileMuted = true

        print ("\n playing from "+url.absoluteString)

        audioPlayer = try! AKAudioPlayer(file: AKAudioFile(forReading: url)){
            
            self.stopWaveAnimation()
            self.startTimer()
            
        }
        
        audioPlayer?.volume = 500;

        AudioKit.output = audioPlayer
        try! AudioKit.start()
        
        startWaveAnimation();
        
        audioPlayer?.play()
        

    }
    
    
    func downloadAudioFileFromURL(url:URL){
        
        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
        
        Alamofire.download(url, method: .get, to: destination).downloadProgress(
            closure: { (progress) in
                //progress closure
            }).response(completionHandler: { (DefaultDownloadResponse) in
                
                if let s = DefaultDownloadResponse.destinationURL {
                    self.playAudio(url:s)
                }
                
        })

    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    
    
}
