//
//  GlobalUtils.swift
//  SomeDemo
//
//  Created by 王明友 on 2022/7/21.
//

import Foundation
import UIKit

public let OnePixel = 1 / UIScreen.main.scale
public let ScreenWidth = UIScreen.main.bounds.width
public let ScreenHeight = UIScreen.main.bounds.height
public let ScreenWidthRadio = ScreenWidth / 768

extension UIColor {
    //返回随机颜色
    open class var randomColor:UIColor{
        get
        {
            let red = CGFloat(arc4random()%256)/255.0
            let green = CGFloat(arc4random()%256)/255.0
            let blue = CGFloat(arc4random()%256)/255.0
            return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        }
    }
}
