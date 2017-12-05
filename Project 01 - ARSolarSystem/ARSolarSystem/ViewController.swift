//
//  ViewController.swift
//  ARSolarSystem
//
//  Created by Marla Na on 16.09.17.
//  Copyright © 2017 Marla Na. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var solarSystem: SCNNode?
    let scene = SCNScene()
    var rotation_speeds = [2, 54,  54, 50, 730] as [CFTimeInterval]
    var fast = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        self.createPlanets(scene: scene, rotation_speeds: self.rotation_speeds)
        
        // Tap Gesture Recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognize:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
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
    
    @objc func handleTap(gestureRecognize :UITapGestureRecognizer) {
        let sceneView = gestureRecognize.view as! ARSCNView
        let touchLocation = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(touchLocation, options: [:])
        if !hitResults.isEmpty {
            self.solarSystem?.removeFromParentNode()
            if(self.fast){
                self.fast = false
                createPlanets(scene: scene, rotation_speeds: self.rotation_speeds.map{ $0 * 27})
            }else {
                self.fast = true
                createPlanets(scene: scene, rotation_speeds: self.rotation_speeds.map{ $0 / 27})
            }
        }
    }
    
    func createPlanets(scene: SCNScene, rotation_speeds: [CFTimeInterval]){
        self.solarSystem = SCNNode()
        // Create the Earth-Moon-System and place it 10cm in front of the screen.
        let earthMoonSystem = SCNNode()
        earthMoonSystem.position = SCNVector3(0,0,-0.7)
        
        // Create the Earth and add it to the system. In this system the moon orbits the Earth, thus Earth's position is 0.0.0 and rotates around its y axis.
        let earthNode = self.createObject(radius: 0.04, materialName: "earth.jpg", position: SCNVector3(0,0,0))
        earthMoonSystem.addChildNode(earthNode)
        // Rotate the Earth around its y axis.
        self.rotateObject(node: earthNode, duration: rotation_speeds[0], from: SCNVector4Make(0, 1, 0, 0), to: SCNVector4Make(0, 1, 0, Float(Double.pi) * 2.0), key: "earth_own_rotation")
        
        // Create the Moon-Rotation-System. In this sub-system of the Earth-Moon-System the moon has an offset of -10cm on the x axis.
        let moonRotationNode = SCNNode()
        let moonNode = self.createObject(radius: 0.01, materialName: "moon.jpg", position: SCNVector3(0,0,-0.1))
        // Rotate the Moon around its y axis.
        self.rotateObject(node: moonNode, duration: rotation_speeds[1], from: SCNVector4Make(0, 1, 0, 0), to: SCNVector4Make(0, 1, 0, Float.pi * 2.0), key: "moon_own_rotation")
        moonRotationNode.addChildNode(moonNode)
        // MRS is a sub-system of EMS.
        earthMoonSystem.addChildNode(moonRotationNode)
        
        // In order to rotate the Moon around the Earth, we rotate the "whole" Moon-Rotation-System/Node around the y axis forever.
        self.rotateObject(node: moonRotationNode, duration: rotation_speeds[2], from: SCNVector4Make(0, 1, 0, 0), to: SCNVector4Make(0, 1, 0, Float(Double.pi) * 2.0), key: "moon_earth_rotation")
        
         // Create the Earth-Sun-System. It will contains the Earth-Moon-System and the Sun itself.
        let earthSunSystem = SCNNode()
        let sunNode = self.createObject(radius: 0.1, materialName: "sun.jpg", position: SCNVector3(0,0,0))
        earthSunSystem.addChildNode(sunNode)
        self.rotateObject(node: sunNode, duration: rotation_speeds[3], from: SCNVector4Make(0, 1, 0, 0), to: SCNVector4Make(0, 1, 0, Float(Double.pi) * 2.0), key: "sun_own_rotation")
        
        // In order to rotate the planet around the Sun, we rotate the "whole" Earth-Moon-System/Node around the y axis forever.
        let earthRotationSystem = SCNNode()
        earthRotationSystem.addChildNode(earthMoonSystem)
        earthSunSystem.addChildNode(earthRotationSystem)
        self.rotateObject(node: earthRotationSystem, duration: rotation_speeds[4], from: SCNVector4Make(0, 1, 0, 0), to: SCNVector4Make(0, 1, 0, Float(Double.pi) * 2.0), key: "earth_sun_rotation")
    
        guard let solarSystem = self.solarSystem else {
            print("Solar System node does not exist !")
            return
        }
        self.solarSystem?.addChildNode(earthSunSystem)
        scene.rootNode.addChildNode(solarSystem)
    }
    // Helper method to create astronomical objects.
    func createObject(radius: CGFloat, materialName: String, position: SCNVector3) -> SCNNode {
        let object = SCNSphere(radius: radius)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: materialName)
        object.materials = [material]
        let node = SCNNode(geometry: object)
        node.position = position
        return node
    }
     // Helper method to rotate objects forever.
    func rotateObject(node: SCNNode, duration: CFTimeInterval, from: SCNVector4, to: SCNVector4, key: String){
        let animation = CABasicAnimation(keyPath: "rotation")
        animation.duration = duration
        animation.fromValue = NSValue(scnVector4: from)
        animation.toValue = NSValue(scnVector4: to)
        animation.repeatCount = Float.greatestFiniteMagnitude
        node.addAnimation(animation, forKey: key)
    }
}
