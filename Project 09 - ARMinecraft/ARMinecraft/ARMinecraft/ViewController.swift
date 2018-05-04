//
//  ViewController.swift
//  ARMinecraft
//
//  Created by Marla Na on 25.04.18.
//  Copyright © 2018 Marla Na. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var informationLabel: UILabel!
    @IBOutlet weak var moreInformationLabel: UILabel!
    // Variable to track the last added node in the scene
    var lastNode: SCNNode?
    // Variable to track the latest touchpoint on touchpad
    var lastTouchedPoint = CGPoint.zero
    // Variables to track the beggining and ending of the swipes in order to detect right and left swipe
    var firstPointOnSwipe = CGPoint.zero
    var lastPointOnSwipe = CGPoint.zero
    // Variable to track possible plane nodes
    var planeNode: SCNNode?
    // Variable to track the latest added cube size.
    var oldCubeSize = (0.1, 0.1, 0.1)
    // Variable to iterate through different cube skins
    var materialsCode = 0
    /*
     Variables to make sure the signals from the controller are only executed once. Note: DayDream SDK delivers for one click, 9-10 notifications at once. Mapping: (a,b,c) => a: last signal, b: newest signal, c: first signal of click
     Example : (false,false,true) : not pressed, (false, true, true ) : pressed and first signal received, (false, true, false): pressed but not first signal received (won't be executed).
     */
    var checkingAppButton = (false ,false, true)
    var checkingVolumeUpButton = (false ,false, true)
    var checkingVolumeDownButton = (false ,false, true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.informationLabel.layer.masksToBounds = true
        self.informationLabel.layer.borderWidth = 3
        self.informationLabel.layer.borderColor = UIColor.black.cgColor
        self.informationLabel.layer.cornerRadius = 8
        self.informationLabel.text = "VR Controller NOT connected."
        
        self.moreInformationLabel.layer.masksToBounds = true
        self.moreInformationLabel.layer.borderWidth = 3
        self.moreInformationLabel.layer.borderColor = UIColor.black.cgColor
        self.moreInformationLabel.layer.cornerRadius = 8
        self.moreInformationLabel.isHidden = true
        
        discoverControllers()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        self.createCube(changeMaterial: false, nextMaterial: false,multiplier: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Detect planes
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z/2)
        let plane = SCNPlane(width: width, height: height)
        plane.materials.first?.diffuse.contents = UIColor.lightGray
        let planeNode = SCNNode(geometry: plane)
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        node.addChildNode(planeNode)
        self.planeNode = node
    }
}

// MARK: - Shapes

extension ViewController {
    
    // This method creates a cube object and adds it to the scene.
    func createCube(changeMaterial: Bool, nextMaterial: Bool, multiplier: Double) {
        if changeMaterial {
            self.materialsCode += nextMaterial ? +1 : -1
            // Avoid negative codes
            if self.materialsCode < 0 {
                self.materialsCode = 11
            }
        }
        let box = SCNBox(width: CGFloat(self.oldCubeSize.0 + multiplier), height: CGFloat(self.oldCubeSize.1 + multiplier), length: CGFloat(self.oldCubeSize.2 + multiplier), chamferRadius: 0.0)
        let boxNode = SCNNode(geometry: box)
        boxNode.position = SCNVector3Make(0, 0, -0.6)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "\(self.materialsCode%14)")
        box.materials = [material]
        self.sceneView.scene.rootNode.addChildNode(boxNode)
        self.lastNode = boxNode
    }
}

// MARK: - Daydream Controller

extension ViewController {
    
