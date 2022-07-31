//
//  VirtualGuideBottomAvatarsView.swift
//  SomeDemo
//
//  Created by wangmingyou on 2022/7/23.
//

import Foundation
import UIKit

private let bottomAvatarsViewAnimationY: CGFloat = 40
private let contentInnerEdgeInset = UIEdgeInsets(top: bottomAvatarsViewAnimationY, left: 20, bottom: 0, right: 20)
private let avartarViewSize: CGSize = CGSize(width: 60, height: 60)
private let avartarViewXPadding: CGFloat = 12

// 动画相关
private let avartarAppearAnimationDuration: CFTimeInterval = 0.2
private let avartarAppearAnimationDelay: CFTimeInterval = 0.033

// MARK: 底部视图
final class VirtualGuideBottomAvatarsView: UIView {
    
    static func viewSize(viewWidth: CGFloat) -> CGSize {
        let h: CGFloat = contentInnerEdgeInset.top + avartarViewSize.height + contentInnerEdgeInset.bottom
        return CGSize(width: viewWidth, height: h)
    }
    
    init(frame: CGRect, subViewsCount: Int) {
        super.init(frame: frame)
        assert(subViewsCount >= 0 ,"subViewsCount must > 0 ")
        self.subViewsCount = subViewsCount
        initSubViews()
    }
    
    func resetViews(subViewsCount: Int) {
        assert(subViewsCount >= 0 ,"subViewsCount must > 0 ")
        userViews.forEach {
            $0.removeFromSuperview()
        }
        contentView.removeFromSuperview()
        self.subViewsCount = subViewsCount
        isInit = false
        initSubViews()
    }
    
    
    // 底部avatars 开始执行动画
    func appear(selectedIndex: Int) {
        if isAnimating {
            return
        }
        firstStartAppearAnimation(selectedIndex: selectedIndex)
    }
    
    func selectedAppear(selectedIndex: Int) {
        if isAnimating {
            return
        }
        startSelectedAppearAnimation(selectedIndex: selectedIndex, disSelectedIndex: self.selectedIndex)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        assert(isInit, "⚠️⚠️⚠️⚠️必须保证bounds不为空⚠️⚠️⚠️⚠️")
        layoutViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private let contentView = UIScrollView()
    private var userViews = [VirtualGuideBottomAvatarView]()
    private weak var viewDelegate: VirtualAvatarsViewDelegate? = nil
    private(set) var selectedIndex: Int = -1
    private(set) var disSelectedIndex: Int = -1
    
    private var animationIsAdding = false
    private var isAnimating = false
    private var isInit = false
    private(set) var subViewsCount: Int = 0
    var appearAnimationOperationFinishBlk: (() -> Void)?
    var startSelectedAppearAnimationOperationFinishBlk: (() -> Void)?
}

// 布局相关
extension VirtualGuideBottomAvatarsView {
    private func layoutViews() {
        guard !bounds.size.equalTo(.zero) else { return }
        
        contentView.backgroundColor = .clear
        contentView.frame = bounds
        let contentW: CGFloat = contentInnerEdgeInset.left + contentInnerEdgeInset.right + CGFloat(subViewsCount) * avartarViewSize.width + fmax(0, (CGFloat(subViewsCount) - 1)) * avartarViewXPadding
        contentView.contentSize = CGSize(width: contentW, height: bounds.height)
        
        // 从左到右
        let y: CGFloat = contentInnerEdgeInset.top - bottomAvatarsViewAnimationY
        for (index, userView) in userViews.enumerated() {
            let x: CGFloat = contentInnerEdgeInset.left + CGFloat(index) * (avartarViewSize.width + avartarViewXPadding)
            userView.frame = CGRect(origin: CGPoint(x: x, y: y), size: avartarViewSize)
        }
    }
    
