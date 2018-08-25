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

class InformationOneController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var isA: BetterSegmentedControl!
    
    @IBOutlet weak var wantsA: BetterSegmentedControl!
    
    @IBOutlet weak var nameField: UITextField!
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    
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

    
    @objc func dismissKeyboard() {

        view.endEditing(true)
        
        self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)

//        self.phoneNumberConstraint.constant = 100;
        
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
        
        print("change!")
    }
    
    
    
    
    @IBAction func pressed(_ sender: Any) {
        
        if ((self.nameField.text?.trim().count)! <= 1){
            self.nameField.becomeFirstResponder();
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
            print("existence", existence)
            
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
            
        catch{
            print("")
        }
        
    }
    
    
    
    
    
    
    @objc func keyboardWasShown(notification: NSNotification) {
        
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        self.scrollView.setContentOffset(CGPoint(x: 0, y: keyboardFrame.size.height+30), animated: true)
        
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
    
            func trim() -> String
        {
            return self.trimmingCharacters(in: CharacterSet.whitespaces)
        }
}
