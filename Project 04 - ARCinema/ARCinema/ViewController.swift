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
    var cinemaFrame: ARFrame?
    //Reference to currently playing video node
    var videoNode = SKVideoNode()
    var nextVideo = "0.mov"
    var counter = 0
    
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
    
    func addVideoNode(toBePlayed: String) {
        let videoNode = SKVideoNode(fileNamed: toBePlayed)
        videoNode.size = CGSize(width: 200, height: 100)
        videoNode.alpha = 0.8
        videoNode.play()
        self.videoNode = videoNode
    }
    
    // MARK: - ARSKViewDelegate
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        if (!self.cinemaLoaded) {
            self.addVideoNode(toBePlayed: self.nextVideo)
            //create playback options
            let play = SKSpriteNode(imageNamed: "play.png")
            let pause = SKSpriteNode(imageNamed: "pause.png")
            let next = SKSpriteNode(imageNamed: "next.png")
            //set identifiers for the nodes
            pause.name = "pause"
            play.name = "play"
            next.name = "next"
            
            //position is relative to parent node/video node
            play.position = CGPoint(x: 0, y: -70)
            pause.position = CGPoint(x: -30, y: -70)
            next.position = CGPoint(x: 30, y: -70)
            videoNode.addChild(play)
            videoNode.addChild(pause)
            videoNode.addChild(next)
            
            self.cinemaLoaded = true
            return videoNode
        }
        return nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(!self.cinemaLoaded){
            self.createCinemaAnchor()
        }
        // Get first touch
        guard let touch = touches.first else {
            return
        }
        // Get location in the scene
        let location = touch.location(in: self.sceneView.scene!)
        
        // Get the nodes at the clicked location
        let clicked = self.sceneView.scene!.nodes(at: location)
        
        // Get the first clicked node
        if let node = clicked.first {
            if let name = node.name {
                if (name == "pause") {
                    videoNode.pause()
                    self.scaleButton(node: node, completion: {(_ param: String) -> Void in})
                }
                if (name == "play") {
                    videoNode.play()
                    self.scaleButton(node: node, completion: {(_ param: String) -> Void in})
                }
                if (name == "next"){
                    self.scaleButton(node: node){ (param: String) in
                        print("\(param)")
                        self.videoNode.pause()
                        self.videoNode.removeFromParent()
                        self.createCinemaAnchor()
                        self.cinemaLoaded = false
                        self.counter += 1
                        //simple iteration through 5 videos. We should be using an array or list actually.
                        self.nextVideo = "\(self.counter%5)"+".mov"
                    }
                }
            }
        } else {
            return
        }
    }

    func scaleButton(node: SKNode, completion: @escaping (_ param: String) -> Void){
        let scaleOut = SKAction.scale(by: 0.8, duration: 0.2)
        let scaleIn = SKAction.scale(by: 1.25, duration: 0.2)
        let sequence = SKAction.sequence([scaleOut,scaleIn])
        node.run(sequence){
            completion("animation finished")
        }
    }
    func createCinemaAnchor(){
        // Create anchor using the camera's current position
        if let currentFrame = sceneView.session.currentFrame {
            //always use the first current frame
            if(!cinemaLoaded){
                self.cinemaFrame = currentFrame
            }
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -0.7
            let transform = simd_mul((cinemaFrame?.camera.transform)!, translation)
            
            // Add a new anchor to the session
            let anchor = ARAnchor(transform: transform)
            sceneView.session.add(anchor: anchor)
        }
    }
}
