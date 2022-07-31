//
//  GroupCircleView.swift
//  SomeDemo
//
//  Created by 王明友 on 2022/7/21.
//

import Foundation
import UIKit

// 参数配置
//设计稿： https://app.zeplin.io/project/62d7a8b722735313726d310a/screen/62da45246ca42c4edd6fe99f
private let usersViewCount: Int = 12
private let usersViewRowCount: Int = 3
private let contentInnerEdgeInset = UIEdgeInsets(top: 0, left: 26, bottom: 0, right: 26)
private let avartarViewSize: CGSize = CGSize(width: 100, height: 100)
private let centerUsersViewOffset: CGFloat = 55
private let userViewYPadding: CGFloat = 12

// 动画相关
private let userAppearAnimationDuration: CFTimeInterval = 0.3
private let userAnimationIndexGroup = [[0], [1,2,3], [4,5,6], [7,8,9], [10,11]]
private let userAnimationDelayGroup = [0, 0.067, 0.067, 0.067, 0.067]

// unselecteds's duration
private let userDisAppearAnimationDuration: CFTimeInterval = 0.133

// selected's move to center's duration
private let userAppearToCenterAnimationDuration: CFTimeInterval = 0.6
let avatarViewCenterSize: CGSize = CGSize(width: avartarViewSize.width*2.2, height: avartarViewSize.height*2.2)

private let testView = UIView()

// MARK: VirtualGuideAvatarsView
final class VirtualGuideAvatarsView: UIView {
    
    static func viewSize(viewWidth: CGFloat) -> CGSize {
        let cloumn: CGFloat = CGFloat(usersViewCount / 3)
        let h: CGFloat = contentInnerEdgeInset.top + cloumn * avartarViewSize.height + max(0, (cloumn-1))*userViewYPadding + (((usersViewCount-2) % 3) == 1 ? centerUsersViewOffset : 0) + contentInnerEdgeInset.bottom
        return CGSize(width: viewWidth, height: h)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        testView.backgroundColor = UIColor.yellow
        testView.alpha = 0.1
//        addSubview(testView)
        initSubViews()
        testView.frame = bottomAvartarsView!.frame
    }
    
    func appear() {
        if isAnimating {
            return
        }
        startAppearAnimation()
    }
    
    func disAppear() {
        if isAnimating {
            return
        }
        startDisAppearAnimation()
    }
    
    
    func appearToCenter(selected: Int) {
        if isAnimating {
            return
        }
        startAppearToCenterAnimation(selectedIndex: selected)
    }
    
    func strengthenAnimation(selected: Int, unSelected: Int ) {
        if isAnimating {
            return
        }
        strengthenAvatarAnimation(selectedIndex: selected, unSelectedIndex: unSelected)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        assert(isInit, "⚠️⚠️⚠️⚠️必须保证bounds不为空⚠️⚠️⚠️⚠️")
        layoutViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private let contentView = UIView()
    private var userViews = [VirtualGuideAvatarView]()
    private var bottomAvartarsView: VirtualGuideBottomAvatarsView?
    private weak var viewDelegate: VirtualAvatarsViewDelegate? = nil
    
    private var animationIsAdding = false
    private var isAnimating = false
    private var isInit = false
    var appearAnimationOperationFinishBlk: (() -> Void)?
    var disAppearAnimationOperationFinishBlk: (() -> Void)?
}

extension VirtualGuideAvatarsView: VirtualAvatarsViewable {
    func set(data: [VirtualAvataring]) {
        for (i, item) in data.enumerated() {
            if  i < userViews.count {
                userViews[i].set(data: item)
            }
        }
        bottomAvartarsView?.set(data: data)
    }
    
    func set(viewDelegate: VirtualAvatarsViewDelegate) {
        self.viewDelegate = viewDelegate
        bottomAvartarsView?.set(viewDelegate: viewDelegate)
    }
}

// 布局相关
extension VirtualGuideAvatarsView {
    private func layoutViews() {
        guard !bounds.size.equalTo(.zero) else { return }
        
        contentView.backgroundColor = .clear
        contentView.frame = bounds
        
        // 从左到右，从上到下
        for (index, userView) in userViews.enumerated() {
            userView.frame = CGRect(origin: userOrigin(index: index), size: avartarViewSize)
        }
    }
    
