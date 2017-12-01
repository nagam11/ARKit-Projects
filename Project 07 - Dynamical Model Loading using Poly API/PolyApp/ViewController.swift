//
//  ViewController.swift
//  PolyApp
//
//  Created by Marla Narazani on 01.12.17.
//  Copyright © 2017 Marla Na. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import ModelIO
import SceneKit.ModelIO

// IMPORTANT: replace this with your project's API key.
let POLY_API_KEY = "AIzaSyA3eh2QYmYvGZg-kfcPwZ64nVbb8zBtI14"
let POLY_BASE_GET_ASSET_URL = "https://poly.googleapis.com/v1/assets"
var POLY_ASSET_ID = "5vbJ5vildOq"

class ViewController: UIViewController, ARSCNViewDelegate, URLSessionDownloadDelegate {
    

    @IBOutlet var sceneView: ARSCNView!
    var fileURLsToDownload: NSMutableArray = []
    var objPathURL: NSURL?
    var mtlPathURL: NSURL?
    var totalFilesDownloaded: Int = 0
    var node: SCNNode?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Provide some nice defaults to the scene.
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.automaticallyUpdatesLighting = true
        self.totalFilesDownloaded = 0
        self.getObjectFromPoly()
        self.downloadFiles()
        
        // Tap Gesture Recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognize:)))
        sceneView.addGestureRecognizer(tapGesture)
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
    
    func getObjectFromPoly(){
        
        self.fileURLsToDownload = NSMutableArray()
        let polyURLWithKey = NSString.init(format: "%@/%@?key=%@",POLY_BASE_GET_ASSET_URL, POLY_ASSET_ID , POLY_API_KEY )
        
        let polyURL = NSURL.init(string: polyURLWithKey as String)
        //let error: NSError
        let data = NSData.init(contentsOf: polyURL! as URL)
        var json: NSDictionary
        do{
            json = try JSONSerialization.jsonObject(with: data as! Data, options: .init(rawValue: 0)) as! NSDictionary
            let formats = json.value(forKey: "formats") as! NSArray
            let format = formats.object(at: 0) as! NSDictionary
            let root = format.value(forKey: "root") as! NSDictionary
            let resources = format.value(forKey: "resources") as! NSArray
            let resource = resources.object(at: 0) as! NSDictionary
            
            self.fileURLsToDownload.add(root.value(forKey: "url"))
            self.fileURLsToDownload.add(resource.value(forKey: "url"))
        } catch {}
    }
    
    func downloadFiles(){
        let configuration = URLSessionConfiguration.default
        let session = URLSession.init(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        for fileURL in self.fileURLsToDownload {
            let url = NSURL.init(string: fileURL as! String) as! URL
            let downloadTask = session.downloadTask(with: url)
            downloadTask.resume()
        }
        
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
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
      
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let URL = downloadTask.originalRequest?.url?.lastPathComponent
      
        let finalPath = documentsPath.appendingPathComponent(URL!)
        let fileManager = FileManager.default
        
        let success: Bool
        let error :  NSError
        
       if (fileManager.fileExists(atPath: finalPath)){
            do{
                try
                fileManager.removeItem(atPath: finalPath)
                let t = fileManager.fileExists(atPath: finalPath)
                
            }catch {}
            
        }
        
        let finalPathURL = NSURL.fileURL(withPath: finalPath)
        do{
             try fileManager.moveItem(at: location, to: finalPathURL)
        }catch{}
        
        self.totalFilesDownloaded += 1
        if finalPathURL.lastPathComponent.contains("obj"){
            self.objPathURL = finalPathURL as NSURL
        }else if finalPathURL.lastPathComponent.contains("mtl"){
            self.mtlPathURL = finalPathURL as NSURL
        }
        
        if (self.totalFilesDownloaded >= 2){
            self.loadObjectToScene()
        }
        
        
    }
    
    func loadObjectToScene(){
        
        let mdlAsset = MDLAsset.init(url: self.objPathURL as! URL)
        mdlAsset.loadTextures()
        
        node = SCNNode.init(mdlObject: mdlAsset.object(at: 0))
        node?.scale = SCNVector3Make(0.15, 0.15, 0.15)
        node?.position = SCNVector3Make(0, -0.2, -0.8)
        
        let rotate = SCNAction.repeatForever(SCNAction.rotate(by: CGFloat(Float.pi), around: SCNVector3Make(0, 1, 1), duration: 3))
        node?.runAction(rotate)
        self.sceneView.scene.rootNode.addChildNode(node!)
    }
    
    //On tap change model
    @objc func handleTap(gestureRecognize :UITapGestureRecognizer) {
        let sceneView = gestureRecognize.view as! ARSCNView
        let touchLocation = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(touchLocation, options: [:])
        if !hitResults.isEmpty {
            POLY_ASSET_ID = "4WkEQfHL-9P"
            self.node?.removeFromParentNode()
            self.getObjectFromPoly()
            self.downloadFiles()
        }
    }
}