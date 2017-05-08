//
//  HeatMapLayer.swift
//  Sugo
//
//  Created by Zack on 6/5/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

import UIKit

class HeatMapLayer: CALayer {

    var heat: [String: Double]
    
    init(frame: CGRect, heat: [String: Double]) {
        self.heat = heat
        super.init()
        self.frame = frame
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(in ctx: CGContext) {
        
        UIGraphicsPushContext(ctx)
        let context = UIGraphicsGetCurrentContext()
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let red: CGFloat = CGFloat(self.heat["red"]! / 255)
        let green: CGFloat = CGFloat(self.heat["green"]! / 255)
        let blue: CGFloat = CGFloat(self.heat["blue"]! / 255)
        let alpha: CGFloat = 0.8
        let color: [CGFloat] = [red, green, blue, alpha,
                                1, 1, 1, alpha]
        let locations: [CGFloat] = [0, 1]
        let gradient = CGGradient(colorSpace: colorSpace,
                                  colorComponents: color,
                                  locations: locations,
                                  count: 2)
        let radius: CGFloat = max(self.bounds.size.width / 2, self.bounds.size.height / 2)
        context?.drawRadialGradient(gradient!,
                                    startCenter: self.position,
                                    startRadius: 0,
                                    endCenter: self.position,
                                    endRadius: radius,
                                    options: CGGradientDrawingOptions.drawsAfterEndLocation)
        
        context?.saveGState()
        context?.restoreGState()
        UIGraphicsPopContext()
    }
    
}
