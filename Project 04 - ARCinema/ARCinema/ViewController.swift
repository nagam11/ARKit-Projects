//
//  ViewController.swift
//  ARCinema
//
//  Created by Marla Na on 27.10.17.
//  Copyright © 2017 Marla Na. All rights reserved.
//

import UIKit
import SpriteKit
import ARKit

class ViewController: UIViewController, ARSKViewDelegate {
    
    @IBOutlet var sceneView: ARSKView!
    private var cinemaLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and node count
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        
        // Load the SKScene from 'Scene.sks'
        if let scene = SKScene(fileNamed: "Scene") {
            sceneView.presentScene(scene)
        }
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
    
    // MARK: - ARSKViewDelegate
    
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        if !self.cinemaLoaded {
            let videoNode = SKVideoNode(fileNamed: "1.mov")
            videoNode.size = CGSize(width: 100, height: 150)
            let play = SKSpriteNode(imageNamed: "play.png")
            let pause = SKSpriteNode(imageNamed: "pause.png")
            let next = SKSpriteNode(imageNamed: "next.png")
            videoNode.alpha = 0.8
            play.position = CGPoint(x: 0, y: -90)
            pause.position = CGPoint(x: -30, y: -90)
            next.position = CGPoint(x: 30, y: -90)
            videoNode.addChild(play)
            videoNode.addChild(pause)
            videoNode.addChild(next)
            videoNode.play()
            self.cinemaLoaded = true
            return videoNode
        }
        return SKNode()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
