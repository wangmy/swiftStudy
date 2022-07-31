//
//  ViewController.swift
//  SomeDemo
//
//  Created by 王明友 on 2022/7/21.
//

import UIKit

extension ViewController: VirtualAvatarsViewDelegate {
    func userViewDidAppear(view: VirtualAvatarsViewable, userView: VirtualAvatarViewable, index: Int) {
        
    }
    
    func viewDidAppear(view: VirtualAvatarsViewable) {
        
    }
    
    func userViewDidClicked(view: VirtualAvatarsViewable, userView: VirtualAvatarViewable, index: Int) {
        if let guideAvatarsView = view as? VirtualGuideAvatarsView {
            guideAvatarsView.appearToCenter(selected: index)
            
        } else if let bottomAvatarsView = view as? VirtualGuideBottomAvatarsView {
            if index == bottomAvatarsView.selectedIndex { return }
            bottomAvatarsView.selectedAppear(selectedIndex: index)
            animationView.strengthenAnimation(selected: index, unSelected: bottomAvatarsView.disSelectedIndex)
        }
    }
    
    func userViewDidDisAppear(view: VirtualAvatarsViewable, userView: VirtualAvatarViewable, index: Int) {
        
    }
    
    func viewDidDisAppear(view: VirtualAvatarsViewable) {
        
    }
    
}

class ViewController: UIViewController {
    private let animationView = VirtualGuideAvatarsView()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        animationView.frame = CGRect(origin: CGPoint(x: 0, y: 220), size: VirtualGuideAvatarsView.viewSize(viewWidth: ScreenWidth))
        animationView.set(viewDelegate: self)
        view.addSubview(animationView)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animationView.appear()
    }
}
