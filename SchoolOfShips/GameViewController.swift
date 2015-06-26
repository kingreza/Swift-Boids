//
//  GameViewController.swift
//  SchoolOfShips
//
//  Created by Reza Shirazian on 2015-06-22.
//  Copyright (c) 2015 Reza Shirazian. All rights reserved.
//

import SceneKit
import QuartzCore

class GameViewController: NSViewController, SCNSceneRendererDelegate {
    
    @IBOutlet weak var gameView: GameView!
    
    var ships: [Ship] = [Ship]();
    
   
    override func awakeFromNib(){
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.dae")!
        
        let realGameScene = SCNScene();
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        realGameScene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 70)
        cameraNode.camera?.zFar = 100
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 50)
        realGameScene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = NSColor.darkGrayColor()
        realGameScene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
        for x in 0...10
        {
            var shipNode = scene.rootNode.childNodeWithName("ship", recursively: true)!.clone() as! SCNNode
           
            var ship = Ship(newNode: shipNode);
            realGameScene.rootNode.addChildNode(ship.node)
            ships.append(ship);
            ship.node.position = SCNVector3(x: CGFloat(Int(arc4random_uniform(20)) * x), y: CGFloat(Int(arc4random_uniform(20))), z: CGFloat(10))
            ship.node.rotation = SCNVector4(x: 0.0, y: 0.0, z: 0.0, w: -3.1415 / 2.0)
            ship.node.scale = SCNVector3(x: CGFloat(0.5), y: CGFloat(0.5), z: CGFloat(0.5))

//            let animation = CABasicAnimation(keyPath: "rotation")
//            animation.toValue = NSValue(SCNVector4: SCNVector4(x: CGFloat(0), y: CGFloat(1), z: CGFloat(0), w: CGFloat(M_PI)*2))
//            animation.duration = 30000
//            animation.repeatCount = MAXFLOAT //repeat forever
            //ship.node.addAnimation(animation, forKey: nil)
        }
        
       
        var shipNode = scene.rootNode.childNodeWithName("ship", recursively: true)!.clone() as! SCNNode
        shipNode.position = SCNVector3(x: CGFloat(-100), y: CGFloat(-100), z: CGFloat(10))
        realGameScene.rootNode.addChildNode(shipNode)
        let animation = CABasicAnimation(keyPath: "rotation")
        animation.toValue = NSValue(SCNVector4: SCNVector4(x: CGFloat(0), y: CGFloat(1), z: CGFloat(0), w: CGFloat(M_PI)*2))
        animation.duration = 30000
        animation.repeatCount = MAXFLOAT //repeat forever
        shipNode.addAnimation(animation, forKey: nil)
        
        // animate the 3d object


        // set the scene to the view
        self.gameView!.scene = realGameScene
        
        // allows the user to manipulate the camera
        self.gameView!.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        self.gameView!.showsStatistics = true
        
        // configure the view
        self.gameView!.backgroundColor = NSColor.blackColor()
        
        self.gameView.delegate = self;
        
    }
    
    func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval)
    {
        for ship in ships
        {
            var v1 = flyCenterOfMass(ship)
            var v2 = keepASmallDistance(ship)
            var v3 = matchSpeedWithOtherShips(ship)
            var v4 = boundPositions(ship)
            
            
            v1 *= (0.01)
            v2 *= (0.01)
            v3 *= (0.01)
            v4 *= (1.0)
            
            var positionToBe = ship.node.position + ship.velocity + v1 + v2 + v3 + v4;
            //look_at(ship, positionToBe: positionToBe);
            
            /*
                I need to figure out how I can rotate the models to face the directions they are going.
            */
            
            rotateShipToFaceForward(ship, positionToBe: positionToBe);
            ship.velocity = ship.velocity + v1 + v2 + v3 + v4;
            limitVelocity(ship);
//            var angle = calculateAngle(ship.velocity.x, y1: ship.velocity.y, x2: CGFloat(0), y2: CGFloat(0))
//            ship.node.rotation = SCNVector4(x: 0.0, y: -1.0, z: 0.0, w: CGFloat(angle))
            //updateLocal(ship);
          
            ship.prevDir = (ship.node.position - ship.velocity).normalized();
            ship.node.position = ship.node.position + (ship.velocity)
        }
    }
    
    func limitVelocity(ship: Ship)
    {
        var mag = Float(ship.velocity.length())
        var limit = Float(0.2);
        if mag > limit
        {
            ship.velocity = (ship.velocity/mag) * limit
        }
        
        
    }
    
    func look_at(ship: Ship, aim: SCNVector3)
    {
        var up = SCNVector3(x: CGFloat(0), y: CGFloat(1), z:CGFloat(0))
        var z = (ship.node.position - aim).normalized();
        
        if (z.length() == 0)
        {
            z.z = 1;
        }
        
        var x = up.cross(z).normalized();
        
        if (x.length() == 0)
        {
            z.x += 0.001
            x = up.cross(z).normalized();
        }
        
        var y = z.cross(x).normalized();
 
        
        
    }
    func flyCenterOfMass(ship: Ship) -> SCNVector3
    {
        var percieved_center = SCNVector3(x: CGFloat(0), y: CGFloat(0), z:CGFloat(0))
        
        for otherShip in ships
        {
            if ship.node != otherShip.node
            {
                percieved_center = percieved_center + otherShip.node.position;
            }
        }
        
        percieved_center = percieved_center / Float(ships.count - 1);
        
        return (percieved_center - ship.node.position)/100;
        
    }
    
    func keepASmallDistance(ship: Ship) -> SCNVector3
    {
        var force_away = SCNVector3(x: CGFloat(0), y: CGFloat(0), z:CGFloat(0))
        
        for otherShip in ships
        {
            if ship.node != otherShip.node
            {
                if abs(otherShip.node.position.distance(ship.node.position)) < 18
                {
                    force_away = (force_away - (otherShip.node.position - ship.node.position))
                }
            }
        }
        
        return force_away

    }
    
    func matchSpeedWithOtherShips(ship: Ship) -> SCNVector3
    {
        var percieved_velocity = SCNVector3(x: CGFloat(0), y: CGFloat(0), z:CGFloat(0))
        
        for otherShip in ships
        {
            if ship.node != otherShip.node
            {

                percieved_velocity = percieved_velocity + otherShip.velocity;
            }
        }
        
        percieved_velocity = percieved_velocity / Float(ships.count - 1);
        
        return (percieved_velocity - ship.velocity)
    }
    
    func boundPositions(ship: Ship) -> SCNVector3
    {
         var rebound = SCNVector3(x: CGFloat(0), y: CGFloat(0), z:CGFloat(0))
        
        var Xmin = -30;
        var Ymin = -30;
        var Zmin = -30;
        
        var Xmax = 30;
        var Ymax = 30;
        var Zmax = 70;
        
        if ship.node.position.x < CGFloat(Xmin)
        {
            rebound.x = 1;
        }
        
        if ship.node.position.x > CGFloat(Xmax)
        {
            rebound.x = -1;
        }
        
        if ship.node.position.y < CGFloat(Ymin)
        {
            rebound.y = 1;
        }
        
        if ship.node.position.y > CGFloat(Ymax)
        {
            rebound.y = -1;
        }
        
        if ship.node.position.z < CGFloat(Zmin)
        {
            rebound.z = 1;
        }
        
        if ship.node.position.z > CGFloat(Zmax)
        {
            rebound.z = -1;
        }
        
        return rebound;

    }
    
    func calculateAngle(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat) -> Float
    {
        var x = x2 - x1
        var y = y2 - y1
        
        var rot = Float(atan2(x, y));
        
        return rot;

    }
    
    func rotateShipToFaceForward(ship: Ship, positionToBe: SCNVector3)
    {
        var source = (ship.node.position - ship.velocity).normalized();
        var destination = (positionToBe - ship.node.position).normalized();
        
        var dot = source.dot(destination)
       
        var rotAngle = GLKMathDegreesToRadians(acos(dot));
        var rotAxis = source.cross(destination);
        
        rotAxis.normalize();

        var q = GLKQuaternionMakeWithAngleAndAxis(Float(rotAngle), Float(rotAxis.x), Float(rotAxis.y), Float(rotAxis.z))
        
        ship.node.rotation = SCNVector4(x: CGFloat(q.x), y: CGFloat(q.y), z: CGFloat(q.z), w: CGFloat(q.w))
   
        
    }
    
    func updateLocal(ship: Ship, aim: SCNVector3)
    {
        var m11 = ship.velocity.x;
        var m21 = ship.velocity.y;
        var m31 = ship.velocity.z;
        
        var tempUp: SCNVector3 = SCNVector3(x: CGFloat(0), y: CGFloat(1), z:CGFloat(0))
        
        var newZ = ship.velocity.cross(tempUp);
        
        newZ.normalize();
        
        var m12 = newZ.x
        var m22 = newZ.y
        var m32 = newZ.z
        
        var newY = newZ.cross(ship.velocity)
        
        newY.normalize();
        
        var m13 = newY.x
        var m23 = newY.y
        var m33 = newY.z
        
        var rotAngle = (((360/(2*3.14159265)))*(acos(0.5*(m11+m22+m33-1))));
        
        var denom = 2 * (sin((rotAngle*3.14159265)/180));
        
        var ux = (m32-m23)/denom;
        var uy = (m13-m31)/denom;
        var uz = (m21-m12)/denom;
        
        var rotateVector: SCNVector3 = SCNVector3(x: CGFloat(ux), y: CGFloat(uy), z:CGFloat(uz))
        
        rotateVector.normalize()
        
        ship.node.rotation = SCNVector4(x: ux, y: uy, z: uz, w: rotAngle)


        
    }
}






























