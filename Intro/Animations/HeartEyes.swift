//
//  SAConfettiView.swift
//  Pods
//
//  Created by Sudeep Agarwal on 12/14/15.
//
//

import UIKit
import QuartzCore

public class HeartEyes: UIView {
    
    public enum ConfettiType {
        case Confetti
        case Triangle
        case Star
        case Diamond
        case Image(UIImage)
    }
    
    var emitter: CAEmitterLayer!
    public var colors: [UIColor]!
    public var intensity: Float!
    public var type: ConfettiType!
    private var active :Bool!
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func setup() {
        colors = [UIColor(red:0.95, green:0.40, blue:0.27, alpha:1.0),
                  UIColor(red:1.00, green:0.78, blue:0.36, alpha:1.0),
                  UIColor(red:0.48, green:0.78, blue:0.64, alpha:1.0),
                  UIColor(red:0.30, green:0.76, blue:0.85, alpha:1.0),
                  UIColor(red:0.58, green:0.39, blue:0.55, alpha:1.0)]
        intensity = 0.5
        type = .Confetti
        active = false
    }
    
    public func startConfetti() {
        emitter = CAEmitterLayer()
        
        emitter.emitterPosition = CGPoint(x: frame.size.width / 2.0, y: frame.size.height)
        emitter.emitterShape = kCAEmitterLayerLine
        emitter.emitterSize = CGSize(width: frame.size.width/2.0, height: 1)
        
        var cells = [CAEmitterCell]()
        cells.append(confettiWithColor())
        
        
        emitter.emitterCells = cells
        layer.addSublayer(emitter)
        active = true
    }
    
    public func stopConfetti() {
        emitter?.birthRate = 0
        active = false
    }
    
    
    public func playFor(seconds: Double!){
    
        self.startConfetti()
        DispatchQueue.main.asyncAfter(deadline: .now()+seconds/1.0) {
            self.stopConfetti()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.layer.removeFromSuperlayer()
            }

        }
        
    }
    
    func imageForType(type: ConfettiType) -> UIImage? {
        
        var fileName: String!
        
        switch type {
        case .Confetti:
            fileName = "confetti"
        case .Triangle:
            fileName = "triangle"
        case .Star:
            fileName = "star"
        case .Diamond:
            fileName = "diamond"
        case let .Image(customImage):
            return customImage
        }
        
        let path = Bundle(for: HeartEyes.self).path(forResource: "HeartEyes", ofType: "bundle")
        let bundle = Bundle(path: path!)
        let imagePath = bundle?.path(forResource: fileName, ofType: "png")
        let url = NSURL(fileURLWithPath: imagePath!)
        let data = NSData(contentsOf: url as URL)
        if let data = data {
            return UIImage(data: data as Data)!
        }
        return nil
    }
    
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

    func confettiWithColor() -> CAEmitterCell {
        let confetti = CAEmitterCell()
        confetti.birthRate = 1.0 * intensity
        confetti.lifetime = 8.0 * intensity
        confetti.lifetimeRange = 0
        confetti.color = UIColor.white.cgColor
        confetti.velocity = CGFloat(80.0 * intensity)
        confetti.contents = self.resizeImage(image: UIImage(named: "hearteyes.png")!, targetSize: CGSize(width:30.0, height:30.0)).cgImage
        
        return confetti
    }
    
    public func isActive() -> Bool {
        return self.active
    }
}
