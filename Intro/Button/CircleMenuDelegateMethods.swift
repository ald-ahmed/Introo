

import UIKit
import CircleMenu

extension ViewController: CircleMenuDelegate {
    
    
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
    func circleMenu(_: CircleMenu, willDisplay button: UIButton, atIndex: Int) {
        
        //    let colors = [UIColor.redColor(), UIColor.grayColor(), UIColor.greenColor(), UIColor.purpleColor()]
        let items: [(icon: String, color: UIColor, title: String)] = [
            ("😍", UIColor(red: 0.22, green: 0.74, blue: 0, alpha: 1), "Heart Eyes"),
            ("🎉", UIColor(red: 0.96, green: 0.23, blue: 0.21, alpha: 1),  "Confetti"),
            ("🤙", UIColor(red: 1, green: 0.39, blue: 0, alpha: 1),  "Share Number"),
            ]
        
        let index = atIndex%3
        button.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        button.setImage(resizeImage(image: items[index].icon.image()!, targetSize: CGSize(width:10, height:10)) , for: .normal)
        
        button.setTitle(items[index].title, for: .normal)
        button.setTitleColor(#colorLiteral(red: 0.08235294118, green: 0.0862745098, blue: 0.08235294118, alpha: 1), for: .normal)
        button.titleLabel?.font = UIFont(name: "Helvetica Neue", size: 12)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .center
        
        button.titleEdgeInsets = UIEdgeInsets(top: 80.0, left: 0.0, bottom: 5.0, right: 0.0)

        
        // set highlited image
        let highlightedImage = UIImage(named: items[index].icon)?.withRenderingMode(.alwaysTemplate)
        button.setImage(highlightedImage, for: .highlighted)
        button.tintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        
    }
    
    func circleMenu(_: CircleMenu, buttonWillSelected _: UIButton, atIndex: Int) {
        print("button will selected: \(atIndex)")
    }
    
    func circleMenu(_: CircleMenu, buttonDidSelected _: UIButton, atIndex: Int) {
        print("button did selected: \(atIndex)")
    }

    
}

