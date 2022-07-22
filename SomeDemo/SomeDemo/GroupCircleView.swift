//
//  GroupCircleView.swift
//  SomeDemo
//
//  Created by 王明友 on 2022/7/21.
//

import Foundation
import UIKit

// MARK: 参数配置
// 背景弧线动画 duration & delay
private let layerAnimationDuration: CFTimeInterval = 0.3
private let layerAnimationDelay: CFTimeInterval = 0.1

// 圆动画 duration
private let circleAnimationDuration: CFTimeInterval = 0.4

// TextLabel duration
private let textAnimationDuration: CFTimeInterval = circleAnimationDuration*0.5

/*
 true：圆的中心 落在弧线上，
 false：否则是圆+Text整体的中心落在弧线上
 */
private let circleCenterInLayer = true

/*
 背景弧线
    true: 四个同半径圆，圆心线性渐变
    false: 是四个同圆心，半径线性渐变
 */
private let centerLiner = true

private let topPadding: CGFloat = 100
private let bottomPadding: CGFloat = 104
private let r0: CGFloat = 400

// MARK: GroupView
final class GroupView: UIView {
    
    deinit {
        print("🌞 dealloc")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubViews()
    }
    
    func viewDidAppear() {
        if isAppearing {
            return
        }
        isAppearing = true
        startAnimation()
    }
    
    func viewDidDisAppear() {
        isAppearing = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        print("🌞bounds:\(bounds)")
        assert(isInit, "⚠️⚠️⚠️⚠️必须保证bounds不为空⚠️⚠️⚠️⚠️")
        guard !bounds.size.equalTo(.zero) else {
            print("🌞bounds zero")
            return
        }
        
        layoutViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private(set) var item: GroupCircling?
    private weak var viewDelegate: GroupViewDelegate? = nil
    
    private let backgroundImageView = UIImageView()
    private let contentView = UIView()
    
    private lazy var layer1 = self.shapLayer()
    private lazy var layer2 = self.shapLayer()
    private lazy var layer3 = self.shapLayer()
    private lazy var layer4 = self.shapLayer()
    private var userViews = [GroupUserView]()
    
    private var animationIsAdding = false
    private var isAppearing = false
    private var isInit = false
    
    private let layerWidth: CGFloat = 1
    private var layerInitYOffset: CGFloat = 40
    
    
    private let usersRowCount: Int = 4
    private let usersHPadding: CGFloat = 25
    private let userAWH: CGFloat = 54
    private let userBWH: CGFloat = 64
    private let userCWH: CGFloat = 72
    private let circleViewCount: Int = 12
    private var dPadding: CGFloat = 0
    var animationOperationFinishBlk: (() -> Void)?
    
}

// 布局相关
extension GroupView {
    private func layoutViews() {
        bounds = self.bounds
        
        backgroundImageView.frame = bounds
        contentView.frame = bounds
        
        /**
         四段弧线，来自四个圆（从下到上）
         */
        let layerCircel1MinY = bounds.height - bottomPadding
        // 第一个（从下到上） 背景圆的半径和圆心坐标
        dPadding = (layerCircel1MinY - topPadding)/3
        let layers = [layer1, layer2, layer3, layer4]
        
        let circleViewPadding: CGFloat = (bounds.width - usersHPadding * 2 - 2*userBWH - userAWH - userCWH) / CGFloat(usersRowCount-1)
        var circleStartIndex: Int = 0
        var circleCenterX: CGFloat = usersHPadding
        
        for (i, layer) in layers.enumerated() {
            let layerCenter = getBackgroundLayerCenter(i: i)
            let raduis = getBackgroundLayerRadius(i: i)
            setCALayer(layer, origin: layerCenter, layerWidth: raduis * 2, lineWidth: layerWidth+CGFloat(i))
            
            // layut layer circleViews
            
            for _ in 0 ..< usersRowCount {
                if userViews.count > circleStartIndex {
                    let circleSize = getUserSize(type: getUserType(index: circleStartIndex))
                    let circleViewSize = GroupUserView.viewSize(avatarWH: circleSize.width)
                    if circleCenterInLayer {
                        circleCenterX += (circleSize.width)/2
                    } else {
                        circleCenterX += (circleViewSize.width)/2
                    }
                    
                    /**
                     设
                        大圆的圆心 (X0, Y0)， 大圆的半径 R
                        圆上任意一点的坐标 (x, y), 与圆心的角度 A0
                     
                     根据余弦定理
                     R * cosA0 + x = X0
                     R * sinA0 + y = Y0
                     
                     已知 x， 求y
                     let A0 = acosf(Float((X0 - x) / R))
                     let y = Y0 - R * CGFloat(sin(A0))
                     
                     当 circleCenterInLayer = true
                     circleView.frame = (x - circleW, y - circlrH, circleW, circlrH)
                     
                     当 circleCenterInLayer = false
                     circleView.frame = (x - circleViewW, y - circlrViewH, circleViewW, circlrViewH)
                     
                     
                     let a0 = acosf(Float((x0 - userX)/radius))
                     let userY = (y - dBottom) - (radius * CGFloat(sin(a0)) - dBottom) + (H - userSize.height)
                     */
                    let angle = acosf(Float((layerCenter.x - circleCenterX) / raduis))
//                    let layer0CenterPadding: CGFloat = r0 - bottomPadding
                    let circleCenterY: CGFloat = layerCenter.y - raduis * CGFloat(sin(angle))
                    
                    let circleView = userViews[circleStartIndex]
                    
                    if circleCenterInLayer {
                        circleView.frame = CGRect(origin: CGPoint(x: circleCenterX - circleSize.width/2, y: circleCenterY - circleSize.height/2), size: circleViewSize)
                        circleCenterX += (circleSize.width)/2 + circleViewPadding
                    } else {
                        circleView.frame = CGRect(origin: CGPoint(x: circleCenterX - circleViewSize.width/2, y: circleCenterY - circleViewSize.height/2), size: circleViewSize)
                        circleCenterX += (circleViewSize.width)/2 + circleViewPadding
                    }
                    
                    if (circleStartIndex+1) % usersRowCount == 0 {
                        circleCenterX = usersHPadding
                    }
                    
                    circleStartIndex += 1
                }
                
            }
        }
    }
    
