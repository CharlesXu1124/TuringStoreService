//
//  ViewController.swift
//  VStore
//
//  Created by Charles Xu on 2/6/21.
//

import UIKit
import RealityKit
import Alamofire
import SwiftyJSON
import RMQClient
import ARKit

class ARViewController: UIViewController, ARSessionDelegate, UNUserNotificationCenterDelegate {
    
    @IBOutlet var arView: ARView!
    var arAnchor: TuringStore.Scene!
    
    var counter = 0
    
    var configuration = ARWorldTrackingConfiguration()
    
    private var gestureProcessor = HandGestureProcessor()
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput")
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        handPoseRequest.maximumHandCount = 1
        arAnchor = try! TuringStore.loadScene()
        
        arView.scene.anchors.append(arAnchor)
        
        
        
        
    }
    
    func send(withData motionData: Double) {
        let delegate = RMQConnectionDelegateLogger()
        let conn = RMQConnection(uri: "amqp://user1:rtc2021@168.61.18.117:5672", delegate: delegate)
        conn.start()
        let ch = conn.createChannel()
        
        let q = ch.queue("hello")
        ch.defaultExchange().publish("Hello World!".data(using: .utf8)!, routingKey: q.name)
        
        conn.close()
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        arView.session.delegate = self
        setupARView()
        
        self.togglePeopleOcclusion()
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    fileprivate func togglePeopleOcclusion() {
        guard let config = arView.session.configuration as? ARWorldTrackingConfiguration else {
            fatalError("Unexpectedly failed to get the configuration.")
        }

        arView.session.run(config)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        print("Session failed. Changing worldAlignment property.")
        print(error.localizedDescription)

        if let arError = error as? ARError {
            switch arError.errorCode {
            case 102:
                configuration.worldAlignment = .gravity
                restartSessionWithoutDelete()
            default:
                restartSessionWithoutDelete()
            }
        }
    }
    
    func restartSessionWithoutDelete() {
        // Restart session with a different worldAlignment - prevents bug from crashing app
        self.arView.session.pause()

        self.arView.session.run(configuration, options: [
            .resetTracking,
            .removeExistingAnchors])
    }
    
    // function for handling tapping actions
    @objc
    func handleTap(recognizer: UITapGestureRecognizer) {
        
    }
    
    func setupARView() {
        arView.automaticallyConfigureSession = false
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        arView.session.run(configuration)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {

        counter += 1
        
        let handler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: .up, options: [:])
        do {
            if counter % 20 == 0 {
                
                
                try? handler.perform([handPoseRequest])
                guard let observation = handPoseRequest.results?.first else {return}

                let thumbPoints = try! observation.recognizedPoints(forGroupKey: .handLandmarkRegionKeyThumb)
                let indexFingerPoints = try observation.recognizedPoints(forGroupKey: .handLandmarkRegionKeyIndexFinger)
                let ringFingerPoints = try observation.recognizedPoints(forGroupKey: .handLandmarkRegionKeyRingFinger)
                // Look for tip points.
                guard let thumbTipPoint = thumbPoints[.handLandmarkKeyThumbTIP], let indexTipPoint = indexFingerPoints[.handLandmarkKeyIndexTIP], let ringTipPoint = ringFingerPoints[.handLandmarkKeyRingTIP] else {
                    return
                }

                // Ignore low confidence points.
                guard thumbTipPoint.confidence > 0.3 && indexTipPoint.confidence > 0.3 else {
                    return
                }

                let indexFingerAndThumbTipDistance = abs(thumbTipPoint.location.x - indexTipPoint.location.x) + abs(thumbTipPoint.location.y - indexTipPoint.location.y)

                print(indexFingerAndThumbTipDistance)
                // send the real time grabbing action data to the broker in Azure server
                if indexFingerAndThumbTipDistance < 0.05 {
                    send(withData: Double(indexFingerAndThumbTipDistance))
                }
                

            }
        } catch {

        }
    }
}


extension Entity{

  /// Changes The Text Of An Entity
  /// - Parameters:
  ///   - content: String
    func setText(_ content: String, _ keyword: String){ self.components[ModelComponent] = self.generatedModelComponent(text: content, keyword) }

  /// Generates A Model Component With The Specified Text
  /// - Parameter text: String
    func generatedModelComponent(text: String, _ keyword: String) -> ModelComponent{
        var modelComponent: ModelComponent!
        if keyword == "t" {
            modelComponent = ModelComponent(
                mesh: .generateText(text, extrusionDepth: TextElements().extrusionDepth, font: TextElements().font,containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail),
                materials: [SimpleMaterial(color: TextElements().colour, isMetallic: true)]

            )
        } else if keyword == "s" {
            modelComponent = ModelComponent(
                mesh: .generateText(text, extrusionDepth: SpeedElements().extrusionDepth, font: SpeedElements().font,containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail),
                materials: [SimpleMaterial(color: SpeedElements().colour, isMetallic: true)]

            )
        } else if keyword == "a" {
            modelComponent = ModelComponent(
                mesh: .generateText(text, extrusionDepth: AltitudeElements().extrusionDepth, font: AltitudeElements().font,containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail),
                materials: [SimpleMaterial(color: AltitudeElements().colour, isMetallic: true)]

            )
        }
        
    return modelComponent
  }

}

//--------------------
//MARK:- Text Elements
//--------------------

/// The Base Setup Of The MeshResource
struct TextElements{

  let initialText = "Cube"
  let extrusionDepth: Float = 0.001
    let font: MeshResource.Font = MeshResource.Font.systemFont(ofSize: 0.03, weight: .light)
    let colour: UIColor = .red
}

struct SpeedElements{
    let initialText = "Cube"
    let extrusionDepth: Float = 0.001
    let font: MeshResource.Font = MeshResource.Font.systemFont(ofSize: 0.01, weight: .light)
    let colour: UIColor = .purple
}

struct  AltitudeElements {
    let initialText = "Cube"
    let extrusionDepth: Float = 0.001
    let font: MeshResource.Font = MeshResource.Font.systemFont(ofSize: 0.01, weight: .light)
    let colour: UIColor = .green
}
