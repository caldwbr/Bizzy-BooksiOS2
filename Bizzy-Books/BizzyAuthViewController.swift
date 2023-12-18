//
//  BizzyAuthViewController.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 11/22/23.
//

import UIKit
import FirebaseDatabase
import FirebaseDatabaseUI
import FirebaseAuthUI

class BizzyAuthViewController: FUIAuthPickerViewController {
    
    
    override init(nibName: String?, bundle: Bundle?, authUI: FUIAuth) {
        super.init(nibName: "FUIAuthPickerViewController", bundle: bundle, authUI: authUI)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        
        let imageViewBackground = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        imageViewBackground.image = UIImage(named: "beesBackground")
        
        // you can change the content mode:
        imageViewBackground.contentMode = UIView.ContentMode.scaleAspectFill
        
        view.insertSubview(imageViewBackground, at: 0)
 
    }

}
