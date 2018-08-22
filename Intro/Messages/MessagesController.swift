//
//  MessagesController.swift
//  Intro
//
//  Created by Ahmed Al Dulaimy on 7/5/18.
//  Copyright © 2018 Intro. All rights reserved.
//

import UIKit


class MessagesController: UIViewController{


    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        
    }
    
    
    
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        
        if gesture.direction == UISwipeGestureRecognizerDirection.right {
            
            print("Swipe Right")
            
        }
            
        else if gesture.direction == UISwipeGestureRecognizerDirection.left {
            print("Swipe Left")

        }
            
        else if gesture.direction == UISwipeGestureRecognizerDirection.up {
            print("Swipe Up")
            
            
        }
            
        else if gesture.direction == UISwipeGestureRecognizerDirection.down {
            print("Swipe Down")
            
            self.dismiss(animated: true, completion: nil)
        }
        
    }


}
