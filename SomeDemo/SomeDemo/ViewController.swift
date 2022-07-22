//
//  ViewController.swift
//  SomeDemo
//
//  Created by 王明友 on 2022/7/21.
//

import UIKit

class ViewController: UIViewController {
    private let animationView = GroupView()
    override func viewDidLoad() {
        super.viewDidLoad()
        animationView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        view.addSubview(animationView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        animationView.set(data: GroupCircle())
        animationView.viewDidAppear()
    }
}

