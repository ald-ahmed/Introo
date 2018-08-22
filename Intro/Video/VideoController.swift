//
//  VideoController.swift
//  Intro
//
//  Created by Ahmed Al Dulaimy on 6/9/18.
//  Copyright © 2018 Intro. All rights reserved.
//

import UIKit
import TwilioVideo
import FirebaseFunctions
import Alamofire

class VideoChatView: UIView, TVIRemoteParticipantDelegate, TVIVideoViewDelegate, TVIRoomDelegate {
    
    // Video SDK components
    var room: TVIRoom?
    var camera: TVICameraCapturer?
    var localVideoTrack: TVILocalVideoTrack?
    var localAudioTrack: TVILocalAudioTrack?
    var remoteParticipant: TVIRemoteParticipant?
    var remoteView: TVIVideoView?
    var didConnectToRoom: Bool = false;
    var parentView: ViewController!;
    
    lazy var functions = Functions.functions()

    var accessToken:String!
    
    
    func setToken(uniqueUserID: String!, completionHandler: @escaping (String!, Error?) -> ()) {
        
        
        if let camera = TVICameraCapturer(source: .frontCamera){
            self.localVideoTrack = TVILocalVideoTrack(capturer: camera)
        }
        
        self.localAudioTrack = TVILocalAudioTrack.init(options: nil, enabled: true, name: "Microphone")

        
        
        Alamofire.request("https://us-central1-intro-69d9e.cloudfunctions.net/tokenGenerator", parameters: ["userID": uniqueUserID])
            
            .responseJSON { response in
                
                if (response.result.error != nil) {
                    // got an error in getting the data, need to handle it
                    print(response.result.error!)

                    return
                }
                
                // make sure we got some JSON since that's what we expect
                guard let json = response.result.value as? [String: Any] else {
                    if let error = response.result.error {
                        print("Error: \(error)")
                    }
                    
                    return
                }
                
                // get and print the title
                guard let key = json["data"] as? String else {
                    print("Could not get todo title from JSON")

                    return
                }
                
                //                print("The data is: " + key)
                self.accessToken = key;
                completionHandler(key, nil);
                
        }
        
        
    }
    
    
    func getToken(uniqueUserID: String!) {
        
        
        
    }
    
    
    func connectOrCreateRoom(roomName: String) {
        
        let connectOptions = TVIConnectOptions.init(token: accessToken) { (builder) in
            builder.roomName = roomName
            builder.audioTracks = self.localAudioTrack != nil ? [self.localAudioTrack!] : [TVILocalAudioTrack]()
            builder.videoTracks = self.localVideoTrack != nil ? [self.localVideoTrack!] : [TVILocalVideoTrack]()
        }
    
        room = TwilioVideo.connect(with: connectOptions, delegate: self)

        
//        if let camera = TVICameraCapturer(source: .frontCamera),
//            let videoTrack = TVILocalVideoTrack(capturer: camera) {
//            
//            // TVIVideoView is a TVIVideoRenderer and can be added to any TVIVideoTrack.
//            let renderer = TVIVideoView(frame: self.parentView.PreviewView.bounds)
//            
//            // Add renderer to the video track
//            videoTrack.addRenderer(renderer)
//            
//            self.localVideoTrack = videoTrack
//            self.camera = camera
//            self.parentView.PreviewView.addSubview(renderer)
//            
//        } else {
//            print("Couldn't create TVICameraCapturer or TVILocalVideoTrack")
//        }
        
        
    }
    
    func disconnect(){
        room = nil;
    }
    
    func didConnectToRoom(room: TVIRoom) {
        print("Did connect to room")
    }
    
    func didConnect(to room: TVIRoom) {
        
        // The Local Participant
        if let localParticipant = room.localParticipant {
            print("Local identity \(localParticipant.identity)")
        }
        
        // Connected participants
        let participants = room.remoteParticipants;
        print("Number of connected Participants \(participants.count)")
        
        if (participants.count == 1) {
//            self.parentView.readyToConversate();
        }
        
        if (room.remoteParticipants.count > 0) {
            self.remoteParticipant = room.remoteParticipants[0]
            self.remoteParticipant?.delegate = self
        }
        
        
    }
    
    func room(_ room: TVIRoom, participantDidConnect participant: TVIRemoteParticipant) {
        print ("Participant \(participant.identity) has joined Room \(room.name)")
        participant.delegate = self
        
//        self.parentView.readyToConversate();

    }
    
    func room(_ room: TVIRoom, participantDidDisconnect participant: TVIRemoteParticipant) {
        print ("Participant \(participant.identity) has left Room \(room.name)")
        
        self.parentView.disconnectFromSession();
        
    }

    // MARK: TVIRemoteParticipantDelegate
    
    /*
     * In the Participant Delegate, we can respond when the Participant adds a Video
     * Track by rendering it on screen.
     */
    func participant(_ participant: TVIParticipant, addedVideoTrack videoTrack: TVIVideoTrack) {
        print("Participant \(participant.identity) added video track participant")
        
        self.remoteView = TVIVideoView(frame: self.bounds, delegate: self)
        videoTrack.addRenderer(self.remoteView!)
        
        self.addSubview(self.remoteView!)
        
    }

    
    /*
     * In the Participant Delegate, we can respond when the Participant adds a Video
     * Track by rendering it on screen.
     */
    
    func subscribed(to videoTrack: TVIRemoteVideoTrack,
                    publication: TVIRemoteVideoTrackPublication,
                    for participant: TVIRemoteParticipant) {
        
        print("Participant \(participant.identity) added a video track.")
        
        self.remoteView = TVIVideoView.init(frame: self.bounds,
                                            delegate:self)
        
        self.remoteView?.contentMode = .scaleAspectFill;
        videoTrack.addRenderer(self.remoteView!)
        self.addSubview(self.remoteView!)
        
        self.setNeedsLayout()
        
    }
    
    // MARK: TVIVideoViewDelegate
    // Lastly, we can subscribe to important events on the VideoView
    func videoView(_ view: TVIVideoView, videoDimensionsDidChange dimensions: CMVideoDimensions) {
        print("The dimensions of the video track changed to: \(dimensions.width)x\(dimensions.height)")
        self.setNeedsLayout()
    }
    
    
    func videoViewDidReceiveData(_ view: TVIVideoView) {
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        //always fill the view
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.tag = 100
        self.addSubview(blurEffectView)
        
        
        self.parentView.readyToConversate();
        // This method is called just once. Make the view visible or animate a transition onscreen here.
        view.isHidden = false
    }

    
}