    private func initSubViews() {
        if isInit {
            return
        }
        
        backgroundImageView.backgroundColor = .white
        addSubview(backgroundImageView)
        contentView.backgroundColor = .red
        addSubview(contentView)
        
        layer1.opacity = 0
        contentView.layer.addSublayer(layer1)
        
        layer2.opacity = 0
        contentView.layer.addSublayer(layer2)
        
        layer3.opacity = 0
        contentView.layer.addSublayer(layer3)
        
        layer4.opacity = 0
        contentView.layer.addSublayer(layer4)
        
        for i in 0 ..< circleViewCount {
            let uview = GroupUserView()
            uview.didClickBlk = { [weak self] circleView in
                guard let self = self else { return }
                print("[GroupView] click \(i)")
                if let viewDelegate = self.viewDelegate, let circles = self.item?.circles, circles.count > i {
                    viewDelegate.circleViewDidClicked(view: self, circleView: circleView, index: i)
                }
            }
            contentView.addSubview(uview)
            userViews.append(uview)
        }
        
        isInit = true
    }
    // MARK:
    private func getBackgroundLayerCenter(i: Int) -> CGPoint {
        if centerLiner {
            let y0 = (bounds.height - bottomPadding + r0)
            return CGPoint(x: bounds.width/2, y: y0 - dPadding * CGFloat(4-1-i))
            
        } else {
            return CGPoint(x: bounds.width/2, y: (bounds.height - bottomPadding + r0))
        }
    }
    private func getBackgroundLayerRadius(i: Int) -> CGFloat {
        if centerLiner {
            return r0
        } else {
            return (r0 + dPadding * CGFloat(4-1-i))
        }
    }
    private func getUserType(index: Int) -> UserViewType {
        if index == 0 || index == 7 || index == 9 {
            return .A
        } else  if index == 1 || index == 3 || index == 4 || index == 6 || index == 8 || index == 10 {
            return .B
        } else  if index == 2 || index == 5 || index == 11 {
            return .C
        }
        return .A
    }
    private func getUserSize(type: UserViewType) -> CGSize {
        switch type {
        case .A:
            return CGSize(width: userAWH, height: userAWH)
        case .B:
            return CGSize(width: userBWH, height: userBWH)
        case .C:
            return CGSize(width: userCWH, height: userCWH)
        }
    }
    
}

// 动画相关
extension GroupView {
    private func startAnimation(_ delay: UInt = 0) {
        print("🌞 startAnimation")
        if animationIsAdding { return }
        
        animationIsAdding = true
        
        // do animation
        addLayerAnimation(calayer: layer1)
        addLayerAnimation(calayer: layer2, delay: layerAnimationDelay)
        addLayerAnimation(calayer: layer3, delay: layerAnimationDelay*2)
        addLayerAnimation(calayer: layer4, delay: layerAnimationDelay*3)
        
        // 第二根线动画开始，开始做头像动画
        var userAnimationDelay = layerAnimationDuration + layerAnimationDelay
        /**
         头像出现顺序： 序号6运动开始

         100ms后 序号3和9同时开始运动 ; 66ms后 序号2开始运动

         33ms后 序号11开始运动 ; 33ms后 序号1、4、5、7开始运动

         33ms后 序号8开始运动 ; 33ms后 序号10、12开始运动
         */
        let userAnimationIndexGroup = [[5], [2,8], [1], [10], [0,3,4,6],[7],[9, 11]]
        let userAnimationDelayGroup = [0, 0.1, 0.066, 0.033, 0.033, 0.033, 0.033]
        
        if userViews.count < circleViewCount || userAnimationDelayGroup.count != userAnimationIndexGroup.count {
            assert(false, "⚠️⚠️⚠️⚠️检查数据，还没有initSubViews⚠️⚠️⚠️⚠️")
            // 异常情况，就简单出现
            var i: Int = 0
            for (index, circleView) in userViews.enumerated() {
                if let viewDelegate = viewDelegate {
                    viewDelegate.circleViewDidAppear(view: self, circleView: circleView, index: index)
                } else {
                    print("[GroupView] mv error")
                }
                i += 1
                circleView.startAnimation()
            }
        } else {
            for (index, animationIndexs) in userAnimationIndexGroup.enumerated() {
                userAnimationDelay += userAnimationDelayGroup[index]
                for userViewIndex in animationIndexs {
                    if userViews.count > userViewIndex {
                        let circleView = userViews[userViewIndex]
                        if let viewDelegate = viewDelegate {
                            viewDelegate.circleViewDidAppear(view: self, circleView: circleView, index: userViewIndex)
                        }
                        circleView.startAnimation(delay: userAnimationDelay)
                    }
                }
            }
        }
        animationIsAdding = false
        
        // 动画操作结束
        animationOperationFinishBlk?()
        
    }
    // MARK:
    private func setCALayer(_ shapeLayer: CAShapeLayer, origin: CGPoint, layerWidth: CGFloat, lineWidth: CGFloat) {
        
        shapeLayer.lineWidth = lineWidth
        //设置半径
        let radius: CGFloat = layerWidth/2 - lineWidth/2
        //按照顺时针方向
        let clockWise = false
        //初始化一个路径
        let path = UIBezierPath(arcCenter: CGPoint(x: origin.x, y: origin.y), radius: radius, startAngle: 0, endAngle: 2.0 * .pi, clockwise: clockWise)
        shapeLayer.path = path.cgPath
    }
    
