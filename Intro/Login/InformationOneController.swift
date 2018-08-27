//
//  InformationOneController.swift
//  Intro
//
//  Created by Ahmed Al Dulaimy on 6/11/18.
//  Copyright © 2018 Intro. All rights reserved.
//

import UIKit
import BetterSegmentedControl
import Firebase
import PhoneNumberKit

class InformationOneController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var isA: BetterSegmentedControl!
    @IBOutlet weak var wantsA: BetterSegmentedControl!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var phoneField: PhoneNumberTextField!

    @IBOutlet weak var noteOnEmojiChange: UILabel!
    @IBOutlet weak var viewForName: UIView!
    @IBOutlet weak var hiMyNameIs: UILabel!
    @IBOutlet weak var myPhone: UILabel!
    @IBOutlet weak var imaandiwanna: UILabel!
    
    @IBOutlet weak var tapAwayMessage: UILabel!
    
    var countryCode = ""
    var nationalNumber = ""
    
    var countryCodeConfirmed = ""
    var nationalNumberConfirmed = ""

    var ref: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()

        let name = UserDefaults.standard.string(forKey: "name") ?? "";
        self.nameField.text = name;
        self.nameField.delegate = self;
        
       
        let fontSize = CGFloat(24.0)
        let fontName = "HelveticaNeue-Medium"
        
        self.isA.titleFont =  UIFont(name: fontName, size: fontSize)!
        self.isA.selectedTitleFont =  UIFont(name: fontName, size: fontSize)!
        self.isA.titles = ["👨", "👩"]
        
        self.wantsA.titleFont =  UIFont(name: fontName, size: fontSize)!
        self.wantsA.selectedTitleFont =  UIFont(name: fontName, size: fontSize)!
        self.wantsA.titles = ["👨", "👩"]
        
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardWasShown(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillChangeFrame,
                                               object: nil)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false;
        view.addGestureRecognizer(tap)
        
        let tapGenderIsA: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.changeEmojiIsA) )
        
        tapGenderIsA.cancelsTouchesInView = false;
        self.isA.addGestureRecognizer(tapGenderIsA)
        
    }
    
    

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
//        if let mainViewController = segue.destination as? ViewController {
//
//        }
        
    }
    

    var activeTextField = UITextField()
    
    // Assign the newly active text field to your activeTextField variable
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeTextField = textField
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        return updatedText.count <= 10
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        
        let changedText = currentText.replacingCharacters(in: stringRange, with: text)
        
        return changedText.count <= 10
    }

    
    
    
    @objc func keyboardWasShown(notification: NSNotification) {
        
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        
        //        TODO: make sure to scroll if textfield not in view only. Iterate through all textfields to check
        if (self.phoneField.isFirstResponder){
            
            var offset = keyboardFrame.size.height - self.phoneField.layer.frame.origin.y
            
            if (keyboardFrame.size.height <  self.phoneField.layer.frame.origin.y){
                offset = self.phoneField.layer.frame.origin.y - keyboardFrame.size.height ;
            }
            
            self.scrollView.setContentOffset(CGPoint(x: 0, y: offset + 2*self.phoneField.layer.frame.height), animated: true)
            
            hiMyNameIs.fadeOut()
            nameField.fadeOut()
            imaandiwanna.fadeOut()
            isA.fadeOut()
            wantsA.fadeOut()
            viewForName.fadeOut()
            noteOnEmojiChange.fadeOut()
            tapAwayMessage.fadeIn()
            
        }
        
        
    }
    
    
    
    @objc func dismissKeyboard() {
        
        
        let onConfirmation = self.phoneField.placeholder == "enter confirmation code" || self.phoneField.placeholder == "wrong code, try again"
        
        if (self.phoneField.placeholder == "loading..."){
            resetPhoneNumberFieldAndDismiss();
            return;
        }
        
        
        if (self.phoneField.isFirstResponder == false) || (self.phoneField.isFirstResponder && self.phoneField.nationalNumber == self.nationalNumberConfirmed && self.nationalNumberConfirmed != "") {
            
            print ("\n\n dissmiss right away you're confirmed")
            
            view.endEditing(true)
            self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            
            fadeInAll();

            return;
            
        }
        
        if (!onConfirmation) {
            
            print("phone is focused")

            let text = self.phoneField.text ?? ""
            
            if text == "" {
                self.resetPhoneNumberFieldAndDismiss();
                return
            }
            
            do {
                
                let phoneNumber = try PhoneNumberKit().parse(text)
                self.countryCode = String(phoneNumber.countryCode)
                self.nationalNumber = String(phoneNumber.nationalNumber)
                
                self.phoneField.text = ""
                self.phoneField.placeholder = "loading..."

                Verify.sendVerificationCode(self.countryCode, self.nationalNumber)
                
                self.phoneField.text = ""
                self.phoneField.placeholder = "enter confirmation code"
                self.phoneField.isPartialFormatterEnabled = false;
                
                return

            }
                
            catch {
                
                self.phoneField.text = ""
                self.phoneField.placeholder = "incorrect number, try again"

                print("error parsing phonenumber")
                return
                
            }

        }
        
        else if (onConfirmation && (self.phoneField.text?.count)! > 1) {
            
            
            let code = self.phoneField.text!
            self.phoneField.text = ""
            self.phoneField.placeholder = "loading..."

            Verify.validateVerificationCode(self.countryCode, self.nationalNumber, code) { checked in
                
                
                if (checked.success) {

                    self.countryCodeConfirmed = self.countryCode
                    self.nationalNumberConfirmed = self.nationalNumber
                    self.resetPhoneNumberFieldAndDismiss()

                } else {
                    self.phoneField.text = ""
                    self.phoneField.placeholder = "wrong code, try again"

                }

            }

        }
        
        else {
            resetPhoneNumberFieldAndDismiss();
        }
        
    }
    
    func resetPhoneNumberFieldAndDismiss() {
        
        self.phoneField.text = self.countryCodeConfirmed + self.nationalNumberConfirmed
        self.phoneField.placeholder = "123-123-1234"
        self.phoneField.isPartialFormatterEnabled = true;
        
        view.endEditing(true)
        self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        
        fadeInAll();
    }
    
    func fadeInAll(){
        hiMyNameIs.fadeIn()
        nameField.fadeIn()
        imaandiwanna.fadeIn()
        isA.fadeIn()
        wantsA.fadeIn()
        viewForName.fadeIn()
        noteOnEmojiChange.fadeIn()
        tapAwayMessage.fadeOut()
    }
    
    @objc func changeEmojiIsA(gestureRecognizer: UITapGestureRecognizer) {
        
        let mainViewController = presentingViewController as! ViewController

        if gestureRecognizer.state == UIGestureRecognizerState.recognized {
            
            let loc = gestureRecognizer.location(in: self.isA.inputView)
            print(loc)
            print(self.isA.center)

            if loc.x > self.isA.center.x && self.isA.index == 0 {
                try? self.isA.setIndex(1)
                self.isA.titles[0]=mainViewController.emojiCodeMen[0]
                return;
            }
            else if loc.x < self.isA.center.x && self.isA.index == 1 {
                try? self.isA.setIndex(0)
                self.isA.titles[1]=mainViewController.emojiCodeWomen[0]
                return;
            }

        }

        if Int(self.isA.index) == 0 {
            let index = ((mainViewController.emojiCodeMenCounter)+1)%(mainViewController.emojiCodeMen.count)
            self.isA.titles[0]=mainViewController.emojiCodeMen[index]
            self.isA.titles[1]=mainViewController.emojiCodeWomen[0]
            mainViewController.emojiCodeMenCounter+=1;
        }
        
        else if Int(self.isA.index) == 1 {
            let index = ((mainViewController.emojiCodeWomenCounter)+1)%(mainViewController.emojiCodeWomen.count)
            self.isA.titles[1]=mainViewController.emojiCodeWomen[index]
            self.isA.titles[0]=mainViewController.emojiCodeMen[0]
            mainViewController.emojiCodeWomenCounter+=1;
        }
        
    }
    
    var phoneConfirmed = false;

    @IBAction func pressed(_ sender: Any) {
        
        if ((self.nameField.text?.trim().count)! <= 1){
            self.nameField.becomeFirstResponder();
            return;
        }
        
        if (self.nationalNumberConfirmed == "" || self.phoneField.nationalNumber != self.nationalNumberConfirmed) {
            self.phoneField.becomeFirstResponder();
            return;
        }
        
        
        
        let mainViewController = presentingViewController as? ViewController
        
        self.dismiss(animated: true) {
            
            mainViewController?.nameOfPerson = self.nameField.text?.trim()
            mainViewController?.isA = Int(self.isA.index)
            mainViewController?.wantsA = Int(self.wantsA.index)

            mainViewController?.menuImage.alpha = 0;

            UIView.animate(withDuration: 1, delay: 0.0, options: [.curveEaseOut], animations: {

                mainViewController?.menuImage.alpha = 1;
                mainViewController?.menuImage.isHidden = false;

            }, completion: nil)


            mainViewController?.emojiCodeMenCounter = mainViewController?.emojiCodeMen.index(of: self.isA.titles[0]) ?? 0
            
            mainViewController?.emojiCodeWomenCounter = mainViewController?.emojiCodeWomen.index(of: self.isA.titles[1]) ?? 0
            
            
            mainViewController?.updatePhoneNumber(phoneNumber: self.countryCodeConfirmed+self.nationalNumberConfirmed)
            
            mainViewController?.updateUserProfile()
            mainViewController?.startMatching()
        }

        
    }

    
    func tapRecognizing(image:UIImageView, function:Selector) {
        let tap = UITapGestureRecognizer(target: self, action: function )
        image.addGestureRecognizer(tap)
        image.isUserInteractionEnabled = true
        image.layer.borderColor = #colorLiteral(red: 0.5058823529, green: 0.9450980392, blue: 0.6588235294, alpha: 1)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        let mainViewController = presentingViewController as! ViewController

        mainViewController.endMatching()
        mainViewController.hideLoadingAnimation()

        self.ref = Database.database().reference()
    self.ref.child("users").child(mainViewController.uniqueUserID).child("emoji").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
        
            let existence = snapshot.value as? String ?? ""
        print("emoji in db: ", existence)
        
            if (existence == "" || snapshot.value == nil ){

            }
                
            else {
                if UInt(UserDefaults.standard.integer(forKey: "isA") ) == 0 {
                    self.isA.titles[0] = existence
                }
                else {
                    self.isA.titles[1] = existence
                }

            }
        
        });
        
        do {
            try self.isA.setIndex(UInt(UserDefaults.standard.integer(forKey: "isA") ))
            try self.wantsA.setIndex(UInt(UserDefaults.standard.integer(forKey: "wantsA") ))
        }
            
        catch {
            print("")
        }
        
        
        
    self.ref.child("users").child(mainViewController.uniqueUserID).child("phoneNumber").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
            let existence = snapshot.value as? String ?? ""
            print("phoneNumber in db: ", existence)
        
            if (existence=="") {
                return;
            }
        
            do {
                
                let phoneNumber = try PhoneNumberKit().parse(existence)
                self.countryCodeConfirmed = String(phoneNumber.countryCode)
                self.nationalNumberConfirmed = String(phoneNumber.nationalNumber)
                
                self.resetPhoneNumberFieldAndDismiss()
                
            }
                
            catch {
                
                self.resetPhoneNumberFieldAndDismiss()
                
            }

        
        
        });
        
        
    }
    
}





extension String {
    func image() -> UIImage? {
        
        let size = CGSize(width: 60, height: 60)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.white.set()
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(CGRect(origin: .zero, size: size))
        (self as AnyObject).draw(in: rect, withAttributes: [.font: UIFont.systemFont(ofSize: 60)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
        
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
}


extension UIView {
    var textFieldsInView: [UITextField] {
        return subviews
            .filter ({ !($0 is UITextField) })
            .reduce (( subviews.compactMap { $0 as? UITextField }), { summ, current in
                return summ + current.textFieldsInView
            })
    }
    var selectedTextField: UITextField? {
        return textFieldsInView.filter { $0.isFirstResponder }.first
    }
}


public extension UIView {
    
    /**
     Fade in a view with a duration
     
     - parameter duration: custom animation duration
     */
    func fadeIn(withDuration duration: TimeInterval = 0.5) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1.0
        })
    }

    /**
     Fade out a view with a duration
     
     - parameter duration: custom animation duration
     */
    func fadeOut(withDuration duration: TimeInterval = 0.5) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.0
        })
    }

}

