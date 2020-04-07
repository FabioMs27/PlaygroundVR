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
    
    var cameraDir: Float{
        return eulerPlus == 0 ? 1 : -1
    }
    ///Depends on its orientation in the screen
    var eulerPlus:Float = 0.0
    
    var texture: SKScene!
    var textCam = SKCameraNode()
    let cameraView = SK3DNode()
    
    init(with portal: SCNNode, and target: SCNNode, type: PortalType) {
        super.init()
        texture = SKScene(size: portalSize)
        texture.scaleMode = .aspectFit
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
        self.name = portal.name
        eulerPlus = target.eulerAngles.y
        
        self.physicsBody = portal.physicsBody
        portal.removeFromParentNode()
    }
    
    ///activate portal to show what is has to show
    func setUpPortal(scene: SCNScene){
        texture.addChild(cameraView)
        
        cameraView.scnScene = scene
        cameraView.pointOfView = targetCamera
        cameraView.viewportSize = CGSize(width: portalSize.width, height: portalSize.height)
//        cameraView.viewportSize = texture.size
        self.geometry?.firstMaterial?.diffuse.contents = texture
    }
    
    ///The space the player has to appear on the other side relative to the portal
    func offSet(player: SCNNode) -> SCNVector3{
        let p = player.position
        let c = self.position
        return SCNVector3(p.x - c.x, p.y - c.y, p.z - c.z)
    }
    
    ///Update what is being seen in the camera
    func updateCameraView(relativeTo player: SCNNode){
        //camera position
        let offsetPos = offSet(player: player)
        targetCamera.position.z = offsetPos.z * cameraDir
        targetCamera.position.x = offsetPos.x * cameraDir
        targetCamera.position.y = offsetPos.y

        
        //camera orientation
        ///getting horizontal angle
        let xzPlayerPoint = CGPoint(x: CGFloat(player.position.x), y: CGFloat(player.position.z))
        let xzPortalPoint = CGPoint(x: CGFloat(self.position.x), y: CGFloat(self.position.z))
        let hAngle = Float.angleToPoint(startingPoint: xzPlayerPoint, endingPoint: xzPortalPoint, radius: 45.55)
        
        let yzPlayerPoint = CGPoint(x: CGFloat(player.position.y), y: CGFloat(player.position.z))
        let yzPortalPoint = CGPoint(x: CGFloat(self.position.y), y: CGFloat(self.position.z))
        let vAngle = Float.angleToPoint(startingPoint: yzPlayerPoint, endingPoint: yzPortalPoint, radius: 45.57)
        
        targetCamera.eulerAngles.y = treatAngle(angle: hAngle)
        targetCamera.eulerAngles.x = (vAngle * -1)

        let distance = (offsetPos.z < 0 ? offsetPos.z * -1 : offsetPos.z)
        
//        targetCamera.camera?.fieldOfView = CGFloat(distance * 60)
//        targetCamera.position.z -= distance/3.8

        //scaling
        
        
        scaling(by: distance - 0.1)
//        textCam.setScale(CGFloat(distance/3.8))
//        texture.setScale(CGFloat(distance))
//        targetCamera.camera?.fieldOfView = CGFloat(distance) + 60
    }
    
    ///Updating the Horizontal angles
    func treatAngle(angle: Float)-> Float{
        if cameraDir == -1{
            return (angle) + eulerPlus
        }
        return ((angle - .pi)) + .pi
    }
    
    ///Update Scaling
    func scaling(by distance: Float){
//        if distance < 3.8 {
//            textCam.setScale(CGFloat((3.8 - distance) + 1))
//        }else{
//            cameraView.setScale(CGFloat(distance/0.1))
//        }
//        cameraView.projectPoint(SIMD3<Float>(repeating: distance))
        cameraView.setScale(CGFloat(distance))
        
    }
}

//MARK: - Getting Angles
//Getting angle between 2 points
extension Float {
    static func angleToPoint(startingPoint: CGPoint, endingPoint: CGPoint, radius: Float) -> Float {
        
        let originPoint = CGPoint(x: endingPoint.x - startingPoint.x, y: endingPoint.y - startingPoint.y)
        
        let originX = originPoint.x
        let originY = originPoint.y
        var radians = atan2(originY, originX)
        
        while radians < 0 {
            radians += CGFloat(2 * Double.pi)
        }
        
        return (Float(radians) + radius) * -1
    }
}
