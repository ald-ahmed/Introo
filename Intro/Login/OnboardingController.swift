//
//  OnboardingController.swift
//  Intro
//
//  Created by Ahmed Al Dulaimy on 8/17/18.
//  Copyright © 2018 Intro. All rights reserved.
//



import UIKit
import paper_onboarding

class OnboardingController: UIViewController {
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let onboarding = PaperOnboarding()
        onboarding.delegate = self
        onboarding.dataSource = self
        onboarding.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(onboarding)
        
        // add constraints
        for attribute: NSLayoutAttribute in [.left, .right, .top, .bottom] {
            let constraint = NSLayoutConstraint(item: onboarding,
                                                attribute: attribute,
                                                relatedBy: .equal,
                                                toItem: view,
                                                attribute: attribute,
                                                multiplier: 1,
                                                constant: 0)
            view.addConstraint(constraint)
        }
    }

    
    


}



extension OnboardingController: PaperOnboardingDelegate {
    
    func onboardingWillTransitonToIndex(_ index: Int) {
        print(index)
        if index == 2 {
            performSegue(withIdentifier: "showMain", sender: self)
        }
    }
    
    func onboardingDidTransitonToIndex(_: Int) {
    }
    
    func onboardingConfigurationItem(_ item: OnboardingContentViewItem, index: Int) {
        //item.titleLabel?.backgroundColor = .redColor()
        //item.descriptionLabel?.backgroundColor = .redColor()
        //item.imageView = ...
    }
}

// MARK: PaperOnboardingDataSource
extension OnboardingController: PaperOnboardingDataSource {
    
    
    private static let titleFont = UIFont(name: "Nunito-Bold", size: 36.0) ?? UIFont.boldSystemFont(ofSize: 36.0)
    private static let descriptionFont = UIFont(name: "OpenSans-Regular", size: 14.0) ?? UIFont.systemFont(ofSize: 14.0)
    
    func onboardingItem(at index: Int) -> OnboardingItemInfo {
        let IMAGE = #imageLiteral(resourceName: "icon-messages-app-store-1024x768")

        
        return [
            OnboardingItemInfo(informationImage: IMAGE,
                               title: "Video Check",
                               description: "Today's your day. Enable the video real quick.", pageIcon: IMAGE,
                               
                               color: UIColor(red: 0.40, green: 0.56, blue: 0.71, alpha: 1.00),
                               titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: OnboardingController.titleFont, descriptionFont: OnboardingController.descriptionFont),
            
            OnboardingItemInfo(informationImage: IMAGE,
                               title: "Mic Check",
                               description: "Ahem ahem.. let's make sure the audio is enabled...",
                               
                               pageIcon: IMAGE,
                               color: UIColor(red: 0.40, green: 0.69, blue: 0.71, alpha: 1.00),
                               titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: OnboardingController.titleFont, descriptionFont: OnboardingController.descriptionFont),
            
            OnboardingItemInfo(informationImage: IMAGE,
                               title: "No Bots Past This Point",
                               description: "We need to verify you're a real one.",
                               pageIcon: IMAGE,
                               color: UIColor(red: 0.61, green: 0.56, blue: 0.74, alpha: 1.00),
                               titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: OnboardingController.titleFont, descriptionFont: OnboardingController.descriptionFont),
            
            
            ][index]
    }
    
    
    
    func onboardingItemsCount() -> Int {
        return 3
    }
    
    func onboardinPageItemRadius() -> CGFloat {
        return 2
    }

    func onboardingPageItemSelectedRadius() -> CGFloat {
        return 10
    }
    func onboardingPageItemColor(at index: Int) -> UIColor {
        return [UIColor.white, UIColor.red, UIColor.green][index]
    }
}