    func discoverControllers() {
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.controllerDidConnect(_:)), name: NSNotification.Name.DDControllerDidConnect, object: nil)
        do {
            try DDController.startDaydreamControllerDiscovery()
        } catch DDControllerError.bluetoothOff {
            print("Bluetooth is off.")
        } catch _ {}
    }
    
    func configureNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.controllerDidConnect(_:)), name: NSNotification.Name.DDControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.controllerDidDisconnect(_:)), name: NSNotification.Name.DDControllerDidDisconnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.controllerDidUpdateBatteryLevel(_:)), name: NSNotification.Name.DDControllerDidUpdateBatteryLevel, object: nil)
    }
    
    @objc func controllerDidConnect(_ notification: Notification) {
        print("VR Controller was connected successfully.")
        self.informationLabel.isHidden = false
        self.informationLabel.text = "VR Controller SUCCESSFULLY connected."
        self.moreInformationLabel.text = "Focus the centre of the screen when placing a box."
        configureNotifications()
        
        guard let controller = notification.object as? DDController else { return }
        
        // Detect right and left swipes
        controller.touchpad.pointChangedHandler = { (touchpad: DDControllerTouchpad, point: CGPoint) in
            if !self.lastTouchedPoint.equalTo(CGPoint.zero) && self.firstPointOnSwipe.equalTo(CGPoint.zero) {
                self.firstPointOnSwipe = point
            }
            if self.lastPointOnSwipe.equalTo(CGPoint.zero) && point.equalTo(CGPoint.zero) {
                self.lastPointOnSwipe = self.lastTouchedPoint
                if (self.firstPointOnSwipe.x<150.0) && (self.lastPointOnSwipe.x>180){
                    //Swipe to the right
                    print("User swiped to the right!")
                    self.lastNode?.removeFromParentNode()
                    self.createCube(changeMaterial: true, nextMaterial: true ,multiplier: 0)
                }
                if (self.firstPointOnSwipe.x>100.0) && (self.lastPointOnSwipe.x<75){
                    //Swipe to the left
                    print("User swiped to the left!")
                    self.lastNode?.removeFromParentNode()
                    self.createCube(changeMaterial: true, nextMaterial: false, multiplier: 0)
                }
            }
            // reset if the swipe finished
            if (point.equalTo(CGPoint.zero)){
                self.lastPointOnSwipe = CGPoint.zero
                self.firstPointOnSwipe = CGPoint.zero
            }
            self.lastTouchedPoint = point
        }
        
        controller.touchpad.button.valueChangedHandler = { (button: DDControllerButton, pressed: Bool) in
            if pressed {
                print("Touchpad was pressed")
            }
        }
        
        controller.appButton.valueChangedHandler = { (button: DDControllerButton, pressed: Bool) in
            // Take care of multiple signals sent for one click
            self.checkingAppButton = ( self.checkingAppButton.1 ,pressed ? true : false, self.checkingAppButton.2)
            if self.checkingAppButton.1 {
                if self.checkingAppButton.2 {
                    self.lastNode?.removeFromParentNode()
                    self.createCube(changeMaterial: false, nextMaterial: false, multiplier: 0.0)
                    //Use the middle of the screen for hitTest
                    let point = CGPoint(x: self.sceneView.frame.size.width / 2, y: self.sceneView.frame.size.height / 2);
                    let hitResults = self.sceneView.hitTest(point, types: .existingPlaneUsingExtent)
                    if hitResults.count > 0, let firstHit = hitResults.first {
                        self.lastNode?.position = SCNVector3Make(firstHit.worldTransform.columns.3.x, firstHit.worldTransform.columns.3.y + Float(self.oldCubeSize.1/2), firstHit.worldTransform.columns.3.z)
                        self.planeNode?.removeFromParentNode()
                        self.oldCubeSize = (0.1,0.1,0.1)
                        self.createCube(changeMaterial: false, nextMaterial: false, multiplier: 0)
                    }
                }
            }
            else  if (!self.checkingAppButton.0 && !self.checkingAppButton.1) {
                self.checkingAppButton.2 = true
            }
        }
        
        controller.homeButton.valueChangedHandler = { (button: DDControllerButton, pressed: Bool) in
            if pressed {
                print("Home button was pressed")
            }
        }
        
        controller.volumeUpButton.valueChangedHandler = { (button: DDControllerButton, pressed: Bool) in
            // Take care of multiple signals sent for one click
            self.checkingVolumeUpButton = ( self.checkingVolumeUpButton.1 ,pressed ? true : false, self.checkingVolumeUpButton.2)
            if self.checkingVolumeUpButton.1 {
                //Only interact with the object, if it's in the field of view.
                if let pointOfView = self.sceneView.pointOfView {
                    let isVisible = self.sceneView.isNode(self.lastNode!, insideFrustumOf: pointOfView)
                    if isVisible {
                        if self.checkingVolumeUpButton.2 {
                            self.lastNode?.removeFromParentNode()
                            self.createCube(changeMaterial: false, nextMaterial: false,multiplier: 0.1)
                            self.oldCubeSize = (self.oldCubeSize.0 + 0.1, self.oldCubeSize.1 + 0.1, self.oldCubeSize.2 + 0.1)
                            self.checkingVolumeUpButton.2 = false
                        }
                    }
                }
            }
            else  if (!self.checkingVolumeUpButton.0 && !self.checkingVolumeUpButton.1) {
                self.checkingVolumeUpButton.2 = true
            }
        }
        
        controller.volumeDownButton.valueChangedHandler = { (button: DDControllerButton, pressed: Bool) in
            // Take care of multiple signals sent for one click
            self.checkingVolumeDownButton = ( self.checkingVolumeDownButton.1 ,pressed ? true : false, self.checkingVolumeDownButton.2)
            if self.checkingVolumeDownButton.1 {
                //Only interact with the object, if it's in the field of view.
                if let pointOfView = self.sceneView.pointOfView {
                    let isVisible = self.sceneView.isNode(self.lastNode!, insideFrustumOf: pointOfView)
                    if isVisible {
                        if self.checkingVolumeDownButton.2 {
                            self.lastNode?.removeFromParentNode()
                            self.createCube(changeMaterial: false, nextMaterial: false,multiplier: (-0.1))
                            self.oldCubeSize = (self.oldCubeSize.0 - 0.1, self.oldCubeSize.1 - 0.1, self.oldCubeSize.2 - 0.1)
                            self.checkingVolumeDownButton.2 = false
                        }
                    }
                }
            }
            else if (!self.checkingVolumeDownButton.0 && !self.checkingVolumeDownButton.1) {
                self.checkingVolumeDownButton.2 = true
            }
        }
    }
    
    @objc func controllerDidDisconnect(_ notification: Notification) {
        print("Controller disconnected...")
    }
    
    @objc func controllerDidUpdateBatteryLevel(_ notification: Notification) {
        guard let controller = notification.object as? DDController else { return }
        guard let battery = controller.batteryLevel else { return }
        print("Controller battery life is \(Int(battery * 100))%")
    }
}
