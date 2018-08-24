//
//  ActiveCollectionView.swift
//  Intro
//
//  Created by Ahmed Al Dulaimy on 8/22/18.
//  Copyright © 2018 Intro. All rights reserved.
//

import Foundation
import AnimatedCollectionViewLayout

class LabeledCell: UICollectionViewCell {
    
    @IBOutlet weak var text: UILabel!
    
    
}



class ActiveCollectionView:UICollectionView {
    
    // This is in the UICollectionView subclass
    private func addGradientMask() {
        let coverView = GradientView(frame: self.bounds)
        let coverLayer = coverView.layer as! CAGradientLayer
        coverLayer.colors = [UIColor.white.withAlphaComponent(0).cgColor, UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor]
        coverLayer.locations = [0.0, 0.5, 1.0]
        coverLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        coverLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        self.mask = coverView
    }

}


extension ViewController {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count;
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as! LabeledCell
        
        cell.text.text = users[indexPath.row]
        
        for layer in cell.layer.sublayers! {
            if layer.value(forKey: "border") as? String ?? "" == "1" {
                layer.removeFromSuperlayer()
            }
        }
        
        
        if indexPath.row == 0  &&  users[indexPath.row] != "" {

            let border = CALayer()
            let width = CGFloat(2.0)
            border.setValue("1", forKey: "border")
            border.borderColor = UIColor.white.cgColor
            
            border.frame = CGRect(x: cell.frame.size.width-1, y: 0, width: cell.frame.size.width, height: cell.frame.size.height)
            
            border.borderWidth = width
            cell.layer.addSublayer(border)
            cell.layer.masksToBounds = true

        }

        return cell
    }
    
    

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }

    
}

// Declare this anywhere outside the sublcass
class GradientView: UIView {
    class func layerClass() -> AnyClass {
        return CAGradientLayer.self
    }
}
