//
//  ViewController.swift
//  Intro
//
//  Created by Ahmed Al Dulaimy on 5/30/18.
//  Copyright © 2018 Intro. All rights reserved.
//

import UIKit
import Contacts

import RecordButton
import SwiftSiriWaveformView
import AVFoundation
import Firebase
import FirebaseStorage
import Alamofire
import AudioKit

import TwilioVideo
import FirebaseFunctions
import NVActivityIndicatorView
import Pastel
import Repeat
import PhoneNumberKit

class ViewController: UIViewController, AVAudioRecorderDelegate, NVActivityIndicatorViewable {
    
    @IBOutlet weak var recordButton: RecordButton!
    @IBOutlet weak var waveform: SwiftSiriWaveformView!
    
    @IBOutlet weak var timerBGView: UIView!

    @IBOutlet weak var timeElapsedBar: UIView!
    @IBOutlet weak var QuestionCardView: UIView!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var VideoView: VideoChatView!
    @IBOutlet weak var PreviewView: UIView!
    
    @IBOutlet weak var buttonImage: UIImageView!
    
    @IBOutlet weak var shareNumber: UIButton!
    
    var audioRecorder: AVAudioRecorder!
    var audioFilename: URL!
    var audioFile: AKAudioFile!
    var audioPlayer: AKAudioPlayer!
    var audioRecordingMaxLengthInSeconds: CGFloat! = 10;
    
    var progressTimer : Repeater!
    var timeToNextPersonDefault : Double = 10;
    var timeToNextPerson : Double!;
    var timerUpdateRateInSeconds : Double = 0.05;
    var recordingButtonElapsedPortion : CGFloat = 0;

    var waveTimer : Timer!
    
    @IBOutlet weak var menuImage: UIImageView!
    
    var LC = LocationController();
    
    var uniqueUserID = UIDevice.current.identifierForVendor!.uuidString;
    
    var ref: DatabaseReference!
    var selfObserver: UInt! ;
    var noOneConnectedToMe = true;
    var connectedSessionID: String!;
    
    var connectedSessionWasRemovedObserver: UInt! ;
    var connectedSessionAddedAudioObserver: UInt! ;
    
    lazy var functions = Functions.functions()
    
    var accessToken: String!;

    var nameOfPerson: String!;
    var isA: Int!;
    var wantsA: Int!;
    var otherPersonsPhoneNumber: String!;

    var numberOfUploadedAudioFiles: Int = 0;

    var questions: [String]!;
    var imIFirstOrSecondParticipant: Int!;
    
    var searching = false;

    var queueTimer_: Repeater!
    
    var activityIndicatorView: NVActivityIndicatorView!;

    
    func initFreshSession() {
        
//        self.recordButton.sendActions(for: UIControlEvents.touchUpInside)
//
        
        if (self.nameOfPerson == nil) {
            let name = UserDefaults.standard.string(forKey: "name") ?? "";
            
            if name != "" {
                self.nameOfPerson = name;
            }
            else {
                self.nameOfPerson = self.uniqueUserID
            }
        }

        self.isA = 0
        self.wantsA = 1
        
        self.shareNumber.isHidden = true;
        self.phoneNumberField.isHidden = true;

        self.connectedSessionID = nil;
        self.noOneConnectedToMe = true;
        
        self.connectedSessionWasRemovedObserver = nil;
        self.connectedSessionAddedAudioObserver = nil;
        self.imIFirstOrSecondParticipant = 0;
        self.numberOfUploadedAudioFiles = 0;
        self.recordingButtonElapsedPortion = 0;
        self.timeToNextPerson = self.timeToNextPersonDefault;
        self.audioRecorder = nil
        self.otherPersonsPhoneNumber = ""
        self.shareNumber.setTitle("Share Number", for: .normal)
        self.removeBlur();
        self.stopWaveAnimation();
        self.hideAllButMenu();
        self.stopTimer();
        
        let startingPoint = timerBGView.bounds.origin.x
        timeElapsedBar.frame = CGRect(x: startingPoint, y: 0, width: timerBGView.bounds.width, height: timerBGView.frame.height);

    }
    