    private func initSubViews() {
        if isInit {
            return
        }
        addSubview(contentView)
        
        for i in 0 ..< usersViewCount {
            let uview = VirtualGuideAvatarView()
            uview.didClickBlk = { [weak self] circleView in
                guard let self = self else { return }
                if self.isAnimating {
                    print("🐯🐯🐯 正在做动画 🐯🐯🐯")
                    return
                }
                print("[VirtualGuideAvatarsView] click \(i)")
                if let viewDelegate = self.viewDelegate, self.userViews.count > i {
                    viewDelegate.userViewDidClicked(view: self, userView: self.userViews[i], index: i)
                }
            }
            
            uview.appearAnimationDidStartBlk = { [weak self] circleView in
                guard let self = self else { return }
                self.isAnimating = true
            }
            
            uview.appearAnimationDidStopBlk = { [weak self] circleView in
                guard let self = self else { return }
                print("[VirtualGuideAvatarView] animationDidStop \(i)")
                
                if let viewDelegate = self.viewDelegate, self.userViews.count > i {
                    viewDelegate.userViewDidAppear(view: self, userView: self.userViews[i], index: i)
                }
                
                if let lastIndexes = userAnimationIndexGroup.last, lastIndexes.contains(i) {
                    print("[VirtualGuideAvatarsView] animationDidStop \(i)")
                    self.isAnimating = false
                    if let viewDelegate = self.viewDelegate{
                        viewDelegate.viewDidAppear(view: self)
                    }
                }
            }
            
            uview.disAppearAnimationDidStartBlk = { [weak self] circleView in
                guard let self = self else { return }
                self.isAnimating = true
            }
            
            uview.disAppearAnimationDidStopBlk = { [weak self] circleView in
                guard let self = self else { return }
                
                if let viewDelegate = self.viewDelegate, self.userViews.count > i {
                    viewDelegate.userViewDidDisAppear(view: self, userView: self.userViews[i], index: i)
                }
                
                if circleView == self.userViews.last {
                    self.isAnimating = false
                    if let viewDelegate = self.viewDelegate{
                        viewDelegate.viewDidDisAppear(view: self)
                    }
                }
            }
            
            contentView.addSubview(uview)
            userViews.append(uview)
        }
        
        // TODO: wmy subViewsCount ?= userViews.count
        bottomAvartarsView = VirtualGuideBottomAvatarsView(frame: CGRect(origin: CGPoint(x: 0, y: avatarViewCenterSize.height + 59), size: VirtualGuideBottomAvatarsView.viewSize(viewWidth: ScreenWidth)), subViewsCount: userViews.count)
        contentView.addSubview(bottomAvartarsView!)
        bottomAvartarsView?.isHidden = true
        
        isInit = true
    }
    
    private func userOrigin(index: Int) -> CGPoint {
        guard usersViewRowCount != 0 else { return .zero }
        var userViewXPadding: CGFloat = 0
        if usersViewRowCount > 1 {
            userViewXPadding = (bounds.width - (contentInnerEdgeInset.left + contentInnerEdgeInset.right) - (avartarViewSize.width * CGFloat(usersViewRowCount))) / CGFloat((usersViewRowCount - 1))
        }
        let x: CGFloat = contentInnerEdgeInset.left + CGFloat((index % 3)) * (avartarViewSize.width + userViewXPadding)
        let y: CGFloat = contentInnerEdgeInset.top + (CGFloat(index / 3)) * (avartarViewSize.height + userViewYPadding) + ((index % 3) == 1 ? centerUsersViewOffset : 0)
        return CGPoint(x: x, y: y)
    }
}

// 动画相关
extension VirtualGuideAvatarsView {
    private func startDisAppearAnimation(_ delay: CFTimeInterval = 0) {
        print("🌞 startDisAppearAnimation")
        if animationIsAdding { return }
        animationIsAdding = true
        
        for (_, userView) in userViews.enumerated() {
            userView.disAppearAnimation(delay: delay)
        }
        
        
        animationIsAdding = false
        // 动画操作结束
        disAppearAnimationOperationFinishBlk?()
    }
    
