//
//  ViewController.swift
//  SwiftyCubeSample
//
//  Created by Zamber on 2016/11/10.
//
//

import UIKit

class ViewController: UIViewController {

    @IBAction func goForward() {
        cubeController()?.scrollForwardAnimated(animated: true)
    }
    
    @IBAction func goBack() {
        cubeController()?.scrollBackAnimated(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}