    func hideAllButMenu(){
        
        self.QuestionCardView.layer.isHidden = true;
        self.timerBGView.isHidden = true;
        self.waveform.isHidden = true;
        self.nameLabel.isHidden = true;
//        self.recordButton.isHidden = true;
        
        if (!self.noOneConnectedToMe){
            self.shareNumber.isHidden = false;
        }
        
        self.message.isHidden = false;
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.initFreshSession();
        
        self.ref = Database.database().reference()
        
        do {
            self.disconnectFromSession()
        }
        catch {
            print("no active record")
        }
        
        self.makeYourselfActive();
        self.loadQuestions()
        
        self.VideoView.parentView = self;
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appIsClosing), name: Notification.Name.UIApplicationWillTerminate, object: nil)

//        LC.startLocationTracking();
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        
        
        view.addGestureRecognizer(tap)
        
        
        shareNumber.layer.cornerRadius = 20;
        QuestionCardView.layer.cornerRadius = 20;
        
        QuestionCardView.layer.shadowColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        QuestionCardView.layer.shadowOpacity = 0.5;
        QuestionCardView.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        
        timerBGView.layer.cornerRadius = 5;
        timeElapsedBar.layer.cornerRadius = 5;
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
        
        self.activityIndicatorView = NVActivityIndicatorView(frame: self.QuestionCardView.frame, type: .ballTrianglePath, color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),padding: 50 )
//        activityIndicatorView.addGestureRecognizer(swipeUp)
        activityIndicatorView.isUserInteractionEnabled = false
        self.view.addSubview(activityIndicatorView)
        
        let pastelView = PastelView(frame: view.bounds)
        
        // Custom Direction
        pastelView.startPastelPoint = .bottomLeft
        pastelView.endPastelPoint = .topRight
        
        // Custom Duration
        pastelView.animationDuration = 3.0
        
        // Custom Color
        pastelView.setColors([
                               #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),
                                #colorLiteral(red: 0.5058823529, green: 0.9450980392, blue: 0.6588235294, alpha: 1),
                                #colorLiteral(red: 0.5058823529, green: 0.9450980392, blue: 0.8013113839, alpha: 1),
                                #colorLiteral(red: 0.5514229911, green: 0.6056919643, blue: 0.8013113839, alpha: 1),
                                 #colorLiteral(red: 0.7871372768, green: 0.5, blue: 0.6588235294, alpha: 1),
                                 #colorLiteral(red: 0.2470588235, green: 0.6784313725, blue: 0.8666852679, alpha: 1),
            ])
        
        pastelView.startAnimation()
        VideoView.insertSubview(pastelView, at: 0)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardWasShown(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillChangeFrame,
                                               object: nil)

//        recordButton.progressColor = UIColor.white
//
//        recordButton.addTarget(self, action: #selector(self.record), for: UIControlEvents.touchDown)
//        recordButton.addTarget(self, action: #selector(self.stop), for: UIControlEvents.touchUpInside)
//        recordButton.addTarget(self, action: #selector(self.stop), for: UIControlEvents.touchUpOutside)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        menuImage.isUserInteractionEnabled = true
        menuImage.addGestureRecognizer(tapGestureRecognizer)

        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
//            try AVAudioSession.sharedInstance().setInputGain(0.3);
            
            try AVAudioSession.sharedInstance().setActive(true)
            AVAudioSession.sharedInstance().requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
//                        self.loadRecordingUI()
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            // failed to record!
        }
        
        
        
 
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
    
        self.ref.child("users").child(self.uniqueUserID).child("name").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
                let existence = snapshot.value as? String ?? ""
            print("existence", existence)
            
                if (existence == "" || snapshot.value == nil ){
                    self.endMatching()
                    self.performSegue(withIdentifier: "goToSettings", sender: self)
                }
                    
                else {
                    self.startMatching()
                }
            
            });
        
