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
import AnimatedCollectionViewLayout


class ViewController: UIViewController, AVAudioRecorderDelegate, NVActivityIndicatorViewable, UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    
    @IBOutlet weak var ActiveCollectionView: ActiveCollectionView!
    
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
    var emoji: Int!;
    
    var otherPersonsPhoneNumber: String!;

    var numberOfUploadedAudioFiles: Int = 0;

    var questions: [String]!;
    var imIFirstOrSecondParticipant: Int!;
    
    var searching = false;

    var queueTimer_: Repeater!
    
    var activityIndicatorView: NVActivityIndicatorView!;
    
    var users = [""]
    
    var emojiCodeWomen = ["👩","👩🏻","👩🏼","👩🏽","👩🏾","👩🏿"]
    var emojiCodeWomenCounter = 0;
    
    var emojiCodeMen = ["👨","👨🏻","👨🏼","👨🏽","👨🏾","👨🏿"]
    var emojiCodeMenCounter = 0;
 
    var startLocation: CGPoint!

    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true

        self.ActiveCollectionView.delegate = self;
        self.ActiveCollectionView.dataSource = self;

        self.ref = Database.database().reference()
        self.initFreshSession();
        
        self.setActiveToOff()

        self.makeYourselfActive();
        self.loadQuestions()
        
        self.VideoView.parentView = self;
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appIsClosing), name: Notification.Name.UIApplicationWillTerminate, object: nil)