    private func shapLayer() -> CAShapeLayer {
        let shapLayer = CAShapeLayer()
        shapLayer.lineWidth = layerWidth
        //圆环的颜色
        shapLayer.strokeColor = UIColor.randomColor.cgColor
        //背景填充色
        shapLayer.fillColor = UIColor.clear.cgColor
        return shapLayer
    }
    
    private func addLayerAnimation(calayer: CAShapeLayer, delay: CFTimeInterval = 0) {
        calayer.removeAllAnimations()
        
        let positionAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        positionAnimation.values = [layerInitYOffset, -10, 0]
        positionAnimation.keyTimes = [0, 0.6, 1]
        positionAnimation.calculationMode = .cubic
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0
        opacityAnimation.toValue = 1
        opacityAnimation.duration = layerAnimationDuration
        
        let group = CAAnimationGroup()
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.duration =  layerAnimationDuration
        group.beginTime = CACurrentMediaTime() + delay
        group.animations = [positionAnimation, opacityAnimation]
        calayer.add(group, forKey: "positionAnimation")
    }
}

// 对外调用
extension GroupView: GroupViewable {
    // MARK: Viewable
    func set(viewDelegate: GroupViewDelegate) {
        self.viewDelegate = viewDelegate
    }
    
    func set(data: GroupCircling) {
        assert(!userViews.isEmpty, "⚠️⚠️⚠️cirecleViews 还未完成初始化⚠️⚠️⚠️")
        self.item = data
        let circles = data.circles
        for (index, cirecleView) in userViews.enumerated() {
            cirecleView.isHidden = true
            if index < circles.count {
                var circleItem = circles[index]
                circleItem.itemText = "\(index)"
                cirecleView.isHidden = false
                cirecleView.set(data: circleItem)
            }
        }
    }
}

// MARK: GroupUserView
enum UserViewType : String {
    /**
     设计稿：
     https://app.zeplin.io/project/62ce2e7e7a8c22120dc4277c/dashboard?sid=62ce974933ac8410b55ed6c1
     详细： https://app.zeplin.io/project/62ce2e7e7a8c22120dc4277c/screen/62ce974933ac8410b55ed6c1
     */
    /**
     3行4列，从左到右，index从1开始 [1,2,3,4,5,6,7,8,9,10,11,12]
     A 对应 1，8，10
     B 对应 2，4，5，7，9，11
     C 对应 3，6，12
     */
    case A
    case B
    case C
}

final class GroupUserView: UIView {
    