    private func startAppearAnimation(_ delay: CFTimeInterval = 0) {
        print("🌞 startAppearAnimation")
        
        if animationIsAdding { return }
        animationIsAdding = true
        
        var userAnimationDelay: CFTimeInterval = delay
        if userViews.count < usersViewCount || userAnimationDelayGroup.count != userAnimationIndexGroup.count {
            assert(false, "⚠️⚠️⚠️⚠️检查数据，还没有initSubViews⚠️⚠️⚠️⚠️")
            // 异常情况，就简单出现
            for (_, userView) in userViews.enumerated() {
                userView.appearAnimation(delay: userAnimationDelay)
            }
        } else {
            for (index, animationIndexs) in userAnimationIndexGroup.enumerated() {
                userAnimationDelay += userAnimationDelayGroup[index]
                for userViewIndex in animationIndexs {
                    if userViews.count > userViewIndex {
                        let userView = userViews[userViewIndex]
                        print("🌞 startUserAnimation \(index)")
                        userView.appearAnimation(delay: userAnimationDelay)
                    }
                }
            }
        }
        
        animationIsAdding = false
        // 动画操作结束
        appearAnimationOperationFinishBlk?()
    }
    
    private func startAppearToCenterAnimation(_ delay: CFTimeInterval = 0, selectedIndex: Int) {
        print("🌞 startAppearToCenterAnimation")
        if animationIsAdding { return }
        animationIsAdding = true
        
        // 1. 选中的view做中心放大动画
        // 2. 未选中的做消失动画
        for (index, userView) in userViews.enumerated() {
            userView.isUserInteractionEnabled = false
            if index == selectedIndex {
                let from = userView.frame.origin
                let to = CGPoint(x: ScreenWidth/2 - avartarViewSize.width/2, y: avatarViewCenterSize.width/2 - avartarViewSize.width/2)
                userView.appearToCenterAnimation(delay: delay, positions: (from, to))
            } else {
                userView.disAppearAnimation(delay: delay)
            }
        }
        
        // 开始做bottomView动画
        bottomAvartarsView?.isHidden = false
        bottomAvartarsView?.appear(selectedIndex: selectedIndex)
        
        animationIsAdding = false
        
        // 动画操作结束
        appearAnimationOperationFinishBlk?()
    }
    
    private func strengthenAvatarAnimation(_ delay: CFTimeInterval = 0.2, selectedIndex: Int, unSelectedIndex: Int) {
        print("🌞 strengthenAnimation")
        if animationIsAdding { return }
        animationIsAdding = true
        assert(userViews.count > selectedIndex, "userViews.count > selectedIndex error ")
        assert(userViews.count > unSelectedIndex, "userViews.count > selectedIndex error ")

        for (index, avatarView) in userViews.enumerated() {
            if index == selectedIndex {
                avatarView.backgroundColor = UIColor.clear
                avatarView.removeAllAnimation()
                avatarView.frame = CGRect(x: (bounds.width - avatarViewCenterSize.width)/2, y: 0, width: avatarViewCenterSize.width, height: avatarViewCenterSize.height)
                avatarView.strengthenAppearAvatarAnimation(delay: delay)
                
            } else if index == unSelectedIndex {
                avatarView.backgroundColor = UIColor.clear
                avatarView.removeAllAnimation()
                avatarView.frame = CGRect(x: (bounds.width - avatarViewCenterSize.width)/2, y: 0, width: avatarViewCenterSize.width, height: avatarViewCenterSize.height)
                avatarView.strengthenDisAppearAvatarAnimation(delay: delay)
                
            } else {
                avatarView.backgroundColor = UIColor.clear
                avatarView.removeAllAnimation()
                avatarView.frame = CGRect(x: (bounds.width - avatarViewCenterSize.width)/2, y: 0, width: avatarViewCenterSize.width, height: avatarViewCenterSize.height)
            }
        }
        if selectedIndex >= 0 {
            
        }
        animationIsAdding = false
    }
}

// MARK: VirtualGuideAvatarView
private let animationType: String = "VirtualGuideAvatarViewAnimationType"
private let animationTypeAppear: String = "VirtualGuideAvatarViewAnimationType_Appear"
private let animationTypeAppearToCenter: String = "VirtualGuideAvatarViewAnimationType_AppearToCenter"
private let animationTypeDisAppear: String = "VirtualGuideAvatarViewAnimationType_DisAppear"

final class VirtualGuideAvatarView: UIView {
    var didClickBlk: ((_ view: VirtualGuideAvatarView) -> Void)?
    
    var appearAnimationDidStartBlk: ((_ view: VirtualGuideAvatarView) -> Void)?
    var appearAnimationDidStopBlk: ((_ view: VirtualGuideAvatarView) -> Void)?
    var disAppearAnimationDidStartBlk: ((_ view: VirtualGuideAvatarView) -> Void)?
    var disAppearAnimationDidStopBlk: ((_ view: VirtualGuideAvatarView) -> Void)?
    