//
//
//        if self.nameOfPerson == self.uniqueUserID {
//            performSegue(withIdentifier: "goToSettings", sender: self)
//        }
//

    }
    
    @IBOutlet weak var shareNumberBottomConstraint: NSLayoutConstraint!
    
    @objc func keyboardWasShown(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.shareNumberBottomConstraint.constant = keyboardFrame.size.height + 30
        })
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.shareNumberBottomConstraint.constant = 100
        })
        
        self.shareNumber.isEnabled = true;

        
    }
    
    
    func getContacts() -> [String] {
        var storedContacts = [String]()
        let contactStore = CNContactStore()
        var contacts = [CNContact]()
        let keys = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey
            ] as [Any]
        let request = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        do {
            try contactStore.enumerateContacts(with: request){
                (contact, stop) in
                // Array containing all unified contacts from everywhere
                contacts.append(contact)
                for phoneNumber in contact.phoneNumbers {
                    if let number = phoneNumber.value as? CNPhoneNumber, let label = phoneNumber.label {
                        let localizedLabel = CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: label)
                        print("\(contact.givenName) \(contact.familyName) tel:\(localizedLabel) -- \(number.stringValue), email: \(contact.emailAddresses)")
                        
                        storedContacts.append(number.stringValue)
                        
                    }
                }
            }
            
        } catch {
            print("unable to fetch contacts")
        }
        
        return storedContacts
    }
    
    
    func updateUserProfile() {
        
        let name = UserDefaults.standard.string(forKey: "name") ?? ""
//        if name == self.nameOfPerson { return }
        
        print("updating")
        self.ref.child("users").child(self.uniqueUserID).setValue(["name": String(self.nameOfPerson), "isA": self.isA, "wantsA": self.wantsA, "contacts": self.getContacts()])
        print("finished updating")

        UserDefaults.standard.set(self.nameOfPerson, forKey: "name")

    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        
        if gesture.direction == UISwipeGestureRecognizerDirection.right {
            
            print("Swipe Right")
            
        }
            
        else if gesture.direction == UISwipeGestureRecognizerDirection.left {
            print("Swipe Left")
            
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()

            self.disconnectFromSession()
        }
            
        else if gesture.direction == UISwipeGestureRecognizerDirection.up {
            print("Swipe Up")
            
//            performSegue(withIdentifier: "showMessages", sender: self)

        }
            
        else if gesture.direction == UISwipeGestureRecognizerDirection.down {
            print("Swipe Down")
            
            performSegue(withIdentifier: "goToSettings", sender: self)
        }
        
    }

    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
