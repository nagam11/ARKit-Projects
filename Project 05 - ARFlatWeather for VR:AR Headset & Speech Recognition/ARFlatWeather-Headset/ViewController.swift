//
//  ViewController.swift
//  ARFlatWeather-Headset
//
//  Created by Marla Na on 07.11.17.
//  Copyright © 2017 Marla Na. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Speech
import CoreLocation
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var sceneViewLeft: ARSCNView!
    @IBOutlet weak var sceneViewRight: ARSCNView!
    @IBOutlet weak var imageViewLeft: UIImageView!
    @IBOutlet weak var imageViewRight: UIImageView!
    let eyeCamera : SCNCamera = SCNCamera()
    var boxNode = SCNNode()
    var scene =  SCNScene()
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var tempToday = ("","")
    var tempTomorrow = ("","")
    var tempAfterTomorrow = ("","")
    var tempAfterAfterTomorrow = ("","")
    var location = ""
    var didFindLocation = false
    let locationManager = CLLocationManager()
    
    // --- Hanley Weng Headset View Implementation --- //
    // Parametres
    let interpupilaryDistance = 0.066
    let viewBackgroundColor : UIColor = UIColor.white
    // Set eyeFOV and cameraImageScale. Uncomment any of the below lines to change FOV.
    let eyeFOV = 60; let cameraImageScale = 3.478;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.requestAlwaysAuthorization()
        
        self.locationManager.requestWhenInUseAuthorization()
        
        locationManager.requestWhenInUseAuthorization();
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        else{
            print("Location service disabled");
        }
        
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.isHidden = true
        self.view.backgroundColor = viewBackgroundColor
        
        switch SFSpeechRecognizer.authorizationStatus() {
        case .notDetermined:
            askSpeechPermission()
        case .authorized:
            askSpeechPermission()
        case .denied, .restricted:
            askSpeechPermission()
        }
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        // --- Hanley Weng Headset View Implementation --- //
        // Set up Left-Eye SceneView
        sceneViewLeft.scene = self.scene
        sceneViewLeft.showsStatistics = sceneView.showsStatistics
        sceneViewLeft.isPlaying = true
        
        // Set up Right-Eye SceneView
        sceneViewRight.scene = scene
        sceneViewRight.showsStatistics = sceneView.showsStatistics
        sceneViewRight.isPlaying = true
        
        ////////////////////////////////////////////////////////////////
        // Create CAMERA
        eyeCamera.zNear = 0.001
        eyeCamera.fieldOfView = CGFloat(eyeFOV)
        
        ////////////////////////////////////////////////////////////////
        // Setup ImageViews - for rendering Camera Image
        self.imageViewLeft.clipsToBounds = true
        self.imageViewLeft.contentMode = UIViewContentMode.center
        self.imageViewRight.clipsToBounds = true
        self.imageViewRight.contentMode = UIViewContentMode.center
        
        scene.rootNode.addChildNode(boxNode)
        // Start recording upon opening app. Close recording when recognizing 'weather'
        // to avoid 'self' speech recognition from microphone. Start recording again
        // after setting the dashboard in the setTemp func.
        self.startRecording()
    }
    func askSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            OperationQueue.main.addOperation {
                switch status {
                default:
                    print("okay")
                }
            }
        }
    }
    func startRecording() {
        // Setup audio engine and speech recognizer
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        // TODO: bugs: it still listens ! + listen after saying thanks/aka order of recognizing
        let request = SFSpeechAudioBufferRecognitionRequest()
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        // Prepare and start recording
        audioEngine.prepare()
        do {
            try audioEngine.start()
            // self.status = .recognizing
        } catch {
            return print(error)
        }
        
        // Analyze the speech
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                print(result.bestTranscription.formattedString)
                // Only recognize 'thanks' and something related to weather
                if(result.bestTranscription.formattedString.contains("thanks")){
                    // Remove the weather dashboard
                    self.scene.rootNode.enumerateChildNodes({ (node, stop) in
                        node.removeFromParentNode()
                        //self.cancelRecording()
                    })
                } else
                    if(result.bestTranscription.formattedString.contains("weather")){
                        // Avoid self speech recognition.
                        self.cancelRecording()
                        self.setTemp()
                }
            } else if let error = error {
                print(error)
            }
        })
    }
    func cancelRecording() {
        audioEngine.stop()
        let node = audioEngine.inputNode
        node.removeTap(onBus: 0)
        recognitionTask?.cancel()
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
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFrame()
        }
    }
    
    // --- Hanley Weng Headset View Implementation --- //
    func updateFrame() {
        /////////////////////////////////////////////
        // CREATE POINT OF VIEWS
        let pointOfView : SCNNode = SCNNode()
        pointOfView.transform = (sceneView.pointOfView?.transform)!
        pointOfView.scale = (sceneView.pointOfView?.scale)!
        // Create POV from Camera
        pointOfView.camera = eyeCamera
        
        // Set PointOfView for SceneView-LeftEye
        sceneViewLeft.pointOfView = pointOfView
        
        // Clone pointOfView for Right-Eye SceneView
        let pointOfView2 : SCNNode = (sceneViewLeft.pointOfView?.clone())!
        // Determine Adjusted Position for Right Eye
        let orientation : SCNQuaternion = pointOfView.orientation
        let orientationQuaternion : GLKQuaternion = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)
        let eyePos : GLKVector3 = GLKVector3Make(1.0, 0.0, 0.0)
        let rotatedEyePos : GLKVector3 = GLKQuaternionRotateVector3(orientationQuaternion, eyePos)
        let rotatedEyePosSCNV : SCNVector3 = SCNVector3Make(rotatedEyePos.x, rotatedEyePos.y, rotatedEyePos.z)
        let mag : Float = Float(interpupilaryDistance)
        pointOfView2.position.x += rotatedEyePosSCNV.x * mag
        pointOfView2.position.y += rotatedEyePosSCNV.y * mag
        pointOfView2.position.z += rotatedEyePosSCNV.z * mag
        
        // Set PointOfView for SceneView-RightEye
        sceneViewRight.pointOfView = pointOfView2
        
        ////////////////////////////////////////////
        // RENDER CAMERA IMAGE
        // Clear Original Camera-Image
        sceneViewLeft.scene.background.contents = UIColor.clear // This sets a transparent scene bg for all sceneViews - as they're all rendering the same scene.
        
        // Read Camera-Image
        let pixelBuffer : CVPixelBuffer? = sceneView.session.currentFrame?.capturedImage
        if pixelBuffer == nil { return }
        let ciimage = CIImage(cvPixelBuffer: pixelBuffer!)
        // Convert ciimage to cgimage, so uiimage can affect its orientation
        let context = CIContext(options: nil)
        let cgimage = context.createCGImage(ciimage, from: ciimage.extent)
        
        // Determine Camera-Image Scale
        var scale_custom : CGFloat = 1.0
        scale_custom = CGFloat(cameraImageScale)
        
        // Determine Camera-Image Orientation
        let imageOrientation : UIImageOrientation = (UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.landscapeLeft) ? UIImageOrientation.down : UIImageOrientation.up
        
        // Display Camera-Image
        let uiimage = UIImage(cgImage: cgimage!, scale: scale_custom, orientation: imageOrientation)
        self.imageViewLeft.image = uiimage
        self.imageViewRight.image = uiimage
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
        self.sceneView.scene.rootNode.addChildNode(imageNode)
        return imageNode
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
    /* Get weather data from Open Weather API. Insert own API-TOKEN.
     */
    func getWeather(latitude: String, longitude: String){
        let openWeatherEndpoint = "https://api.openweathermap.org/data/2.5/forecast?lat=\(latitude)&lon=\(longitude)&units=metric&appid=API-TOKEN"
        
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
                            case 0: self.tempToday.0 = String(temp)
                            case 1: self.tempTomorrow.0 = String(temp)
                            case 2: self.tempAfterTomorrow.0 = String(temp)
                            default: self.tempAfterAfterTomorrow.0 = String(temp)
                            }
                            print(temp)
                        }
                    }
                    if let weather = weatherList[i]["weather"] as? [Any] {
                        if let object = weather.first as? [String: Any]{
                            if let main = object["main"] as? String {
                                var weatherDescription = main.lowercased()
                                if weatherDescription.contains("clear"){
                                    weatherDescription = "sun"
                                } else if weatherDescription.contains("cloud"){
                                    weatherDescription = "cloud"
                                } else {
                                    weatherDescription = "rain"
                                }
                                switch i {
                                case 0: self.tempToday.1 = String(weatherDescription)
                                case 1: self.tempTomorrow.1 = String(weatherDescription)
                                case 2: self.tempAfterTomorrow.1 = String(weatherDescription)
                                default: self.tempAfterAfterTomorrow.1 = String(weatherDescription)
                                }
                            }
                        }
                    }
                }
                //get current location
                guard let city = data["city"] as? [String: Any] else {
                    print("Could not get city from JSON")
                    return
                }
                if let cityName = city["name"] as? String {
                    self.location = cityName
                }
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
    /* This method sets the weather for today and the next three days.
     */
    func setTemp(){
        //Create main node for today.
        self.createTextNode(title: self.location, size: 2.9, x: 5, y: -5)
        let primaryImage = self.createImageNode(width: 7, height: 7, x: 10, y: -6, imageName: "\(self.tempToday.1).png")
        let action = SCNAction.repeatForever(SCNAction.rotate(by: .pi, around: SCNVector3(0, 0, 1), duration: 5))
        if self.tempToday.1.contains("sun"){
            primaryImage.runAction(action)
        }
        let weekdays = self.getWeekday()
        self.createTextNode(title: "\(self.tempToday.0)°C", size: 2.6, x: 5, y: -2)
        self.createTextNode(title: weekdays.0, size: 2.3, x: 13, y: 2)
        self.createImageNode(width: 3, height: 3, x: 10.5, y: 4, imageName: "\(self.tempTomorrow.1).png")
        self.createTextNode(title: "\(self.tempTomorrow.0)°C", size: 1.8, x: 13, y: 9)
        self.createTextNode(title: weekdays.1, size: 2.3, x: 6, y: 2)
        self.createImageNode(width: 3, height: 3, x: 3, y: 4, imageName: "\(self.tempAfterTomorrow.1).png")
        self.createTextNode(title: "\(self.tempAfterTomorrow.0)°C", size: 1.8, x: 6, y: 9)
        self.createTextNode(title: weekdays.2, size: 2.3, x: -1, y: 2)
        self.createImageNode(width: 3, height: 3, x:-3, y: 4, imageName: "\(self.tempAfterAfterTomorrow.1).png")
        self.createTextNode(title: "\(self.tempAfterAfterTomorrow.0)°C", size: 1.8, x: -1, y: 9)
        self.speakOut(text: "This is the forecast for \(self.location) today and for the next 3 days. Today is \(self.tempToday.0)°C")
        self.startRecording()
    }
    /* This method returns the current weekday.
     */
    func getWeekday() -> (String,String,String){
        let tomorrow = Date().tomorrow
        let afterTomorrow = Date().afterTomorrow
        let afterAfterTomorrow = Date().afterAfterTomorrow
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        dateFormatter.dateFormat = "EEEE"
        
        let tomorrowString = dateFormatter.string(from: tomorrow).prefix(3)
        let afterTomorrowString = dateFormatter.string(from: afterTomorrow).prefix(3)
        let afterAfterTomorrowString = dateFormatter.string(from: afterAfterTomorrow).prefix(3)
        print("Weekdays are \(tomorrowString.prefix(3)) \(afterTomorrowString.prefix(3)) \(afterAfterTomorrowString.prefix(3))")
        return (String(tomorrowString), String(afterTomorrowString), String(afterAfterTomorrowString))
    }
    
}
extension ViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location:CLLocationCoordinate2D = manager.location?.coordinate {
            print("Your location is \(location.latitude) \(location.longitude)")
            manager.stopUpdatingLocation()
            manager.delegate = nil
            //get some Weather data
            self.getWeather(latitude: String(location.latitude), longitude: String(location.longitude))
        }
    }
}
extension Date {
    var tomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: self)!
    }
    var afterTomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 2, to: self)!
    }
    var afterAfterTomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 3, to: self)!
    }
}