    var didClickBlk: ((_ view: GroupUserView) -> Void)?
    private var item: Circling?
    
    private let imgContentView = UIView()
    private let imgView1 = UIImageView()
    private let imgView2 = UIImageView()
    private let imgView3 = UIImageView()
    private let imgView4 = UIImageView()
    
    private var shapMaskLayer = CAShapeLayer()
    private let label: UILabel =  {
        let view = UILabel()
        view.text = "Label"
        view.font = UIFont.systemFont(ofSize: 10)
        view.textColor = .white
        view.textAlignment = .center
        view.backgroundColor = UIColor.black
        return view
    }()
    private static let maskOffset: CGFloat = 2
    private static let labelOffset: CGFloat = 15
    private static let labelH: CGFloat = 22
    private var animationIsAdding = false
    private let labelViewSize = CGSize(width: 46, height: labelH)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imgContentView.layer.opacity = 0
        imgContentView.backgroundColor = .clear
        imgView1.contentMode = .scaleAspectFill
        imgView2.contentMode = .scaleAspectFill
        imgView3.contentMode = .scaleAspectFill
        imgView4.contentMode = .scaleAspectFill
        
        imgContentView.addSubview(imgView1)
        imgContentView.addSubview(imgView2)
        imgContentView.addSubview(imgView3)
        imgContentView.addSubview(imgView4)
        addSubview(imgContentView)
        
        label.textColor = .white
        label.text = "Text"
        label.layer.opacity = 0
        addSubview(label)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        addGestureRecognizer(tapGesture)
        
        //
        imgView1.backgroundColor = UIColor.randomColor
        imgView2.backgroundColor = UIColor.randomColor
        imgView3.backgroundColor = UIColor.randomColor
        imgView4.backgroundColor = UIColor.randomColor
    }
    
    @objc private func tapAction() {
        didClickBlk?(self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = .clear
        print("🌞layoutSubviews bounds:\(bounds)")
        let imageWH = (bounds.width)
        
        imgContentView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: imageWH, height: imageWH))
        
        if let imgUrls = item?.covers, imgUrls.count >= 4 {
            let wh = imageWH/2
            imgView1.frame = CGRect(x: 0, y: 0, width: wh, height: wh)
            imgView2.frame = CGRect(x: wh, y: 0, width: wh, height: wh)
            imgView3.frame = CGRect(x: 0, y: wh, width: wh, height: wh)
            imgView4.frame = CGRect(x: wh, y: wh, width: wh, height: wh)
            imgView1.isHidden = false
            imgView2.isHidden = false
            imgView3.isHidden = false
            imgView4.isHidden = false
            
        } else {
            imgView1.isHidden = false
            imgView2.isHidden = true
            imgView3.isHidden = true
            imgView4.isHidden = true
            imgView1.frame = imgContentView.bounds
        }
        
        label.frame = CGRect(origin: CGPoint(x: (bounds.width - labelViewSize.width)/2, y: imgContentView.frame.maxY - Self.labelOffset), size: labelViewSize)
        label.layer.cornerRadius = (labelViewSize.height / 2)
        label.layer.masksToBounds = true
        
        let maskW = labelViewSize.width + 2*Self.maskOffset
        let maskH = labelViewSize.height + 2*Self.maskOffset
        
