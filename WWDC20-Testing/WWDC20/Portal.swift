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

/*
    Portal class that requires portals to be in the scene to work.
    The program will count the amount of portals and set up where each one has to point.
    In the scene they need a name that can also be "in" for the portals to enter a room our "out" for the portals to exit the room. They also need a "-" and index after that refers to the rooms they are, like : "-4" for the 4th room.
 */
class Portal: SCNNode{
    
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
    let cameraView = SK3DNode()
    
    


    init(with portal: SCNNode, and target: SCNNode) {
        super.init()
        texture = SKScene(size: portalSize)
        texture.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        texture.scaleMode = .aspectFit
        
        self.portal = portal
        self.target = target
        setUpPlaceHolder()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    ///get the place holder in the scene and transform it to the portal class
    func setUpPlaceHolder(){
        self.geometry = portal.geometry
        self.position = portal.position
        self.physicsBody = portal.physicsBody
        portal.removeFromParentNode()
    }
    
    func setUpPortal(scene: SCNScene){
        texture.addChild(cameraView)
        
        cameraView.scnScene = scene
        cameraView.pointOfView = targetCamera
        cameraView.viewportSize = texture.size
        
        self.geometry?.firstMaterial?.diffuse.contents = texture
    }
    
    func teleportOffSet(player: SCNNode) -> Float{
        player.position.x + self.position.x
    }
    
    func deactivatePorta(){
        texture.removeAllChildren()
        cameraView.scnScene = nil
        cameraView.pointOfView = nil
    }
    
}
