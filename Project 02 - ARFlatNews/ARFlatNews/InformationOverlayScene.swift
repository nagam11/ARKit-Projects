//
//  InformationOverlayScene.swift
//  ARFlatNews
//
//  Created by Marla Na on 17.09.17.
//  Copyright © 2017 Marla Na. All rights reserved.
//

import SpriteKit

open class InformationOverlayScene: SKScene {
    open var labelNode: SKLabelNode?
    open var weatherNode: SKLabelNode?
    open var cursorNode: SKShapeNode?
    
    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        labelNode = SKLabelNode()
        weatherNode = SKLabelNode()
        labelNode?.position = CGPoint(x: 100, y: 400)
        weatherNode?.position = CGPoint(x: 100, y: 400)
        self.addChild(labelNode!)
        self.addChild(weatherNode!)
        cursorNode = SKShapeNode(circleOfRadius: 25.0)
        cursorNode?.strokeColor = UIColor.blue
        self.addChild(cursorNode!)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
