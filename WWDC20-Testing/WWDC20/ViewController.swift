//
//  ViewController.swift
//  WWDC20
//
//  Created by Fábio Maciel de Sousa on 26/03/20.
//  Copyright © 2020 Fábio Maciel de Sousa. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

//MARK: - ViewController
class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    var scene: SCNScene!
    var duplicateScene: SCNScene!
    ///Cameras
    var mainCam: SCNNode!
    var arCam: SCNNode!
    var initialCamPos = SCNVector3Zero
    var relativeCamPos = SCNVector3Zero
    ///update the portals according to the room you are in. Turning off the portals from the rooms you are not in.
    var currRoomIndex = 0{
        willSet{
            for i in 0..<roomCount{
                if i != newValue{
                    portalsIn[i].deactivatePorta()
                    portalsOut[i].deactivatePorta()
                }else{
                    portalsIn[i].setUpPortal(scene: duplicateScene)
                    portalsOut[i].setUpPortal(scene: duplicateScene)
                }
            }
        }
    }
    ///properties for the next room and last room according to the room you are in
    var nextIndex: Int{
        return currRoomIndex + 1 == roomCount ? 0 : currRoomIndex + 1
    }
    var lastIndex: Int{
        return currRoomIndex - 1 < 0 ? roomCount - 1 : currRoomIndex - 1
    }
    
    ///Portals
    var portalsIn = [Portal]()
    var portalsOut = [Portal]()
    let roomCount = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        scene = SCNScene(named: "art.scnassets/main.scn")!
        
        //Set up duplicate Scene
        duplicateScene = SCNScene(named: "art.scnassets/main.scn")!
        
        //Set the viewController as delegate of the physicsWorld of the scene
        scene.physicsWorld.contactDelegate = self
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Set up Cameras
        mainCam = scene.rootNode.childNode(withName: "mainCam", recursively: true)
        
        ///Setting up the main cam to be the point of view, thus making the game VR using the arCam informations like  orientation and movement
        arCam = sceneView.pointOfView
        sceneView.pointOfView = mainCam
        ///Getiing the initial position of the camera and updating it when telleporting. This way I can know the position relative to the ArCam.
        initialCamPos = mainCam.position
        relativeCamPos = arCam.position
        setUpPortals()
        currRoomIndex = 0
    }
    
    //MARK: - Setting up Portals
    func setUpPortals(){
        var portalIn = [SCNNode]()
        var portalOut = [SCNNode]()
        var duplPortalIn = [SCNNode]()
        var duplPortalOut = [SCNNode]()

        for i in 0..<roomCount{
            ///normal scene
            guard let nodeIn = scene.rootNode.childNode(withName: "PortalIn-\(i)", recursively: true) else{return}
            guard let nodeOut = scene.rootNode.childNode(withName: "PortalOut-\(i)", recursively: true) else{return}
            
            portalIn.append(nodeIn)
            portalOut.append(nodeOut)
            
            ///duplicate scene
            guard let duplNodeIn = duplicateScene.rootNode.childNode(withName: "PortalIn-\(i)", recursively: true) else{return}
            guard let duplNodeOut = duplicateScene.rootNode.childNode(withName: "PortalOut-\(i)", recursively: true) else{return}
            
            duplPortalIn.append(duplNodeIn)
            duplPortalOut.append(duplNodeOut)
        }
        
        for i in 0..<roomCount{
            let nextI = i == roomCount - 1 ? 0 : i + 1
            let lastI = i == 0 ? roomCount - 1 : i - 1
            let portalInSet = Portal(with: portalIn[i], and: duplPortalOut[lastI])
            let portalOutSet = Portal(with: portalOut[i], and: duplPortalIn[nextI])
            portalsIn.append(portalInSet)
            portalsOut.append(portalOutSet)
        }
    }
    
    // MARK: - Camera Movement and Orientation
    func move(){
        ///orientation
        mainCam.orientation = arCam.orientation
        
        ///movement
        let i = initialCamPos
        let r = relativeCamPos
        let a = arCam.position
        let distance = SCNVector3(r.x - a.x, r.y - a.y, r.z - a.z)
        mainCam.position = SCNVector3(i.x + distance.x, i.y + distance.y, i.z + distance.z)
    }
    
    func teleport(to portal: Portal){
        let offSet = portal.teleportOffSet(player: mainCam)
        initialCamPos = portal.target.position
        initialCamPos.x += offSet
        relativeCamPos = arCam.position
        mainCam.position = initialCamPos
        
        ///treatment to CurrRoomIndex to make the rooms loop. If you are in the first room and want to go back this code will allow you to go to the latest room
        if (portal.name?.contains("In"))! {
            currRoomIndex = lastIndex

        }else{
            currRoomIndex = nextIndex
        }
        portalsIn[currRoomIndex].setUpPortal(scene: duplicateScene)
    }
}

// MARK: - ARSCNViewDelegate
///Update and worldtracking
extension ViewController: ARSCNViewDelegate{
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        move()
    }
}

// MARK: - Physics Handling
extension ViewController: SCNPhysicsContactDelegate{
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        ///Check if one of the objects coliding is a portal and than telleport the player to it
        if let portal = (contact.nodeA as? Portal), contact.nodeA.name == "Portal" {
            teleport(to: portal)
        }
        if let portal = (contact.nodeB as? Portal),contact.nodeA.name == "Portal" {
            teleport(to: portal)
        }
    }
}
