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
    
    let texture = SKScene()
    let cameraView = SK3DNode()



    init(with portal: SCNNode, and target: SCNNode) {
        super.init()
        self.portal = portal
        self.target = target
        self.addChildNode(portal)
        self.name = "Portal"
        texture.backgroundColor = .black
        texture.addChild(cameraView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpPortal(scene: SCNScene){
        texture.scaleMode = .aspectFill
        
        cameraView.scnScene = scene
        cameraView.pointOfView = targetCamera
        
        portal.geometry?.firstMaterial?.diffuse.contents = texture
    }
    
    func teleportOffSet(player: SCNNode) -> Float{
        player.position.x + portal.position.x
    }
    
    func deactivatePorta(){
        texture.removeAllChildren()
        cameraView.scnScene = nil
        cameraView.pointOfView = nil
    }
    
}