    private func initSubViews() {
        if isInit {
            return
        }
        
        contentView.showsHorizontalScrollIndicator = false
        contentView.showsVerticalScrollIndicator = false
        addSubview(contentView)
        
        for i in 0 ..< self.subViewsCount {
            let uview = VirtualGuideBottomAvatarView()
            uview.didClickBlk = { [weak self] circleView in
                guard let self = self else { return }
                if self.isAnimating {
                    print("🐯🐯🐯 正在做动画 🐯🐯🐯")
                    return
                }
                print("[VirtualGuideBottomAvatarsView] click \(i)")
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
                print("[VirtualGuideBottomAvatarView] animationDidStop \(i)")
                if let viewDelegate = self.viewDelegate, self.userViews.count > i {
                    viewDelegate.userViewDidAppear(view: self, userView: self.userViews[i], index: i)
                }
                
                if circleView == self.userViews.last {
                    print("[VirtualGuideBottomAvatarsView] animationDidStop \(i)")
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
        
        isInit = true
    }
}

// 动画相关
extension VirtualGuideBottomAvatarsView {
    
    // 底部avatar点击 - avatar 选中状态改变 & 头像和瞄边动画
    private func startSelectedAppearAnimation(_ delay: CFTimeInterval = 0, selectedIndex: Int ,disSelectedIndex: Int) {
        
        if animationIsAdding || selectedIndex == self.selectedIndex { return }
        animationIsAdding = true
        
        assert(userViews.count > disSelectedIndex, "userViews.count > disSelectedIndex is error")
        assert(userViews.count > selectedIndex, "userViews.count > selectedIndex is error")
        
        var selectedAvatarView: VirtualGuideBottomAvatarView?
        var disSelectedAvatarView: VirtualGuideBottomAvatarView?
        
        if disSelectedIndex > 0 {
            self.disSelectedIndex  = disSelectedIndex
            selectedAvatarView = userViews[selectedIndex]
        }
        
        if selectedIndex > 0 {
            self.selectedIndex  = selectedIndex
            disSelectedAvatarView = userViews[disSelectedIndex]
        }
        
        // 1. 滚动到选中位置
        // 2. 设置选中/非选中
        // 3. 做动画
        if let selectedAvatarView = selectedAvatarView {
            if selectedAvatarView.frame.maxX > ScreenWidth {
                contentView.setContentOffset(CGPoint(x: scrollToOffset(selectedAvatarView: selectedAvatarView), y: 0), animated: true)
            }
            selectedAvatarView.set(isSelected: true)
            selectedAvatarView.selectedAnimation(delay: delay)
        }
        if let disSelectedAvatarView = disSelectedAvatarView {
            disSelectedAvatarView.set(isSelected: false)
            disSelectedAvatarView.unSelectedAnimation(delay: delay)
        }
        
        animationIsAdding = false
        // 动画操作结束
        startSelectedAppearAnimationOperationFinishBlk?()
    }
    
    // 底部avatars 开始执行动画 - avatar 第一次被选中
    private func firstStartAppearAnimation(_ delay: CFTimeInterval = 0, selectedIndex: Int) {
        print("🌞 startAppearAnimation")
        
        if animationIsAdding { return }
        animationIsAdding = true
        
        assert(userViews.count > selectedIndex, "userViews.count > selectedIndex is error")
        
        self.selectedIndex = selectedIndex
        var userAnimationDelay: CFTimeInterval = delay
        let selectedAvatarView = userViews[selectedIndex]
        
        // 滚动到选中位置
        if selectedAvatarView.frame.maxX > ScreenWidth {
            contentView.setContentOffset(CGPoint(x: scrollToOffset(selectedAvatarView: selectedAvatarView), y: 0), animated: false)
        }
        // 设置选中
        selectedAvatarView.set(isSelected: true)
        // 做动画
        for avatarView in userViews {
            avatarView.appearAnimation(delay: userAnimationDelay)
            userAnimationDelay += avartarAppearAnimationDelay
        }
        
        animationIsAdding = false
        // 动画操作结束
        appearAnimationOperationFinishBlk?()
    }
    
    private func scrollToOffset(selectedAvatarView: VirtualGuideBottomAvatarView) -> CGFloat {
        return selectedAvatarView.frame.minX - ((bounds.width - avartarViewSize.width))/2
    }
    
}

// data & viewDelegate
extension VirtualGuideBottomAvatarsView: VirtualAvatarsViewable {
    func set(data: [VirtualAvataring]) {
        for (i, item) in data.enumerated() {
            if  i < userViews.count {
                userViews[i].set(data: item)
            }
        }
    }
    
    func set(viewDelegate: VirtualAvatarsViewDelegate) {
        self.viewDelegate = viewDelegate
    }
}

// MARK: 底部 avatarView

private let animationType: String = "VirtualGuideBottomAvatarViewAnimationType"
private let animationTypeAppear: String = "VirtualGuideBottomAvatarViewAnimationType_Appear"
private let animationTypeAppearToCenter: String = "VirtualGuideBottomAvatarViewAnimationType_AppearToCenter"
private let animationTypeDisAppear: String = "VirtualGuideBottomAvatarViewAnimationType_DisAppear"

final class VirtualGuideBottomAvatarView: UIControl {
    var didClickBlk: ((_ view: VirtualGuideBottomAvatarView) -> Void)?
    
    var appearAnimationDidStartBlk: ((_ view: VirtualGuideBottomAvatarView) -> Void)?
    var appearAnimationDidStopBlk: ((_ view: VirtualGuideBottomAvatarView) -> Void)?
    var disAppearAnimationDidStartBlk: ((_ view: VirtualGuideBottomAvatarView) -> Void)?
    var disAppearAnimationDidStopBlk: ((_ view: VirtualGuideBottomAvatarView) -> Void)?
    
    private let imgContentView = UIView()
    private let imgView = UIImageView()
    private let borderView = UIView()
    private var animationIsAdding = false
    private var isAppearing = false
    private var isHiddenBorder = true {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imgContentView.layer.opacity = 0
        imgContentView.backgroundColor = .clear
        addSubview(imgContentView)
        
        borderView.backgroundColor = UIColor.clear
        imgContentView.addSubview(borderView)
        
        imgView.backgroundColor = UIColor.gray
        imgView.contentMode = .scaleAspectFill
        imgContentView.addSubview(imgView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        addGestureRecognizer(tapGesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var borderWidth: CGFloat = 0
        var borderPadding: CGFloat = 0
        
        borderView.isHidden = isHiddenBorder
        
        if !isHiddenBorder {
            borderWidth = 2
            borderPadding = 2
            
            borderView.frame = bounds
            borderView.layer.cornerRadius = borderView.bounds.width/2
            borderView.layer.borderWidth = borderWidth
            borderView.layer.borderColor = UIColor.orange.cgColor
        }
        let startXY: CGFloat = borderWidth + borderPadding
        imgContentView.frame = bounds
        imgView.frame = CGRect(x: startXY, y: startXY, width: (bounds.width - CGFloat(2) * startXY), height: (bounds.height - CGFloat(2) * startXY))
        imgView.layer.cornerRadius = imgView.bounds.width/2
        imgView.layer.masksToBounds = true
        
    }
    
    
    @objc private func tapAction() {
        didClickBlk?(self)
    }
    
    func appearAnimation(duration: CFTimeInterval = avartarAppearAnimationDuration, delay: CFTimeInterval = 0) {
        if animationIsAdding {
            return
        }
        animationIsAdding = true
        appearUserAnimation(duration: duration, delay: delay)
        animationIsAdding = false
    }
    
    func selectedAnimation(duration: CFTimeInterval = 0.2, delay: CFTimeInterval = 0) {
        if animationIsAdding {
            return
        }
        animationIsAdding = true
        selectAvatarAnimation(duration: duration, delay: delay)
        animationIsAdding = false
    }
    
    func unSelectedAnimation(duration: CFTimeInterval = 0.2, delay: CFTimeInterval = 0) {
        if animationIsAdding {
            return
        }
        animationIsAdding = true
        unSelectAvatarAnimation(duration: duration, delay: delay)
        animationIsAdding = false
    }
    
    func disAppearAnimation(duration: CFTimeInterval = avartarAppearAnimationDuration, delay: CFTimeInterval = 0) {
        if animationIsAdding {
            return
        }
        animationIsAdding = true
        disAppearUserAnimation(duration: duration, delay: delay)
        animationIsAdding = false
    }
    
    private func appearUserAnimation(duration: CFTimeInterval = avartarAppearAnimationDuration, delay: CFTimeInterval = 0) {
        
        // 初始化位置，有个bug
        
        imgContentView.layer.removeAnimation(forKey: "UserViewBottomAvatarAppearInitAnimation")
        let positionAnimationY0 = CABasicAnimation(keyPath: "transform.translation.y")
        positionAnimationY0.fromValue = 0
        positionAnimationY0.toValue = bottomAvatarsViewAnimationY
        positionAnimationY0.duration = 0.01
        positionAnimationY0.beginTime = CACurrentMediaTime() + delay
        positionAnimationY0.fillMode = .forwards
        positionAnimationY0.isRemovedOnCompletion = false
        imgContentView.layer.add(positionAnimationY0, forKey: "UserViewBottomAvatarAppearInitAnimation")
        
        
        imgContentView.layer.removeAnimation(forKey: "UserViewBottomAvatarAppearAnimation")
        let positionAnimationY = CABasicAnimation(keyPath: "transform.translation.y")
        positionAnimationY.fromValue = bottomAvatarsViewAnimationY
        positionAnimationY.toValue = 0
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0
        opacityAnimation.toValue = 1
        
        let group = CAAnimationGroup()
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.duration =  avartarAppearAnimationDuration
        group.beginTime = CACurrentMediaTime() + delay + 0.01
        group.animations = [positionAnimationY, opacityAnimation]
        group.delegate = self
        group.setValue(animationTypeAppear, forKey: animationType)
        imgContentView.layer.add(group, forKey: "UserViewBottomAvatarAppearAnimation")
    }
    
    private func disAppearUserAnimation(duration: CFTimeInterval = avartarAppearAnimationDuration, delay: CFTimeInterval = 0) {
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
    
    private func selectAvatarAnimation(duration: CFTimeInterval, delay: CFTimeInterval = 0) {
        
        imgView.layer.removeAllAnimations()
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [1, 0.8, 1]
        scaleAnimation.keyTimes = [0, 0.667, 1]
        imgView.layer.add(scaleAnimation, forKey: "UserViewAvatarSelectedAnimation")
        
        borderView.layer.removeAllAnimations()
        let borderScaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        borderScaleAnimation.values = [0.5, 1]
        borderScaleAnimation.keyTimes = [0, 1]
        
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [0, 1]
        opacityAnimation.keyTimes = [0, 1]
        let group = CAAnimationGroup()
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.duration =  duration
        group.beginTime = CACurrentMediaTime() + delay
        group.delegate = self
        group.animations = [borderScaleAnimation, opacityAnimation]
        borderView.layer.add(group, forKey: "UserViewAvatarBorderSelectedAnimation")
    }
    
    private func unSelectAvatarAnimation(duration: CFTimeInterval, delay: CFTimeInterval = 0) {
        
        borderView.layer.removeAllAnimations()
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [1, 0]
        opacityAnimation.keyTimes = [0, 1]
        opacityAnimation.duration = duration
        borderView.layer.add(opacityAnimation, forKey: "UserViewAvatarBorderUnSelectedAnimation")
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension VirtualGuideBottomAvatarView: CAAnimationDelegate {
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
            print("🐯 animationDidStop:")
            appearAnimationDidStopBlk?(self)
            
        } else if value == animationTypeDisAppear {
            disAppearAnimationDidStopBlk?(self)
            
        } else if value == animationTypeAppearToCenter {
            
        }
        
    }
}

extension VirtualGuideBottomAvatarView : VirtualAvatarViewable {
    func set(data: VirtualAvataring) {
        imgView.backgroundColor = UIColor.randomColor
//        imgView.pug_setImage(with: URL(string: data.itemImgUrl))
    }
    
}

extension VirtualGuideBottomAvatarView : VirtualGuideBottomAvatarViewSelectable {
    func set(isSelected: Bool) {
        isHiddenBorder = !isSelected
    }
    
}

protocol VirtualGuideBottomAvatarViewSelectable {
    func set(isSelected: Bool)
}
