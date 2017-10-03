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
import SpriteKit
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate,SCNSceneRendererDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var boxNode = SCNNode()
    var name: String = ""
    var surname: String = ""
    var weatherDescription = ""
    var scene =  SCNScene()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //get some Weather data
        //TODO: call openWeather
        // self.getWeather()
        
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
       
        self.createTextNode(title: "Munich", size: 2.9, x: 5, y: -5)
        let primarySun = self.createImageNode(width: 7, height: 7, x: 10, y: -6, imageName: "sun.png")
        let action = SCNAction.repeatForever(SCNAction.rotate(by: .pi, around: SCNVector3(0, 0, 1), duration: 5))
        primarySun.runAction(action)
        //TODO: replace dummies
        self.createTextNode(title: "17°C", size: 2.6, x: 5, y: -2)
        self.createTextNode(title: "Mon", size: 2.3, x: 13, y: 2)
        self.createImageNode(width: 3, height: 3, x: 10.5, y: 4, imageName: "cloud.png")
        self.createTextNode(title: "10°C", size: 1.8, x: 13, y: 9)
        self.createTextNode(title: "Tue", size: 2.3, x: 5, y: 2)
        self.createImageNode(width: 3, height: 3, x: 3, y: 4, imageName: "rain.png")
        self.createTextNode(title: "8°C", size: 1.8, x: 5, y: 9)
        self.createTextNode(title: "Wed", size: 2.3, x: -1, y: 2)
        self.createImageNode(width: 3, height: 3, x:-3, y: 4, imageName: "sun.png")
        self.createTextNode(title: "15°C", size: 1.8, x: -1, y: 9)
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.delegate = self
        
        // Tap Gesture Recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognize:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    func createTextNode(title: String, size: CGFloat, x: Float, y: Float){
        let text = SCNText(string: title, extrusionDepth: 0)
        text.firstMaterial?.diffuse.contents = UIColor.white
        //text.font = UIFont.systemFont(ofSize: size)
        text.font = UIFont(name: "Avenir Next", size: size)
        let textNode = SCNNode(geometry: text)
        textNode.position.x = boxNode.position.x - x
        textNode.position.y = boxNode.position.y - y
        textNode.position.z = boxNode.position.z - 50
        scene.rootNode.addChildNode(textNode)
    }
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
    
    //Generate some random user names
    func getNames(){
       // let todoEndpoint = "https://uinames.com/api/?gender=female"
        let todoEndpoint = "https://crossorigin.me/http://samples.openweathermap.org/data/2.5/weather?q=London,uk&appid=b1b15e88fa797225412429c1c50c122a1"
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
    //Get Weather Data for Munich
    func getWeather() {
        if let url = URL(string: "https://www.weather-forecast.com/locations/Paris/forecasts/latest") {

            let request = NSMutableURLRequest(url: url)
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                var message = ""
                
                if let error = error {
                    print(error)
                } else {
                    if let unwrappedData = data {
                        let dataString = NSString(data: unwrappedData, encoding: String.Encoding.utf8.rawValue)
                        
                        var stringSeperator = "Weather Forecast Summary:</b><span class=\"read-more-small\"><span class=\"read-more-content\"> <span class=\"phrase\">"
                        
                        if let contentArray = dataString?.components(separatedBy: stringSeperator) {
                            
                            if contentArray.count > 1 {
                                stringSeperator = "</span>"
                                
                                let newContentArray = contentArray[1].components(separatedBy: stringSeperator)
                                if newContentArray.count > 1 {
                                    message = newContentArray[0].replacingOccurrences(of: "&deg;", with: "°")
                                }
                            }
                        }
                    }
                }
                
                if message == "" {
                    message = "The weather couldn't be found."
                }
                
                DispatchQueue.main.sync(execute: {
                        let text = "The weather in Munich is " + message +  "\n⛈"
                        self.weatherDescription = self.insert(separator: "\n", afterEveryXChars: 25, intoString: text)
                        self.speakOut(text: self.weatherDescription)
                })
            }
            task.resume()
            
        } else {
            print("The weather couldn't be found.")
        }
    }
    //insert delimiter
    func insert(separator: String, afterEveryXChars: Int, intoString: String) -> String {
        var output = ""
        intoString.characters.enumerated().forEach { index, c in
            if index % afterEveryXChars == 0 && index > 0 {
                output += separator
            }
            output.append(c)
        }
        return output
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
            self.speakOut(text: "This is the weather for Munich")
            self.createTextNode(title: "Thank you!", size: 2.3, x: 12, y: 13)
        }
    }
}