//        LC.startLocationTracking();
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        
        tap.cancelsTouchesInView = false

        view.addGestureRecognizer(tap)
        
        PreviewView.isHidden = true;
        PreviewView.layer.cornerRadius = 5;
        PreviewView.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0.168627451, blue: 0.1607843137, alpha: 1)
        PreviewView.layer.shadowOpacity = 0.5;
        PreviewView.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)

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
        
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.draggedView(_:)))
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(panGesture)

        
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
            try AVAudioSession.sharedInstance().setInputGain(1.0);
            
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
        
        print("view did appear view controller")
        
        self.ref.child("users").child(self.uniqueUserID).child("name").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
                let existence = snapshot.value as? String ?? ""
            print("existence", existence)
            
                if (existence == "" || snapshot.value == nil ){
                    self.endMatching()
                    self.performSegue(withIdentifier: "goToSettings", sender: self)
                }
                    
                else {
                    
                    if (!self.menuImage.isHidden){
                        self.startMatching()
                    }
                    
                    self.VideoView.createPreview();
                }
            
            });

    }
    
    func initFreshSession() {
        
        //        self.recordButton.sendActions(for: UIControlEvents.touchUpInside)
        
        if (self.nameOfPerson == nil) {
            let name = UserDefaults.standard.string(forKey: "name") ?? "";
            
            if name != "" {
                self.nameOfPerson = name;
            }
            else {
                self.nameOfPerson = self.uniqueUserID
            }
        }
        
        self.isA = UserDefaults.standard.integer(forKey: "isA")
        self.wantsA = UserDefaults.standard.integer(forKey: "wantsA")
        
        self.shareNumber.isHidden = true;
        self.phoneNumberField.isHidden = true;
        self.PreviewView.isHidden = true;
        
        self.connectedSessionID = nil;
        self.noOneConnectedToMe = true;
        
        self.connectedSessionWasRemovedObserver = nil;
        self.connectedSessionAddedAudioObserver = nil;
        self.imIFirstOrSecondParticipant = 0;
        self.numberOfUploadedAudioFiles = 0;
        self.recordingButtonElapsedPortion = 0;
        self.timeToNextPerson = self.timeToNextPersonDefault;
        self.audioRecorder = nil
        self.otherPersonsPhoneNumber = nil
        self.resetShareNumber();
        self.shareNumber.setTitle("Share Number", for: .normal)
        self.removeBlur();
        self.stopWaveAnimation();
        self.hideAllButMenu();
        self.stopTimer();
        
        self.updateActiveCollection()
        
        let startingPoint = timerBGView.bounds.origin.x
        timeElapsedBar.frame = CGRect(x: startingPoint, y: 0, width: timerBGView.bounds.width, height: timerBGView.frame.height);
        
    }
    

    @objc func draggedView(_ sender:UIPanGestureRecognizer){
        
//        self.view.bringSubview(toFront: viewDrag)
//        let translation = sender.translation(in: self.view)
//        self.view.center = CGPoint(x: self.view.center.x + translation.x, y: self.view.center.y + translation.y)
//        sender.setTranslation(CGPoint.zero, in: self.view)

        
        if (sender.state == UIGestureRecognizerState.began) {
            startLocation = sender.location(in: self.view)
        }
        else if (sender.state == UIGestureRecognizerState.ended) {
            let stopLocation = sender.location(in: self.view)
            let dx = stopLocation.x - startLocation.x;
//            let dy = stopLocation.y - startLocation.y;
            let distance = sqrt(dx*dx);
            NSLog("Distance: %f", distance);
            
            if distance > self.view.frame.width*0.5 {
                
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
                self.disconnectFromSession()

            }
            

        }
        
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
        
        print ("hide all but menu")
        if (self.menuImage.isHidden == false){
            self.message.isHidden = false;
        }
        
        if (!noOneConnectedToMe){
            self.PreviewView.isHidden = false;
            self.PreviewView.subviews.first?.isHidden = false;
        }
        
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
        
        resetShareNumber();
        
    }
    
    func resetShareNumber(){
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.shareNumberBottomConstraint.constant = 30
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
    
    
    
    func updateActiveCollection(){
        
        users.removeAll(keepingCapacity: true)

        self.ref.child("active").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
            if let value = snapshot.value as? NSDictionary{
                for activeUser in value {
                    
                    if activeUser.key as! String == self.uniqueUserID {
                        continue
                    }
                    
                    let record = activeUser.value as! NSDictionary
                    
                    if record["active"] as? String ?? "0" == "1" && activeUser.key != nil{
                        
                        self.addEmojiToCollection(userID: activeUser.key as! String)
                        
                    }
                    
                    
                    if self.users.count > 10 {
                        return;
                    }
                    
                }
            }
            
            self.users.insert("", at: 0)
            
            print ("active users: ", self.users)
            self.ActiveCollectionView.reloadData()
            
        });
        
        
    }
    
    
    func updateUserProfile() {
        
        print("updating")
        
        self.emojiCodeWomenCounter %= self.emojiCodeWomen.count
        self.emojiCodeMenCounter %= self.emojiCodeMen.count
        
        let userRef = self.ref.child("users").child(self.uniqueUserID)
        
        userRef.child("name").setValue(String(self.nameOfPerson))
        userRef.child("isA").setValue(self.isA)
        userRef.child("wantsA").setValue(self.wantsA)
        userRef.child("contacts").setValue(self.getContacts())

        
        if self.isA == 1 {
            userRef.child("emoji").setValue(self.emojiCodeWomen[self.emojiCodeWomenCounter])
        }
        else {
            userRef.child("emoji").setValue(self.emojiCodeMen[self.emojiCodeMenCounter])
        }
        
        
        print("finished updating")

        UserDefaults.standard.set(self.nameOfPerson, forKey: "name")
        UserDefaults.standard.set(self.isA, forKey: "isA")
        UserDefaults.standard.set(self.wantsA, forKey: "wantsA")
        UserDefaults.standard.set(self.emojiCodeMenCounter, forKey: "emojiCodeMenCounter")
        UserDefaults.standard.set(self.emojiCodeWomenCounter, forKey: "emojiCodeWomenCounter")

    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        
        if gesture.direction == UISwipeGestureRecognizerDirection.right {
            
            print("Swipe Right")
            
        }
            
        else if gesture.direction == UISwipeGestureRecognizerDirection.left {
            print("Swipe Left")
            
//            let generator = UIImpactFeedbackGenerator(style: .heavy)
//            generator.impactOccurred()

//            self.disconnectFromSession()
        }
            
        else if gesture.direction == UISwipeGestureRecognizerDirection.up {
            print("Swipe Up")
            
            performSegue(withIdentifier: "goToSettings", sender: self)

//            performSegue(withIdentifier: "showMessages", sender: self)

        }
            
        else if gesture.direction == UISwipeGestureRecognizerDirection.down {
            print("Swipe Down")
            
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
    
    
    func submitPhoneNumberToSession(phoneNumber: String) {
 
        let sessionRef =  self.ref.child("sessions").child(self.connectedSessionID)
        sessionRef.child("phoneNumber"+String(self.imIFirstOrSecondParticipant)).setValue(phoneNumber)
        
        if (self.otherPersonsPhoneNumber == nil){
            self.shareNumber.setTitle("Waiting for " + self.nameLabel.text!.replacingOccurrences(of: ":", with:"")   , for: .normal)
        }
        else {
            self.shareNumber.setTitle("Open in IMessage" , for: .normal)
        }
        
        self.phoneNumberField.text = "";
        self.phoneNumberField.isHidden = true;
        self.dismissKeyboard();
        
    }

    func textOtherPerson(){
        
        let selfRef = self.ref.child("sessions").child(self.connectedSessionID);
        selfRef.child("openedInIMessage").setValue("1")
        
        let phoneNumber = self.otherPersonsPhoneNumber
        let text = "Here's " + self.nameLabel.text!.replacingOccurrences(of: ":", with: "").trim() + "'s number, good luck!"
        
        let sms: String = "sms:"+phoneNumber!+"&body="+text
        let strURL: String = sms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        self.resetShareNumber();

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

        self.menuImage.alpha = 0;
//        self.PreviewView.alpha = 0;
        self.message.alpha = 0;
        self.ActiveCollectionView.isHidden = false;

        UIView.animate(withDuration: 1, delay: 0.0, options: [.curveEaseOut], animations: {
            self.menuImage.alpha = 1;
            self.menuImage.isHidden = false;
            
//            self.PreviewView.alpha = 1;
//            self.PreviewView.isHidden = false;

            self.message.alpha = 1;
            print ("unhide from startMatching()")
            self.message.isHidden = false;

        }, completion: nil)
        
        
        if (self.queueTimer_ == nil) {
            
            self.queueTimer_ = Repeater(interval: .seconds(0.5), mode: .infinite) { _ in
                self.queue();
            }
            
        }
        
        self.queueTimer_.start()

    }
    
    
    @objc func endMatching(){
        
        self.message.isHidden = true;
        self.PreviewView.isHidden = true;
        self.ActiveCollectionView.isHidden = true;
        
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
                
                self.ref.child("active").child(self.uniqueUserID).child("isA").setValue(self.isA)
                
                self.ref.child("active").child(self.uniqueUserID).child("wantsA").setValue(self.wantsA)
                
                
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
        print ("unhide from showLoadingAnimation()")

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
                
                if (self.shareNumber.titleLabel?.text == "Waiting for " + self.nameLabel.text!.replacingOccurrences(of: ":", with:"") ){
                    self.shareNumber.setTitle("Open in IMessage", for: .normal)
                }
                
            }
            
            if (key == "phoneNumber2" && 2 != self.imIFirstOrSecondParticipant) {
                
                self.otherPersonsPhoneNumber = value;

                if (self.shareNumber.titleLabel?.text == "Waiting for " + self.nameLabel.text!.replacingOccurrences(of: ":", with:"") ){
                    self.shareNumber.setTitle("Open in IMessage", for: .normal)
                }
                
            }
            
            
            if (key == "openedInIMessage") {
                
                var val = "1";
                
                if self.imIFirstOrSecondParticipant == 1 {
                    val = "2";
                }
                
            sessionRef.child("phoneNumber"+val).observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                
                    self.otherPersonsPhoneNumber = (snapshot.value as? String ?? "")
                    print(val, " texting ", self.otherPersonsPhoneNumber)
                    self.textOtherPerson();

            });

                
            }
            
            
            if (key == "p2-ID" && value != self.uniqueUserID){
                
                self.ref.child("users").child(value).child("name").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                    self.nameLabel.text = (snapshot.value as? String ?? "") + ": "

                    self.setCurrentEmoji(userID: value)
                    
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
                
                
                self.setCurrentEmoji(userID: value);
                });
                
            }
            
        });
        
        
    }
    
    
    func setCurrentEmoji(userID: String){
        
        self.ref.child("users").child(userID).child("emoji").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
            
            if let inList = self.users.index(of: (snapshot.value as? String ?? "")) {
                if inList > 0 && inList < self.users.count {
                    self.users.remove(at: inList)
                }
            }

            self.users[0] = (snapshot.value as? String ?? "")
            
            self.ActiveCollectionView.reloadData()
            
        });
        
    }
    
    func addEmojiToCollection(userID: String) {
        
        self.ref.child("users").child(userID).child("emoji").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
            self.users.append((snapshot.value as? String ?? ""))
            self.ActiveCollectionView.reloadData()
            
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
        self.ActiveCollectionView.isHidden = true;
        
        self.startTimer();
        
    }
    
    
    @objc func disconnectFromSession() {
        
//        self.showLoadingAnimation();

        print ("\n\n\n disconnecting!!!!!\n\n " , noOneConnectedToMe )
        
        self.PreviewView.isHidden = true;
        self.PreviewView.subviews.first?.isHidden = true;

        if (self.connectedSessionID != nil) {
//            self.ref.child("sessions").child(self.connectedSessionID).removeValue()
            self.connectedSessionID = nil
        }
        
        self.VideoView.disconnect()
        self.initFreshSession()

        self.setActiveToOff()
        
    }
    
    func setActiveToOff(){
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