    private let imgContentView = UIView()
    private let imgView = UIImageView()
    private var animationIsAdding = false
    private var isAppearing = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imgContentView.layer.opacity = 0
        imgContentView.backgroundColor = .clear
        addSubview(imgContentView)
        
        imgView.backgroundColor = .gray
        imgView.contentMode = .scaleAspectFill
        imgContentView.addSubview(imgView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        addGestureRecognizer(tapGesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imgContentView.frame = bounds
        imgView.frame = imgContentView.bounds
        imgContentView.layer.cornerRadius = imgContentView.bounds.width/2
        imgContentView.layer.masksToBounds = true
    }
    
    @objc private func tapAction() {
        didClickBlk?(self)
    }
    
    func appearAnimation(duration: CFTimeInterval = userAppearAnimationDuration, delay: CFTimeInterval = 0) {
        if animationIsAdding {
            return
        }
        animationIsAdding = true
        appearUserAnimation(duration: duration, delay: delay)
        animationIsAdding = false
    }
    
    func disAppearAnimation(duration: CFTimeInterval = userDisAppearAnimationDuration, delay: CFTimeInterval = 0) {
        if animationIsAdding {
            return
        }
        animationIsAdding = true
        disAppearUserAnimation(duration: duration, delay: delay)
        animationIsAdding = false
    }
    
    func appearToCenterAnimation(duration: CFTimeInterval = userAppearToCenterAnimationDuration, delay: CFTimeInterval = 0, positions: (from: CGPoint, to: CGPoint) = (from: CGPoint.zero, to: CGPoint.zero)) {
        if animationIsAdding {
            return
        }
        animationIsAdding = true
        appearCenterAnimation(duration: duration, delay: delay, positions: positions)
        animationIsAdding = false
    }
    
    
    
    private func appearCenterAnimation(duration: CFTimeInterval = userAppearToCenterAnimationDuration, delay: CFTimeInterval = 0, positions: (from: CGPoint, to: CGPoint) = (from: CGPoint.zero, to: CGPoint.zero)) {
        layer.removeAllAnimations()
        
//        let bezierPath = UIBezierPath()
//        bezierPath.move(to: positions.from)
//        bezierPath.addLine(to: positions.to)
//        let positionAnimation = CAKeyframeAnimation(keyPath: "position")
//        positionAnimation.path = bezierPath.cgPath
//        positionAnimation.fillMode = .forwards
        
        let positionY =  (positions.to.y - positions.from.y)
        let positionX =  (positions.to.x - positions.from.x)
        
        let positionAnimationY = CAKeyframeAnimation(keyPath: "transform.translation.y")
        positionAnimationY.values = [0, (positionY * 0.667), positionY]
        positionAnimationY.keyTimes = [0, 0.667, 1]
        
        let positionAnimationX = CAKeyframeAnimation(keyPath: "transform.translation.x")
        positionAnimationX.values = [0, (positionX * 0.667), positionX]
        positionAnimationX.keyTimes = [0, 0.667, 1]
        
        
        let radio = CGFloat(avatarViewCenterSize.width / avartarViewSize.width)
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [1, radio, radio]
        scaleAnimation.keyTimes = [0, 0.667, 1]
        
        let group = CAAnimationGroup()
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.duration =  duration
        group.beginTime = CACurrentMediaTime() + delay
        group.animations = [positionAnimationX, positionAnimationY, scaleAnimation]
        group.delegate = self
        group.setValue(animationTypeAppearToCenter, forKey: animationType)
        
        layer.add(group, forKey: "UserViewAvatarAppearToCenterAnimation")
    }
    
    private func appearUserAnimation(duration: CFTimeInterval = userAppearAnimationDuration, delay: CFTimeInterval = 0) {
        
        imgContentView.layer.removeAllAnimations()
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [0.75, 1.2, 1]
        scaleAnimation.keyTimes = [0, 0.5567, 1]
        
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [0, 0.5, 1]
        opacityAnimation.keyTimes = [0, 0.5, 1]
        
        let group = CAAnimationGroup()
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.duration =  duration
        group.beginTime = CACurrentMediaTime() + delay
        group.animations = [scaleAnimation, opacityAnimation]
        group.delegate = self
        group.setValue(animationTypeAppear, forKey: animationType)
        imgContentView.layer.add(group, forKey: "UserViewAvatarAppearAnimation")
    }
    
    private func disAppearUserAnimation(duration: CFTimeInterval = userDisAppearAnimationDuration, delay: CFTimeInterval = 0) {
        imgContentView.layer.removeAllAnimations()
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [1, 0.5]
        scaleAnimation.keyTimes = [0, 1]

        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [1, 0]
        opacityAnimation.keyTimes = [0, 1]

        let group = CAAnimationGroup()
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.duration =  duration
        group.beginTime = CACurrentMediaTime() + delay
        group.delegate = self
        group.setValue(animationTypeDisAppear, forKey: animationType)
        group.animations = [scaleAnimation, opacityAnimation]
        imgContentView.layer.add(group, forKey: "UserViewAvatarDisAnimation")
    }
    func removeAllAnimation() {
        imgContentView.layer.removeAllAnimations()
        layer.removeAllAnimations()
    }
    
    func strengthenAppearAvatarAnimation(duration: CFTimeInterval = 1, delay: CFTimeInterval = 0) {
        imgView.backgroundColor = .red
        
        if animationIsAdding {
            return
        }
        animationIsAdding = true
        
        removeAllAnimation()
        
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [0.9, 1]
        scaleAnimation.keyTimes = [0, 1]
        
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [0, 1]
        opacityAnimation.keyTimes = [0, 1]
        
        let group = CAAnimationGroup()
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.duration =  duration
        group.beginTime = CACurrentMediaTime() + delay
        group.animations = [scaleAnimation, opacityAnimation]
        
        imgContentView.layer.add(group, forKey: "UserViewAvatarStrengthAnimation")
        
        animationIsAdding = false
    }
    
    func strengthenDisAppearAvatarAnimation(duration: CFTimeInterval = 1, delay: CFTimeInterval = 0, positions: (from: CGPoint, to: CGPoint) = (from: CGPoint.zero, to: CGPoint.zero)) {
        
        imgView.backgroundColor = .blue
        
        if animationIsAdding {
            return
        }
        animationIsAdding = true
        removeAllAnimation()
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [1, 0.9]
        scaleAnimation.keyTimes = [0, 1]
        
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [1, 0]
        opacityAnimation.keyTimes = [0, 1]
        
        let group = CAAnimationGroup()
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.duration =  duration
        group.beginTime = CACurrentMediaTime() + delay
        group.animations = [scaleAnimation, opacityAnimation]
        
        imgContentView.layer.add(group, forKey: "UserViewAvatarDisStrengthAnimation")
        
        animationIsAdding = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension VirtualGuideAvatarView: CAAnimationDelegate {
    func animationDidStart(_ anim: CAAnimation) {
        guard let value = anim.value(forKey: animationType) as? String else {
            return
        }
        if value == animationTypeAppear {
            appearAnimationDidStartBlk?(self)
        } else if value == animationTypeDisAppear {
            disAppearAnimationDidStartBlk?(self)
        }
    }
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard let value = anim.value(forKey: animationType) as? String else {
            return
        }
        if value == animationTypeAppear {
            appearAnimationDidStopBlk?(self)
        } else if value == animationTypeDisAppear {
            disAppearAnimationDidStopBlk?(self)
        } else if value == animationTypeAppearToCenter {
            print("🐯 animationDidStop: \(imgContentView.layer.anchorPoint) \(frame)")
        }
        
    }
}

extension VirtualGuideAvatarView : VirtualAvatarViewable {
    func set(data: VirtualAvataring) {
        imgView.backgroundColor = .gray
//        imgView.pug_setImage(with: URL(string: data.itemImgUrl))
    }
    
}

protocol VirtualAvataring {
    var itemId: String { get }
    var itemImgUrl: String { get }
}

protocol VirtualAvatarsViewDelegate: AnyObject {
    func userViewDidAppear(view: VirtualAvatarsViewable, userView: VirtualAvatarViewable, index: Int)
    func viewDidAppear(view: VirtualAvatarsViewable)
    func userViewDidClicked(view: VirtualAvatarsViewable, userView: VirtualAvatarViewable, index: Int)
    func userViewDidDisAppear(view: VirtualAvatarsViewable, userView: VirtualAvatarViewable, index: Int)
    func viewDidDisAppear(view: VirtualAvatarsViewable)
}

protocol VirtualAvatarsViewable {
    func set(viewDelegate: VirtualAvatarsViewDelegate);
    func set(data: [VirtualAvataring]);
}

protocol VirtualAvatarViewable {
    func set(data: VirtualAvataring);
}
