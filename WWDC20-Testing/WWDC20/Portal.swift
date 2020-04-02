//
//  Portal.swift
//  WWDC20
//
//  Created by Fábio Maciel de Sousa on 30/03/20.
//  Copyright © 2020 Fábio Maciel de Sousa. All rights reserved.
//

import Foundation
import SceneKit
import SpriteKit

enum PortalType{
    case In
    case Out
}

/*
    Portal class that requires portals to be in the scene to work.
    The program will count the amount of portals and set up where each one has to point.
    In the scene they need a name that can also be "in" for the portals to enter a room our "out" for the portals to exit the room. They also need a "-" and index after that refers to the rooms they are, like : "-4" for the 4th room.
 */
class Portal: SCNNode{
    
    var type: PortalType!
    var portal: SCNNode!
    var target: SCNNode!
    
    var targetCamera: SCNNode!{
        return target.childNode(withName: "camera", recursively: true)
    }
    
    //Resolution of the portal
    var portalSize: CGSize{
        return UIScreen.main.bounds.size
    }
    
    var texture: SKScene!
    var textCam = SKCameraNode()
    let cameraView = SK3DNode()
    
    init(with portal: SCNNode, and target: SCNNode, type: PortalType) {
        super.init()
        texture = SKScene(size: portalSize)
        texture.camera = textCam
        
        self.portal = portal
        self.target = target
        self.type = type
        setUpPlaceHolder()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    ///get the place holder in the scene and transform it to the portal class
    func setUpPlaceHolder(){
        self.geometry = portal.geometry
        self.position = portal.position
        self.eulerAngles = portal.eulerAngles
        self.physicsBody = portal.physicsBody
        portal.removeFromParentNode()
    }
    
    ///activate portal to show what is has to show
    func setUpPortal(scene: SCNScene){
        texture.addChild(cameraView)
        
        cameraView.scnScene = scene
        cameraView.pointOfView = targetCamera
//        cameraView.viewportSize = CGSize(width: portalSize.width/3, height: portalSize.height/3)
        cameraView.viewportSize = texture.size
        
        self.geometry?.firstMaterial?.diffuse.contents = texture
    }
    
    ///The space the player has to appear on the other side relative to the portal
    //TO-DO: change to SCNVector3 instead of float so we can always use this to get distance
    func teleportOffSet(player: SCNNode) -> Float{
        player.position.x + self.position.x
    }
    
//    ///deactivate portal for the sake of rendering power
//    func deactivatePorta(){
//        texture.removeAllChildren()
//        cameraView.scnScene = nil
//        cameraView.pointOfView = nil
//    }
//    
    ///Update what is being seen in the camera
    func updateCameraView(relativeTo player: SCNNode){
        let playerPoint = CGPoint(x: CGFloat(player.position.x), y: CGFloat(player.position.z))
        let portalPoint = CGPoint(x: CGFloat(self.position.x), y: CGFloat(self.position.z))
        let angle = Float.angleToPoint(startingPoint: playerPoint, endingPoint: portalPoint)
        targetCamera.eulerAngles.y = Float(angle/2)
        let distance = player.position.z - self.position.z
        let cameraPoint = distance
        var camPos = targetCamera.presentation.position
        camPos.z = Float(cameraPoint)
        targetCamera.position = camPos

//        cameraView.setScale(CGFloat(distance))
        textCam.setScale(CGFloat(distance))
    }
    
}

//MARK: - Getting Angles
//Getting angle between 2 points
extension Float {
    static func angleToPoint(startingPoint: CGPoint, endingPoint: CGPoint) -> Float {
        
        let originPoint = CGPoint(x: endingPoint.x - startingPoint.x, y: endingPoint.y - startingPoint.y)
        
        let originX = originPoint.x
        let originY = originPoint.y
        var radians = atan2(originY, originX)
        
        while radians < 0 {
            radians += CGFloat(2 * Double.pi)
        }
        
        return (Float(radians) + 45.5) * -1
    }
}
