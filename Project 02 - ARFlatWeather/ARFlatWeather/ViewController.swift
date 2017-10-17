//
//  ViewController.swift
//  ARFlatWeather
//
//  Created by Marla Na on 17.09.17.
//  Copyright © 2017 Marla Na. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate,SCNSceneRendererDelegate, ARSessionDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var tempToday = ""
    var tempTomorrow = ""
    var tempAfterTomorrow = ""
    var tempAfterAfterTomorrow = ""
    var boxNode = SCNNode()
    var scene =  SCNScene()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //get some Weather data
        self.getWeather()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        //create a transparent gray layer
        let box = SCNBox(width: 0.3, height: 0.3, length: 0.005, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "cloudy.png")
        box.materials = [material]
        boxNode = SCNNode(geometry: box)
        boxNode.opacity = 0.3
        //TODO: set via HitTest
        boxNode.position = SCNVector3(0,0,-0.5)
        scene.rootNode.addChildNode(boxNode)
        
        //Create main node for today.
        self.createTextNode(title: "Munich", size: 2.9, x: 5, y: -5)
        let primarySun = self.createImageNode(width: 7, height: 7, x: 10, y: -6, imageName: "sun.png")
        let action = SCNAction.repeatForever(SCNAction.rotate(by: .pi, around: SCNVector3(0, 0, 1), duration: 5))
        primarySun.runAction(action)
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.delegate = self
        
        // Tap Gesture Recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognize:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    /* This method creates only Text Nodes.
     */
    func createTextNode(title: String, size: CGFloat, x: Float, y: Float){
        let text = SCNText(string: title, extrusionDepth: 0)
        text.firstMaterial?.diffuse.contents = UIColor.white
        text.font = UIFont(name: "Avenir Next", size: size)
        let textNode = SCNNode(geometry: text)
        textNode.position.x = boxNode.position.x - x
        textNode.position.y = boxNode.position.y - y
        textNode.position.z = boxNode.position.z - 50
        scene.rootNode.addChildNode(textNode)
    }
    /* This method creates only Image Nodes.
     */
    func createImageNode(width: CGFloat, height: CGFloat, x: Float, y: Float, imageName: String)-> SCNNode{
        let imageNode = SCNNode()
        imageNode.geometry = SCNPlane.init(width: width, height: height)
        imageNode.geometry?.firstMaterial?.diffuse.contents = imageName
        imageNode.position.x = boxNode.position.x - x
        imageNode.position.y = boxNode.position.y - y
        imageNode.position.z = boxNode.position.z - 50
        scene.rootNode.addChildNode(imageNode)
        return imageNode
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
    }
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        print("Frame Updated")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    /* Get weather data from Open Weather API. Insert own API-TOKEN.
     */
    func getWeather(){
        let openWeatherEndpoint = "https://api.openweathermap.org/data/2.5/forecast?q=M%C3%BCnchen,DE&units=metric&appid=API-TOKEN"
        
        guard let url = URL(string: openWeatherEndpoint) else {
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
                guard let data = try JSONSerialization.jsonObject(with: responseData, options: [])
                    as? [String: Any] else {
                        print("error trying to convert data to JSON")
                        return
                }
                guard let weatherList = data["list"] as? [[String: Any]] else {
                    print("Could not get weatherList from JSON")
                    return
                }
                //Get the weather for today and for the next 3 days
                for i in 0...3 {
                    if let main = weatherList[i]["main"] as? [String: Any] {
                        if var temp = main["temp"] as? Double{
                            temp.round()
                            switch i {
                            case 0: self.tempToday = String(temp)
                            case 1: self.tempTomorrow = String(temp)
                            case 2: self.tempAfterTomorrow = String(temp)
                            default: self.tempAfterAfterTomorrow = String(temp)
                            }
                            print(temp)
                        }
                    }
                }
                self.setTemp()
            } catch  {
                print("error trying to convert data to JSON")
                return
            }
        }
        task.resume()
    }
    //Text-to-speech
    func speakOut(text: String){
        let speech = AVSpeechUtterance(string: text)
        speech.voice = AVSpeechSynthesisVoice(language: "en-US")
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(speech)
    }
    //On tap, speak and add a new node.
    @objc func handleTap(gestureRecognize :UITapGestureRecognizer) {
        let sceneView = gestureRecognize.view as! ARSCNView
        let touchLocation = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(touchLocation, options: [:])
        if !hitResults.isEmpty {
            self.speakOut(text: "This is the weather for Munich. Today is \(self.tempToday)°C")
            self.createTextNode(title: "Thank you!", size: 2.3, x: 12, y: 13)
        }
    }
    /* This method sets the weather for today and the next three days.
     */
    func setTemp(){
        //TODO: replace dummies
        self.createTextNode(title: "\(self.tempToday)°C", size: 2.6, x: 5, y: -2)
        self.createTextNode(title: "Mon", size: 2.3, x: 13, y: 2)
        self.createImageNode(width: 3, height: 3, x: 10.5, y: 4, imageName: "cloud.png")
        self.createTextNode(title: "\(self.tempTomorrow)°C", size: 1.8, x: 13, y: 9)
        self.createTextNode(title: "Tue", size: 2.3, x: 6, y: 2)
        self.createImageNode(width: 3, height: 3, x: 3, y: 4, imageName: "rain.png")
        self.createTextNode(title: "\(self.tempAfterTomorrow)°C", size: 1.8, x: 6, y: 9)
        self.createTextNode(title: "Wed", size: 2.3, x: -1, y: 2)
        self.createImageNode(width: 3, height: 3, x:-3, y: 4, imageName: "sun.png")
        self.createTextNode(title: "\(self.tempAfterAfterTomorrow)°C", size: 1.8, x: -1, y: 9)
    }
}
