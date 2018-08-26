//
//  PillButtonsView.swift
//  Intro
//
//  Created by Ahmed Al Dulaimy on 8/25/18.
//  Copyright © 2018 Intro. All rights reserved.
//

import Foundation
import AnimatedCollectionViewLayout

class PillCell: UICollectionViewCell {
    
    @IBOutlet weak var text: UILabel!
    
    
}

class PillButtonController: UICollectionView {
  
   
    
}



class PillButtonDelegate: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var mainController: ViewController?
    
    var buttons = [ (emoji: "🎉", name: "Confetti"),
                    (emoji: "😍", name: "HeartEyes")
    ]
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return buttons.count;
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PillCell", for: indexPath) as! PillCell
        
        cell.text.text = buttons[indexPath.row].emoji
        
        cell.layer.cornerRadius = 10.0
        cell.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0.168627451, blue: 0.1607843137, alpha: 1)
        cell.layer.shadowOpacity = 1;
        cell.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        print(indexPath.row)
        
        mainController?.addAnimationToCollection(name: buttons[indexPath.row].name)
        
        self.fadeOutCell(cell: collectionView.cellForItem(at: indexPath) as! PillCell)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        let CellCount = buttons.count;
        let CellWidth = 100;
        let collectionViewWidth = CGFloat(300.0);
        let CellSpacing = 15;
        
        let totalCellWidth = CellWidth * CellCount
        let totalSpacingWidth = CellSpacing * (CellCount - 1)
        
        let leftInset = (collectionViewWidth - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
        let rightInset = leftInset
        
        return UIEdgeInsetsMake(0, leftInset, 0, rightInset)
    }
    
    
    func fadeOutCell(cell: PillCell){

        cell.alpha = 1;
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseOut], animations: {
            
            cell.alpha = 0;
            
        }, completion: { _ in
//            cell.isHidden = true
    
        })
        
    }
    
}





