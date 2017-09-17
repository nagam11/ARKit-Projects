//
//  ViewController.swift
//  ARFlatNews
//
//  Created by Marla Na on 17.09.17.
//  Copyright © 2017 Marla Na. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import SpriteKit

class ViewController: UIViewController, ARSCNViewDelegate,SCNSceneRendererDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var boxNode = SCNNode()
    var name: String = ""
    var surname: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //get some API data
        self.getNames()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        //create a transparent gray layer
        let box = SCNBox(width: 0.2, height: 0.2, length: 0.005, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.gray
        box.materials = [material]
        boxNode = SCNNode(geometry: box)
        boxNode.opacity = 0.1
        boxNode.position = SCNVector3(0,0,-0.5)
        scene.rootNode.addChildNode(boxNode)
       
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.delegate = self
        // Put text overlay
        sceneView.overlaySKScene = InformationOverlayScene(size: sceneView.frame.size)
        sceneView.overlaySKScene?.isHidden = false
        self.sceneView.overlaySKScene?.scaleMode = .resizeFill
        self.sceneView.overlaySKScene?.isUserInteractionEnabled = true
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    func getNames(){
        let todoEndpoint = "https://uinames.com/api/?gender=female"
        guard let url = URL(string: todoEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        let urlRequest = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) in
            guard error == nil else {
                print("error calling GET")
                print(error!)
                return
            }
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            do {
                guard let todo = try JSONSerialization.jsonObject(with: responseData, options: [])
                    as? [String: Any] else {
                        print("error trying to convert data to JSON")
                        return
                }

                print("The person is: " + todo.description)
                
                guard let name = todo["name"] as? String else {
                    print("Could not get name from JSON")
                    return
                }
                guard let surname = todo["surname"] as? String else {
                    print("Could not get todo surname from JSON")
                    return
                }
                print("The name is: " + name)
                self.name = name
                self.surname = surname
            } catch  {
                print("error trying to convert data to JSON")
                return
            }
        }
        task.resume()
    }
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval)  {
        if let overlay = sceneView.overlaySKScene as? InformationOverlayScene {
                let boxWorldCoordinates = sceneView.scene.rootNode.convertPosition(boxNode.position, from: boxNode.parent)
                let screenCoordinates = self.sceneView.projectPoint(boxWorldCoordinates)
                overlay.labelNode?.text = self.name + " " + self.surname  + "⛈"
                //TODO text wrapping
                let boxY = overlay.size.height - CGFloat(screenCoordinates.y)
                overlay.cursorNode?.position.x = CGFloat(screenCoordinates.x)
                overlay.cursorNode?.position.y = boxY
                overlay.labelNode?.position.x = CGFloat(screenCoordinates.x)
                overlay.labelNode?.position.y = boxY + 50
        }
    }
}
