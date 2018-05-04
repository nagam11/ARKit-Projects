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
    // Variable to track the last added node in the scene
    var lastNode: SCNNode?
    // Variable to track the last touchpoint on touchpad
    fileprivate var lastPoint = CGPoint.zero
    var firstPoint = CGPoint.zero
    var lastPoi = CGPoint.zero
    // TODO: should be optional
    var planeNode = SCNNode()
    // Variable to track the latest added cube size.
    var oldCubeSize = (0.1,0.1,0.1)
    // Variable to iterate through different cube skins
    var materialsCode = 0
    // 3rd variable : Variable to make sure the signals from the controller are only executed once. Note: DayDream SDK delivers for one click, 9-10 notifications at once.
    // Variable to check two consecutive signals from the SDK. (false,false) : not pressed, (false, true) : pressed, (true, true) : not defined, (true, false) : not needed because we only execute once.
    var checking0 = (false ,false, true)
    var checking = (false ,false, true)
    var checking2 = (false ,false, true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        discoverControllers()
        
        self.informationLabel.text = "VR Controller NOT connected."
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        self.createCube(changeMaterial: false, multiplier: 0)
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
    
    // This method creates a cube object and adds it to the scene
    func createCube(changeMaterial: Bool, multiplier: Double) {
        if changeMaterial {
            self.materialsCode += 1
        }
        let box = SCNBox(width: CGFloat(self.oldCubeSize.0 + multiplier), height: CGFloat(self.oldCubeSize.1 + multiplier), length: CGFloat(self.oldCubeSize.2 + multiplier), chamferRadius: 0.0)
        let boxNode = SCNNode(geometry: box)
        boxNode.position = SCNVector3Make(0, 0, -0.6)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "\(self.materialsCode%6)")
        box.materials = [material]
        self.sceneView.scene.rootNode.addChildNode(boxNode)
        self.lastNode = boxNode
    }
}

// MARK: - Daydream Controller

extension ViewController {
    
    func discoverControllers() {
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.controllerDidConnect(_:)), name: NSNotification.Name.DDControllerDidConnect, object: nil)
        print("added observer for controller")
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
        self.informationLabel.text = "VR Controller SUCCESSFULLY connected."
        //DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
         //   self.informationLabel.text = "Focus on the centre of the screen when placing a box."
       // })
        configureNotifications()
        
        guard let controller = notification.object as? DDController else { return }
        
        // TODO
        let touchpadMaxPoint: CGFloat = 250.0
        
        controller.touchpad.pointChangedHandler = { (touchpad: DDControllerTouchpad, point: CGPoint) in
            if !self.lastPoint.equalTo(CGPoint.zero) && self.firstPoint.equalTo(CGPoint.zero) {
                self.firstPoint = point
            }
            print(self.lastPoi)
            print(point)
            if self.lastPoi.equalTo(CGPoint.zero) && point.equalTo(CGPoint.zero) {
                self.lastPoi = self.lastPoint
                // Swipe detection
                print(self.firstPoint.x)
                print(self.lastPoi.x)
                if (self.firstPoint.x<127.0) && (self.lastPoi.x>180){
                    //Swiped to the right
                    print("User swiped to the right!")
                    self.lastNode?.removeFromParentNode()
                    self.createCube(changeMaterial: true, multiplier: 0)
                }
            }
            if (point.equalTo(CGPoint.zero)){
                self.lastPoi = CGPoint.zero
                self.firstPoint = CGPoint.zero
            }
            self.lastPoint = point
           // print(self.lastPoint)
            
        }
        
        controller.touchpad.button.valueChangedHandler = { (button: DDControllerButton, pressed: Bool) in
            if pressed {
                //print("Touchpad was pressed")
            }
        }
        
        controller.appButton.valueChangedHandler = { (button: DDControllerButton, pressed: Bool) in
            self.checking0 = ( self.checking0.1 ,pressed ? true : false, self.checking0.2)
            if self.checking0.1 {
                //Only interact with the object, if it's in the field of view.
              //  if let pointOfView = self.sceneView.pointOfView {
                  //  let isVisible = self.sceneView.isNode(self.lastNode!, insideFrustumOf: pointOfView)
                //    if isVisible {
                        if self.checking0.2 {
                            //TODO: Either delete of move
                            self.lastNode?.removeFromParentNode()
                            self.createCube(changeMaterial: false, multiplier: 0.0)
                            //Use the middle of the screen for hitTest
                            let point = CGPoint(x: self.sceneView.frame.size.width / 2, y: self.sceneView.frame.size.height / 2);
                            let hitResults = self.sceneView.hitTest(point, types: .existingPlaneUsingExtent)
                            
                            if hitResults.count > 0, let firstHit = hitResults.first {
                                self.lastNode?.position = SCNVector3Make(firstHit.worldTransform.columns.3.x, firstHit.worldTransform.columns.3.y + Float(self.oldCubeSize.1/2), firstHit.worldTransform.columns.3.z)
                                //Remove the plane node after an object has been placed on it.
                                //DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                                self.planeNode.removeFromParentNode()
                                self.oldCubeSize = (0.1,0.1,0.1 )
                                self.createCube(changeMaterial: false, multiplier: 0)
                              //  })
                            }
                        }
                //    }
               // }
            }
            else  if (!self.checking0.0 && !self.checking0.1) {
                self.checking0.2 = true
            }
        }
        
        controller.homeButton.valueChangedHandler = { (button: DDControllerButton, pressed: Bool) in
            if pressed {
                print("Home button was pressed")
            }
        }
        
        controller.volumeUpButton.valueChangedHandler = { (button: DDControllerButton, pressed: Bool) in
            self.checking = ( self.checking.1 ,pressed ? true : false, self.checking.2)
            if self.checking.1 {
                //Only interact with the object, if it's in the field of view.
                if let pointOfView = self.sceneView.pointOfView {
                    let isVisible = self.sceneView.isNode(self.lastNode!, insideFrustumOf: pointOfView)
                    if isVisible {
                        if self.checking.2 {
                            self.lastNode?.removeFromParentNode()
                            self.createCube(changeMaterial: false, multiplier: 0.1)
                            self.oldCubeSize = (self.oldCubeSize.0 + 0.1, self.oldCubeSize.1 + 0.1, self.oldCubeSize.2 + 0.1)
                            self.checking.2 = false
                        }
                    }
                }
            }
            else  if (!self.checking.0 && !self.checking.1) {
                self.checking.2 = true
            }
        }
        
        controller.volumeDownButton.valueChangedHandler = { (button: DDControllerButton, pressed: Bool) in
            self.checking2 = ( self.checking2.1 ,pressed ? true : false, self.checking2.2)
            if self.checking2.1 {
                //Only interact with the object, if it's in the field of view.
                if let pointOfView = self.sceneView.pointOfView {
                    let isVisible = self.sceneView.isNode(self.lastNode!, insideFrustumOf: pointOfView)
                    if isVisible {
                        if self.checking2.2 {
                            self.lastNode?.removeFromParentNode()
                            self.createCube(changeMaterial: false, multiplier: (-0.1))
                            self.oldCubeSize = (self.oldCubeSize.0 - 0.1, self.oldCubeSize.1 - 0.1, self.oldCubeSize.2 - 0.1)
                            self.checking2.2 = false
                        }
                    }
                }
            }
            else if (!self.checking2.0 && !self.checking2.1) {
                self.checking2.2 = true
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
