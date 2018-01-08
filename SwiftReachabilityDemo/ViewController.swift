//
//  ViewController.swift
//  SwiftReachabilityDemo
//
//  Created by EastElsoft on 2018/1/8.
//  Copyright © 2018年 AnatoleZho. All rights reserved.
//

import UIKit
import SwiftReachability

class ViewController: UIViewController {
    
    @IBOutlet weak var infoLabel: UILabel!
    
    private lazy var reachability: SwiftReachability = SwiftReachability(hostname: "www.apple.com")
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(FFReachabilityChangedNotification), object: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(self, selector: #selector(networkReachabilityChanged), name: NSNotification.Name.init(FFReachabilityChangedNotification), object: nil)
        reachability.startNotifier()
    }
    
    @IBAction func checkInternetAction(_ sender: Any) {
        updateUI()
    }
    
    @objc func networkReachabilityChanged() {
        updateUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateUI() {
        infoLabel.text = reachability.currentReachabilityStatus.description
    }
    
}


