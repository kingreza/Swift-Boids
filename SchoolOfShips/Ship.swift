//
//  File.swift
//  SchoolOfShips
//
//  Created by Reza Shirazian on 2015-06-23.
//  Copyright (c) 2015 Reza Shirazian. All rights reserved.
//

import SceneKit
import QuartzCore

class Ship{
    
    var node: SCNNode;
    var velocity: SCNVector3 = SCNVector3(x: CGFloat(1), y: CGFloat(1), z:CGFloat(1))
    var prevDir: SCNVector3 = SCNVector3(x: CGFloat(0), y: CGFloat(1), z:CGFloat(0))
    
    init(newNode: SCNNode)
    {
        self.node = newNode;
    }
}

