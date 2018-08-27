//
//  TimersController.swift
//  Intro
//
//  Created by Ahmed Al Dulaimy on 6/30/18.
//  Copyright © 2018 Intro. All rights reserved.
//

import AudioKit
import Repeat

extension ViewController {
    
    func startTimer(){
        
//        self.progressTimer = Timer.scheduledTimer(timeInterval: self.timerUpdateRateInSeconds, target: self, selector: #selector(self.decrementTimer), userInfo: nil, repeats: true)
        
        if (self.progressTimer == nil){
            self.progressTimer = Repeater(interval: .seconds(self.timerUpdateRateInSeconds), mode: .infinite) { _ in
                
                DispatchQueue.main.async {
                    self.decrementTimer();
                }
                
            }
        }
        
        print("\ntimer got the start!")

        self.progressTimer.start();

    }
    
    func stopTimer() {
        
//        if  (self.progressTimer == nil) {
//            self.progressTimer = nil;
//        }
//        else {
//            self.progressTimer.invalidate()
//        }
        
        if  (self.progressTimer != nil) {
            print("\ntimer got the stop!")
            self.progressTimer.pause();
        }

    }
    
    @objc func decrementTimer() {
        
        // ===========================================================
        
        if (self.audioRecorder != nil && self.audioRecorder.isRecording) {
            
            self.recordingButtonElapsedPortion = self.recordingButtonElapsedPortion + (CGFloat(self.timerUpdateRateInSeconds) / self.audioRecordingMaxLengthInSeconds)
            
            recordButton.setProgress(self.recordingButtonElapsedPortion)
            
        }
        
        else {
            
            self.timeToNextPerson = (self.timeToNextPerson-self.timerUpdateRateInSeconds);

                let startingPoint = self.timerBGView.bounds.origin.x
                let portionOfSuperViewElapsed = CGFloat(self.timeToNextPerson/self.timeToNextPersonDefault)*(self.timerBGView.bounds.width);
                
                UIView.animate(withDuration: timerUpdateRateInSeconds, delay: 0.0, options: [.curveEaseOut], animations: {
                    
                    self.timeElapsedBar.frame = CGRect(x: startingPoint, y: 0, width: portionOfSuperViewElapsed, height: self.timerBGView.frame.height );

                }, completion: nil)

        }
        
        
        // ===========================================================

        if self.timeToNextPerson <= 0 && self.waveform.isHidden == false {
            
            // reveal the person!
            self.stopTimer()
            self.hideAllButMenu()
            
            self.removeBlur();

            
        }
            
        else if self.timeToNextPerson <= 0 {
            
            // go on to the next person!
            self.stopTimer()
            self.disconnectFromSession()

        }
        
        // ===========================================================
        
        
        if self.recordingButtonElapsedPortion >= 1 {
            
            self.stop();
            
        }
        
        // ===========================================================
     
    }
    
    
    func removeBlur() {
        
     
            var viewWithTag = self.VideoView.viewWithTag(123123)
        
            UIView.animate(withDuration: 1, delay: 0.0, options: [.curveEaseOut], animations: {
        
                viewWithTag?.alpha = 0;
        
            }, completion: { (finished: Bool) in
                viewWithTag?.removeFromSuperview()
            })
    
        
    }
    
    
    func startWaveAnimation(){
        self.waveTimer = Timer.scheduledTimer(timeInterval: 0.04, target: self, selector: #selector(self.changeWave), userInfo: nil, repeats: true)
    }
    
    
    func stopWaveAnimation(){
        
        if (self.waveTimer != nil){
            self.waveTimer.invalidate()
            self.waveTimer = nil;
        }
        
    }
    
    func randomGen(_ range:Range<Double>) -> Double {
        return range.lowerBound + Int(arc4random_uniform(UInt32(range.upperBound - range.lowerBound)))
    }
    
    @objc func changeWave(){
        let fraction = randomGen(1.0 ..< 2.0)/2.0
        waveform.amplitude = CGFloat(fraction);
    }
    
    
}
