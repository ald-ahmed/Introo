//
//  InformationOneController.swift
//  Intro
//
//  Created by Ahmed Al Dulaimy on 6/11/18.
//  Copyright © 2018 Intro. All rights reserved.
//

import UIKit
import Hero
import BetterSegmentedControl

class InformationOneController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var isA: BetterSegmentedControl!
    
    @IBOutlet weak var wantsA: BetterSegmentedControl!
    
    @IBOutlet weak var nameField: UITextField!
    
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

        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        
        
        view.addGestureRecognizer(tap)
        
        
        do {
            try self.isA.setIndex(UInt(UserDefaults.standard.integer(forKey: "isA") ))
            try self.wantsA.setIndex(UInt(UserDefaults.standard.integer(forKey: "wantsA") ))
        }
        catch{
            print("")
        }
        
//        self.wantsA.setIndex(UserDefaults.standard.string(forKey: "wantsA") ?? 0)

        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let mainViewController = segue.destination as? ViewController {
            mainViewController.nameOfPerson = nameField.text?.trim()
            mainViewController.updateUserProfile();
        }
    }
    
    @IBAction func textChanged(_ sender: Any) {
        
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

    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
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
