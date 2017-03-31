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
    lightNode.light!.type = SCNLight.LightType.omni
    lightNode.position = SCNVector3(x: 0, y: 10, z: 50)
    realGameScene.rootNode.addChildNode(lightNode)
    
    // create and add an ambient light to the scene
    let ambientLightNode = SCNNode()
    ambientLightNode.light = SCNLight()
    ambientLightNode.light!.type = SCNLight.LightType.ambient
    ambientLightNode.light!.color = NSColor.darkGray
    realGameScene.rootNode.addChildNode(ambientLightNode)
    
    // retrieve the ship node
    for _ in 0...50
    {
      let shipNode = scene.rootNode.childNode(withName: "ship", recursively: true)!.clone()
      
      let ship = Ship(newNode: shipNode);
      realGameScene.rootNode.addChildNode(ship.node)
      ships.append(ship);
      ship.node.position = SCNVector3(x: CGFloat(Int(arc4random_uniform(10)) - 5), y: CGFloat(Int(arc4random_uniform(10)) - 5), z: 10.0)
      ship.node.scale = SCNVector3(x: CGFloat(0.25), y: CGFloat(0.25), z: CGFloat(0.25))
      
    }
    
    
    let shipNode = scene.rootNode.childNode(withName: "ship", recursively: true)!.clone()
    shipNode.position = SCNVector3(x: CGFloat(-100), y: CGFloat(-100), z: CGFloat(10))
    realGameScene.rootNode.addChildNode(shipNode)
    let animation = CABasicAnimation(keyPath: "rotation")
    animation.toValue = NSValue(scnVector4: SCNVector4(x: CGFloat(0), y: CGFloat(1), z: CGFloat(0), w: CGFloat(M_PI)*2))
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
    self.gameView!.backgroundColor = NSColor.black
    
    self.gameView.delegate = self;
    
  }
  
  func degToRad(_ deg: CGFloat) -> CGFloat {
    return deg / 180.0 * CGFloat(M_PI)
  }
  
  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
  {
    var percievedCenter = SCNVector3(x: CGFloat(0), y: CGFloat(0), z:CGFloat(0))
    var percievedVelocity = SCNVector3(x: CGFloat(0), y: CGFloat(0), z:CGFloat(0))
    for otherShip in ships
    {
      percievedCenter = percievedCenter + otherShip.node.position;
      percievedVelocity = percievedVelocity + otherShip.velocity;
    }
    
    for ship in ships
    {
      var v1 = flyCenterOfMass(ship, percievedCenter)
      var v2 = keepASmallDistance(ship)
      var v3 = matchSpeedWithOtherShips(ship, percievedVelocity)
      var v4 = boundPositions(ship)
      
      
      v1 *= (0.01)
      v2 *= (0.01)
      v3 *= (0.01)
      v4 *= (1.0)
      
      let forward = SCNVector3(x: CGFloat(0), y: CGFloat(0), z: CGFloat(1))
      let velocityNormal = ship.velocity.normalized()
      ship.velocity = ship.velocity + v1 + v2 + v3 + v4;
      limitVelocity(ship);
      let nor = forward.cross(velocityNormal)
      let angle = CGFloat(forward.dot(velocityNormal))
      ship.node.rotation = SCNVector4(x: nor.x, y: nor.y, z: nor.z, w: CGFloat(acos(angle)))
      ship.node.position = ship.node.position + (ship.velocity)
    }
  }
  
  func limitVelocity(_ ship: Ship)
  {
    let mag = Float(ship.velocity.length())
    let limit = Float(0.5);
    if mag > limit
    {
      ship.velocity = (ship.velocity/mag) * limit
    }
    
    
  }
  
  func flyCenterOfMass(_ ship: Ship, _ percievedCenter: SCNVector3) -> SCNVector3
  {
    
    let averagePercievedCenter = percievedCenter / Float(ships.count - 1);
    
    return (averagePercievedCenter - ship.node.position)/100;
    
  }
  
  func keepASmallDistance(_ ship: Ship) -> SCNVector3
  {
    var forceAway = SCNVector3(x: CGFloat(0), y: CGFloat(0), z:CGFloat(0))
    
    for otherShip in ships
    {
      if ship.node != otherShip.node
      {
        if abs(otherShip.node.position.distance(ship.node.position)) < 5
        {
          forceAway = (forceAway - (otherShip.node.position - ship.node.position))
        }
      }
    }
    
    return forceAway
    
  }
  
  func matchSpeedWithOtherShips(_ ship: Ship,  _ percievedVelocity: SCNVector3) -> SCNVector3 {
    
    let averagePercievedVelocity = percievedVelocity / Float(ships.count - 1);
    
    return (averagePercievedVelocity - ship.velocity)
  }
  
  func boundPositions(_ ship: Ship) -> SCNVector3 {
    var rebound = SCNVector3(x: CGFloat(0), y: CGFloat(0), z:CGFloat(0))
    
    let Xmin = -30;
    let Ymin = -30;
    let Zmin = -30;
    
    let Xmax = 30;
    let Ymax = 30;
    let Zmax = 70;
    
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
  
}






