        // 会有1像素的边框，可能是系统精度问题，所以radius 取大一点
        let maskPath1 = UIBezierPath(arcCenter: imgContentView.center, radius: (imageWH+2)/2, startAngle: 0, endAngle: 2.0 * .pi, clockwise: false)
        let maskPath = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: (imageWH-maskW)/2, y: label.frame.minY - Self.maskOffset), size: CGSize(width: maskW, height: maskH)), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: maskH/2, height: maskH/2))
        maskPath1.append(maskPath)
        shapMaskLayer.fillColor = UIColor.white.cgColor
        shapMaskLayer.path = maskPath1.cgPath
        imgContentView.layer.cornerRadius = imageWH/2
        imgContentView.layer.masksToBounds = true
        imgContentView.layer.mask = shapMaskLayer
        
    }
    
    func set(data: Circling) {
        self.item = data
        
        if let imgUrls = item?.covers, imgUrls.count >= 4 {
            imgView1.backgroundColor = UIColor.randomColor
            imgView2.backgroundColor = UIColor.randomColor
            imgView3.backgroundColor = UIColor.randomColor
            imgView4.backgroundColor = UIColor.randomColor
        } else {
            imgView1.backgroundColor = UIColor.randomColor
        }
        label.isHidden = data.itemText.isEmpty
        label.text = data.itemText
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func startAnimation(duration: CFTimeInterval = circleAnimationDuration, delay: CFTimeInterval = 0) {
        if animationIsAdding {
            return
        }
        animationIsAdding = true
        startCircleAnimation(duration: duration, delay: delay)
        startTextAnimation(duration: textAnimationDuration, delay: delay)
        animationIsAdding = false
    }
    
    private func startCircleAnimation(duration: CFTimeInterval = circleAnimationDuration, delay: CFTimeInterval = 0) {
        imgContentView.layer.removeAllAnimations()
        
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [0.4, 1.1, 0.9, 1]
        scaleAnimation.keyTimes = [0, 0.33, 0.67, 1]
        scaleAnimation.calculationMode = .cubic
        
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [1, 1, 1, 1]
        opacityAnimation.keyTimes = [0, 0.5, 1, 1]
        
        let group = CAAnimationGroup()
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.duration =  duration
        group.beginTime = CACurrentMediaTime() + delay
        group.animations = [scaleAnimation, opacityAnimation]
        imgContentView.layer.add(group, forKey: "UserViewAvatarAnimation")
    }
    
    private func startTextAnimation(duration: CFTimeInterval = textAnimationDuration, delay: CFTimeInterval = 0) {
        label.layer.removeAllAnimations()
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fillMode = .forwards
        opacityAnimation.isRemovedOnCompletion = false
        opacityAnimation.fromValue = 0
        opacityAnimation.toValue = 1
        opacityAnimation.duration = duration
        opacityAnimation.beginTime = CACurrentMediaTime() + delay
        label.layer.add(opacityAnimation, forKey: "UserViewLabelAnimation")
    }
    
    static func viewSize(avatarWH: CGFloat) -> CGSize {
        return CGSize(width: avatarWH , height: (avatarWH + labelH - labelOffset + maskOffset))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: protocol
struct CircleCover: CircleCoversing {
    var id = ""
    var img = ""
}

struct Circle: Circling {
    var itemId = ""
    var itemText = "Text"
    var covers: [CircleCoversing] = [CircleCover(),CircleCover(),
                                     CircleCover(),CircleCover()]
}

struct GroupCircle: GroupCircling {
    var circles: [Circling] = [Circle(),Circle(),Circle(),Circle(),Circle(),Circle(),
                               Circle(),Circle(),Circle(),Circle(),Circle(),Circle()]
}

protocol CircleCoversing {
    var id: String { get }
    var img: String { get }
}

protocol Circling {
    var itemId: String { get }
    var itemText: String { get set }
    var covers: [CircleCoversing] { get }
}

protocol GroupCircling {
    var circles: [Circling] { get }
}

protocol GroupViewDelegate: AnyObject {
    func circleViewDidAppear(view: GroupView, circleView: GroupUserView, index: Int)
    func circleViewDidClicked(view: GroupView, circleView: GroupUserView, index: Int)
}

protocol GroupViewable {
    func set(viewDelegate: GroupViewDelegate);
    func set(data: GroupCircling);
}