//        let tappedImage = tapGestureRecognizer.view as! UIImageView
        
        performSegue(withIdentifier: "goToSettings", sender: self)
    }

    
    
    @objc func appMovedToBackground() {
        
        print ("background")
        
        self.endMatching()

    }

        
    @objc func appMovedToForeground() {
        
        print ("foregorund")
        
        if !self.menuImage.isHidden {
            self.startMatching()
        }
        
        



        
    }
    
    @objc func appIsClosing() {
        
        print ("appIsClosing")

        self.endMatching()

        self.ref.child("active").child(uniqueUserID).removeValue()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        self.endMatching();
        self.hideLoadingAnimation();
        
        self.menuImage.isHidden = true;
        
    }
    
    @IBOutlet weak var phoneNumberField: PhoneNumberTextField!
    
    func showNumberAlert(){
        
        self.phoneNumberField.isHidden = false;
        self.phoneNumberField.becomeFirstResponder()

    }
    
    func checkNumber(text: String) -> String{
        
        do {
            let phoneNumber = try PhoneNumberKit().parse(text)
            return phoneNumber.adjustedNationalNumber()
        }
        catch {
            return "error"
        }
        
    }
    
    
    
    func updatePhoneNumber(phoneNumber: String){
        
        let selfRef = self.ref.child("users").child(self.uniqueUserID);
        selfRef.child("phoneNumber").setValue(phoneNumber)
        
    }
    
    
    func submitPhoneNumberToSession(phoneNumber: String){
 
        let sessionRef =  self.ref.child("sessions").child(self.connectedSessionID)
        sessionRef.child("phoneNumber"+String(self.imIFirstOrSecondParticipant)).setValue(phoneNumber)

        
        self.shareNumber.setTitle("Waiting for " + self.nameLabel.text!.replacingOccurrences(of: ":", with:"")   , for: .normal)
        
        
        self.phoneNumberField.text = "";
        self.phoneNumberField.isHidden = true;
        self.dismissKeyboard();
        
    }

    func textOtherPerson(){
        
        let phoneNumber = self.otherPersonsPhoneNumber
        let text = "Say something to " + self.nameLabel.text!

        
        let sms: String = "sms:"+phoneNumber!+"&body="+text
        let strURL: String = sms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        UIApplication.shared.open(URL.init(string: strURL)!, options: [:], completionHandler: nil)

        
    }
    @IBAction func shareNumberPressed(_ sender: Any) {
        
        if (self.shareNumber.titleLabel?.text != "Share Number" && self.shareNumber.titleLabel?.text != "Open in IMessage"){
            return;
        }
        else if (self.shareNumber.titleLabel?.text == "Open in IMessage"){
            
            textOtherPerson();
            
            return;
        }
        
        self.shareNumber.isEnabled = false;
        
        if (self.noOneConnectedToMe) {
            print("shareNumberPressed", "no one is connectedToMe" )
            return;
        }
        
        
        if (self.phoneNumberField.isHidden == false && checkNumber(text: self.phoneNumberField.text!) != "error"){
            
            self.updatePhoneNumber(phoneNumber: self.checkNumber(text: self.phoneNumberField.text!))
            self.submitPhoneNumberToSession(phoneNumber: self.checkNumber(text: self.phoneNumberField.text!))
            
            
            self.shareNumber.isEnabled = true;

            return;
        }
        else if (self.phoneNumberField.isHidden == false && checkNumber(text: self.phoneNumberField.text!) == "error"){
            self.phoneNumberField.text = ""
            self.phoneNumberField.placeholder = "Try again"
            
            return;
        }
        
        
        let selfRef = self.ref.child("users").child(self.uniqueUserID);

        selfRef.child("phoneNumber").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
            let phoneNumber = snapshot.value as? String ?? ""
            print("existence", phoneNumber)
            
            if (phoneNumber == "" || snapshot.value == nil ){
                self.showNumberAlert()
            }
                
            else {
                
                if (self.checkNumber(text: phoneNumber) != "error"){
                    self.submitPhoneNumberToSession(phoneNumber: self.checkNumber(text: phoneNumber))
                }
                else {
                    self.showNumberAlert()
                }
                
            }
        
            self.shareNumber.isEnabled = true;

        });
        
        
    }
    
    
    @objc func startMatching() {
        
        print ("startMatching")
        print ("name is ", self.nameOfPerson)

        
        UIView.animate(withDuration: 1, delay: 0.0, options: [.curveEaseOut], animations: {
            self.menuImage.alpha = 0;
            self.menuImage.alpha = 1;
            self.menuImage.isHidden = false;
            
        }, completion: nil)
        
        
        if (self.queueTimer_ == nil) {
            
            self.queueTimer_ = Repeater(interval: .seconds(0.5), mode: .infinite) { _ in
                self.queue();
            }
            
        }
        
        self.queueTimer_.start()


    }
    
    
    @objc func endMatching(){
        
        if (self.queueTimer_ != nil){
            self.queueTimer_.pause();
        }
    
        self.disconnectFromSession()

    }

    
    @objc func queue(){
        
        if (!self.noOneConnectedToMe) {
            return;
        }

    self.ref.child("active").child(self.uniqueUserID).child("active").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            let activeStatus = snapshot.value as? String ?? ""

            if (activeStatus == "1" || activeStatus == "0"){

                if (activeStatus == "0") {
                    self.ref.child("active").child(self.uniqueUserID).child("active").setValue("1")
                }
                else {
                    self.showLoadingAnimation();
                }

                self.ref.child("active").child(self.uniqueUserID).child("timestamp").setValue(self.date())
                
            }
        });
        
        
        
    }
    
    
    func loadQuestions(){
        
        let questionsRef =  self.ref.child("questions")
        
        questionsRef.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            self.questions = snapshot.value as! [String]
            
        });
        
    }
    
    func makeYourselfActive() {
        
        print("\n making myself active!")
        
        let selfRef = self.ref.child("active").child(self.uniqueUserID);
        let tokenRef =  selfRef.child("tokenID")
        
        VideoView.setToken(uniqueUserID: self.uniqueUserID) { token, error in
            
            self.noOneConnectedToMe = true;
            tokenRef.setValue(token)
            
        };
        
        
        selfObserver = selfRef.observe(DataEventType.childChanged, with: { (snapshot) in
            
            if snapshot.key == "active" {
                let sessionID = snapshot.value as? String ?? "0"
                print("my active status was changed to: ", sessionID)
                
                if (sessionID != "0" && sessionID != "1") {
                    print ("active was changed, snapshot value: ", sessionID)
                    self.connectToSession(sessionID: sessionID);
                }

            }
            
        });
        
    }
    
    
    @IBOutlet weak var message: UILabel!
    
    func showLoadingAnimation(){
        
        if self.activityIndicatorView.isAnimating { return }
        self.activityIndicatorView.startAnimating()
       self.message.isHidden = false;

    }
    
    
    func hideLoadingAnimation(){
        
        self.activityIndicatorView.stopAnimating()
        self.message.isHidden = true;
        
    }
    
    
    func connectToSession(sessionID: String) {
        
        self.connectedSessionID = sessionID;
        
        let sessionRef =  self.ref.child("sessions").child(self.connectedSessionID)
        
        print ("\n\n connected to session", sessionID)

        self.noOneConnectedToMe = false;
        
        VideoView.connectOrCreateRoom(roomName: sessionID)
        
        connectedSessionWasRemovedObserver = sessionRef.observe(DataEventType.childRemoved, with: { (snapshot) in
            
            self.disconnectFromSession();
            
        });
        
        var linksToAudio = [String: String]()
        
        connectedSessionAddedAudioObserver = sessionRef.observe(DataEventType.childAdded, with: { (snapshot) in
            
            print("added key to session: ", snapshot.key, " with value ", snapshot.value ?? "null")
            
            let key = snapshot.key
            let value = (snapshot.value as? String ?? "")
            
            
            if (key == "audio1") {
                linksToAudio["audio1"] = value;
                self.numberOfUploadedAudioFiles+=1
            }
            
            if (key == "audio2") {
                linksToAudio["audio2"] = value;
                self.numberOfUploadedAudioFiles+=1
            }
            
            
            if (self.numberOfUploadedAudioFiles == 2) {
                
                if (self.imIFirstOrSecondParticipant == 1){
                    self.downloadAudioFileFromURL(url: URL(string: linksToAudio["audio2"]!)! )
                    
                }
                else if (self.imIFirstOrSecondParticipant == 2){
                    self.downloadAudioFileFromURL(url: URL(string: linksToAudio["audio1"]!)! )
                }
                
            }
            
            
            if (key == "question") {
                
                self.questionLabel.text = value
                
            }
            
            
            if (key == "phoneNumber1" && 1 != self.imIFirstOrSecondParticipant) {
                
                self.otherPersonsPhoneNumber = value;
                self.shareNumber.setTitle("Open in IMessage", for: .normal)
                
            }
            
            if (key == "phoneNumber2" && 2 != self.imIFirstOrSecondParticipant) {
                
                self.otherPersonsPhoneNumber = value;
                self.shareNumber.setTitle("Open in IMessage", for: .normal)

            }
            
            
            if (key == "p2-ID" && value != self.uniqueUserID){
                
                self.ref.child("users").child(value).child("name").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                    self.nameLabel.text = (snapshot.value as? String ?? "") + ": "
                });
                
                self.imIFirstOrSecondParticipant = 1
                
                let question = self.questions.randomElement();
                sessionRef.child("question").setValue(question)

            }
                
            else if (value == self.uniqueUserID){
                self.imIFirstOrSecondParticipant = 2
            }
            
            if (key == "p1-ID" && value != self.uniqueUserID) {
                
                self.ref.child("users").child(value).child("name").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                    self.nameLabel.text = (snapshot.value as? String ?? "") + ": "
                });
                
            }
            
        });
        
        
    }
    
    func readyToConversate(){
        
        self.hideLoadingAnimation();

        self.QuestionCardView.layer.isHidden = false;
        self.timerBGView.isHidden = false;
        
        self.nameLabel.isHidden = false;
        self.waveform.isHidden = false;
        self.startWaveAnimation();
        
//        self.recordButton.isHidden = false;
        
        self.startTimer();
        
    }
    
    
    @objc func disconnectFromSession() {
        
//        self.showLoadingAnimation();

        print ("\n\n\n disconnecting!!!!!\n\n " , noOneConnectedToMe )
        
        
        if (self.connectedSessionID != nil) {
            self.ref.child("sessions").child(self.connectedSessionID).removeValue()
            self.connectedSessionID = nil
        }
        
        self.VideoView.disconnect()
        self.initFreshSession()

        self.ref.child("active").child(self.uniqueUserID).child("active").setValue("0"){ (error, ref) -> Void in

        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}




extension ViewController {
    
    func date() -> String!{
        let now = Date()
        
        let formatter = DateFormatter()
        
        formatter.timeZone = TimeZone.current
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let dateString = formatter.string(from: now)
        return dateString
    }

}



