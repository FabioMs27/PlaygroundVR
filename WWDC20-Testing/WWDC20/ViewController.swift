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
import CoreMotion

//MARK: - ViewController
class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    var scene: SCNScene!
    var duplicateScene: SCNScene!
    ///Motion Manager
    let motionManager = CMMotionManager()
    ///Cameras
    var mainCam: SCNNode!
    var arCam: SCNNode!
    var initialCamPos = SCNVector3Zero
    var relativeCamPos = SCNVector3Zero
    ///update the portals according to the room you are in. Turning off the portals from the other rooms.
    var currRoomIndex = 0
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
    let roomCount = 4
    
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
        
        // Set up Spheres
        let sphere = scene.rootNode.childNode(withName: "Room-2", recursively: true)!
        let sphereDupl = scene.rootNode.childNode(withName: "Room-2", recursively: true)!
        setUpVideo(in: sphere)
        setUpVideo(in: sphereDupl)

        
        ///Setting up the main cam to be the point of view, thus making the game VR using the arCam informations like  orientation and movement
        arCam = sceneView.pointOfView
        sceneView.pointOfView = mainCam
        ///Getiing the initial position of the camera and updating it when telleporting. This way I can know the position relative to the ArCam.
        initialCamPos = mainCam.position
        relativeCamPos = arCam.position
        setUpPortals()
        currRoomIndex = 0
    }
    
    //MARK: - Setting up videos
    func setUpVideo(in sphere: SCNNode){
        
        ///setting video and playing it
        let videoURL = Bundle.main.url(forResource: "Dolphin", withExtension: "mp4")
        let videoPlayer = AVPlayer(url: videoURL!)
        
        let skScene = SKScene(size: CGSize(width: sceneView.frame.width, height: sceneView.frame.height))
        skScene.scaleMode = .aspectFit
        
        let videoNode = SKVideoNode(avPlayer: videoPlayer)
        videoNode.position = CGPoint(x: skScene.size.width/2, y: skScene.size.height/2)
        videoNode.yScale = -1
        videoNode.size = skScene.size
        skScene.addChild(videoNode)
        videoNode.play()
        
        ///setting as material
        sphere.geometry?.firstMaterial?.diffuse.contents = skScene

    }
    
    //MARK: - Setting up Portals
    func setUpPortals(){
        var portalIn = [SCNNode]()
        var portalOut = [SCNNode]()
        var duplPortalIn = [SCNNode]()
        var duplPortalOut = [SCNNode]()

        //take every portal from both scenes
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
            
            duplNodeIn.isHidden = true
            duplNodeOut.isHidden = true
        }
        
        //Instanciate all the portals with the portal class and set them up.
        for i in 0..<roomCount{
            let nextI = i == roomCount - 1 ? 0 : i + 1
            let lastI = i == 0 ? roomCount - 1 : i - 1
            let portalInSet = Portal(with: portalIn[i], and: duplPortalOut[lastI], type: .In)
            let portalOutSet = Portal(with: portalOut[i], and: duplPortalIn[nextI], type: .Out)
            portalsIn.append(portalInSet)
            portalsOut.append(portalOutSet)
            scene.rootNode.addChildNode(portalInSet)
            scene.rootNode.addChildNode(portalOutSet)
            portalInSet.setUpPortal(scene: duplicateScene)
            portalOutSet.setUpPortal(scene: duplicateScene)
        }
    }
    
    // MARK: - Camera Movement
    func move(){
        ///movement
        let i = initialCamPos
        let r = relativeCamPos
        let a = arCam.position
        let distance = SCNVector3(a.x - r.x, a.y - r.y, a.z - r.z)
        mainCam.position = SCNVector3(i.x + distance.x, i.y + distance.y, i.z + distance.z)
        
        ///Get Portal's visuals to uptade depending on the movement
        portalsIn[currRoomIndex].updateCameraView(relativeTo: mainCam)
        portalsOut[currRoomIndex].updateCameraView(relativeTo: mainCam)
    }
    
    func teleport(to portal: Portal){
        let offSet = portal.offSet(player: mainCam)
        initialCamPos = portal.target.position
        initialCamPos.x += offSet.x
        initialCamPos.y += offSet.y
        initialCamPos.z += offSet.z + (offSet.z > 0 ? -0.2 : 0.2)
        relativeCamPos = arCam.position
        mainCam.position = initialCamPos
        
        ///treatment to CurrRoomIndex to make the rooms loop. If you are in the first room and want to go back this code will allow you to go to the latest room
        if portal.type == .In{
            currRoomIndex = lastIndex
        }
        if portal.type == .Out{
            currRoomIndex = nextIndex
        }
    }
    
}

// MARK: - Update, worldtracking and orientation
extension ViewController: ARSCNViewDelegate{
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
        
        motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { (data, error) in
            if let myData = data{
                self.mainCam.orientation = myData.gaze(atOrientation: .portrait)
            }
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    //MARK:- Update
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        move()
    }
    
}

// MARK: - Physics Handling
extension ViewController: SCNPhysicsContactDelegate{
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
            ///Check if one of the objects coliding is a portal and than telleport the player to it
            if let portal = (contact.nodeA as? Portal) {
                teleport(to: portal)
            }
            if let portal = (contact.nodeB as? Portal) {
                teleport(to: portal)
            }
    }
    
    
    
}

//MARK:- Orientation gaze
extension CMDeviceMotion {
    
    func gaze(atOrientation orientation: UIInterfaceOrientation) -> SCNVector4 {
        
        let attitude = self.attitude.quaternion
        let aq = GLKQuaternionMake(Float(attitude.x), Float(attitude.y), Float(attitude.z), Float(attitude.w))
      
        let cq = GLKQuaternionMakeWithAngleAndAxis(-Float.pi / 2, 1, 0, 0)
        let q = GLKQuaternionMultiply(cq, aq)
        
        return SCNVector4(x: q.x, y: q.y, z: q.z, w: q.w)
    }
    
}
