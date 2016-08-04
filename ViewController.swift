//
//  ViewController3.swift
//  imageToVideo
//
//  Created by Stanley Chiang on 8/4/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//
//http://stackoverflow.com/a/36290742/1079379

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settings = RenderSettings()
        let imageAnimator = ImageAnimator(renderSettings: settings)
        imageAnimator.render() {
            print("yes")
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
