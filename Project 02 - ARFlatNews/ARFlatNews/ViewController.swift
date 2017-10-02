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
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate,SCNSceneRendererDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var boxNode = SCNNode()
    var name: String = ""
    var surname: String = ""
    var weatherDescription = ""
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
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
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
        if let url = URL(string: "https://www.weather-forecast.com/locations/Munich/forecasts/latest") {

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
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval)  {
        if let overlay = sceneView.overlaySKScene as? InformationOverlayScene {
                let boxWorldCoordinates = sceneView.scene.rootNode.convertPosition(boxNode.position, from: boxNode.parent)
                let screenCoordinates = self.sceneView.projectPoint(boxWorldCoordinates)
                overlay.labelNode?.position.x =  CGFloat(screenCoordinates.x) - 70
                let boxYY = overlay.size.height - CGFloat(screenCoordinates.y)
                overlay.labelNode?.position.y =  boxYY + 80
                var lineAt: CGFloat = 0
                let text = self.weatherDescription
                for line in text.components(separatedBy: "\n") {
                    let labelNode = SKLabelNode(fontNamed: "Arial")
                    labelNode.fontSize = 14
                    labelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
                    labelNode.fontColor = SKColor(hue: 1, saturation: 1, brightness: 1, alpha: 1)
                    labelNode.position =  CGPoint.init(x: 0, y: lineAt)
                    labelNode.text = line
                    overlay.labelNode?.addChild(labelNode)
                    lineAt -= 20.0
                }
            
                let boxY = overlay.size.height - CGFloat(screenCoordinates.y)
                overlay.cursorNode?.position.x = CGFloat(screenCoordinates.x)
                overlay.cursorNode?.position.y = boxY
        }
    }
    
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
   
    func speakOut(text: String){
        let speech = AVSpeechUtterance(string: text)
        speech.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(speech)
    }
}
