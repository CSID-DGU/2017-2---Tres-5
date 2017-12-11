// Copyright (c) 2016 Vectorform LLC
// http://www.vectorform.com/
// https://github.com/CocoaHeadsDetroit/ARKit2DTracking
//
// ARKit2DTracking
// ViewController.swift
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    // MARK: - Properties
    
    @IBOutlet var sceneView: ARSCNView!
    
    var reAnchor:matrix_float4x4!
    var rePositioning = false
    
    var detectedDataAnchor: ARAnchor?
    var processing = false
    
    var nodeModel:SCNNode!
    let nodeName = "Bolt.001_Material.001"
    
    // MARK: - View Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Set the session's delegate
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // h529 : show virtual coordinate
        sceneView.debugOptions = ARSCNDebugOptions.showWorldOrigin
        
        // h529 : better rendering option
        sceneView.antialiasingMode = .multisampling4X
        sceneView.automaticallyUpdatesLighting = true
        
        // h529 : create scene
        let scene = SCNScene()
        sceneView.scene = scene
        let modelScene = SCNScene(named: "StopSign.scn", inDirectory: "Models.scnassets/StopSign")!
        self.nodeModel =  modelScene.rootNode.childNode(withName: nodeName, recursively: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Enable horizontal plane detection
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSessionDelegate
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        // Only run one Vision request at a time
        if self.processing {
            return
        }
        
        self.processing = true
        
        // Create a Barcode Detection Request
        let request = VNDetectBarcodesRequest { (request, error) in
            
            // Get the first result out of the results, if there are any
            if let results = request.results, let result = results.first as? VNBarcodeObservation {
                
                // Get the bounding box for the bar code and find the center
                var rect = result.boundingBox
                
                // Flip coordinates
                rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
                rect = rect.applying(CGAffineTransform(translationX: 0, y: 1))
                
                // Get center
                let center = CGPoint(x: rect.midX, y: rect.midY)
                
                // Go back to the main thread
                DispatchQueue.main.async {
                    
                    // Perform a hit test on the ARFrame to find a surface
                    let hitTestResults = frame.hitTest(center, types: [.featurePoint/*, .estimatedHorizontalPlane, .existingPlane, .existingPlaneUsingExtent*/] )
                    
                    // If we have a result, process it
                    if let hitTestResult = hitTestResults.first {
                        
                        // If we already have an anchor, update the position of the attached node
                        if let detectedDataAnchor = self.detectedDataAnchor,
                            let node = self.sceneView.node(for: detectedDataAnchor) {
                                
                                node.transform = SCNMatrix4(hitTestResult.worldTransform)
                                //self.reAnchor = ARAnchor(transform: hitTestResult.worldTransform).transform
                                self.reAnchor = hitTestResult.worldTransform
                            
                            
                            
                        } else {
                            // Create an anchor. The node will be created in delegate methods
                            self.detectedDataAnchor = ARAnchor(transform: hitTestResult.worldTransform)
                            self.sceneView.session.add(anchor: self.detectedDataAnchor!)
                            
                            print("=====================================================")
                            print(hitTestResult.worldTransform) // this is mat4 about relative position from origin
                            self.reAnchor = hitTestResult.worldTransform
                            print("=====================================================")
                        }
                    }
                    
                    // Set processing flag off
                    self.processing = false
                }
                
            } else {
                // Set processing flag off
                self.processing = false
            }
        }
        
        // Process the request in the background
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Set it to recognize QR code only
                request.symbologies = [.QR]
                
                // Create a request handler using the captured image from the ARFrame
                let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage,
                                                                options: [:])
                // Process the request
                try imageRequestHandler.perform([request])
            } catch {
                
            }
        }
        
        if self.reAnchor != nil {
            if self.rePositioning == false {
                self.rePositioning = true
                print("=====================================================")
                print("Reset Position")
                print("Move all to ", self.reAnchor)
                print("=====================================================")

                let wrapperNode = self.sceneView.scene.rootNode.childNodes
                //(withName: nodeName, recursively: true)
                
                for cn in wrapperNode {
                    //cn.transform = SCNMatrix4(self.reAnchor) // 전부 따라 움직이는 예제
                    cn.localTranslate(by: SCNVector3(SCNMatrix4(self.reAnchor).m41, SCNMatrix4(self.reAnchor).m42, SCNMatrix4(self.reAnchor).m43))
                }
            }
        }
        
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if !anchor.isKind(of: ARPlaneAnchor.self) {
            DispatchQueue.main.async {
                if self.nodeModel != nil {
                    let modelClone = self.nodeModel.clone()
                    modelClone.position = SCNVector3Zero
                    
                    // Add model as a child of the node
                    node.addChildNode(modelClone)
                 
                    // it's same.
//                    print(node.worldTransform)
//                    print(anchor.transform)
                }
            }
        }
    }
    
    
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//
//        // If this is our anchor, create a node
//        if self.detectedDataAnchor?.identifier == anchor.identifier {
//
//            // Create a 3D Cup to display
//            guard let virtualObjectScene = SCNScene(named: "StopSign.scn", inDirectory: "Models.scnassets/StopSign") else {
//                return nil
//            }
//
//            let wrapperNode = SCNNode()
//
//            for child in virtualObjectScene.rootNode.childNodes {
//                child.geometry?.firstMaterial?.lightingModel = .physicallyBased
//                child.movabilityHint = .movable
//                wrapperNode.addChildNode(child)
//            }
//
//            // Set its position based off the anchor
//            wrapperNode.transform = SCNMatrix4(anchor.transform)
//
//            return wrapperNode
//        }
//
//        return nil
//    }
    
    // MARK : - TOUCH
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let location = touches.first!.location(in: sceneView)
        
        // Let's test if a 3D Object was touch
        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        
        let hitResults: [SCNHitTestResult]  = sceneView.hitTest(location, options: hitTestOptions)
        
        if let hit = hitResults.first {
            if let node = getParent(hit.node) {
                node.removeFromParentNode()
                return
            }
        }
        
        // No object was touch? Try feature points
        let hitResultsFeaturePoints: [ARHitTestResult]  = sceneView.hitTest(location, types: .featurePoint)
        
        if let hit = hitResultsFeaturePoints.first {
            
            // Get the rotation matrix of the camera
            let rotate = simd_float4x4(SCNMatrix4MakeRotation(sceneView.session.currentFrame!.camera.eulerAngles.y, 0, 1, 0))
            
            // Combine the matrices
            let finalTransform = simd_mul(hit.worldTransform, rotate)
            sceneView.session.add(anchor: ARAnchor(transform: finalTransform))
            //sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
        }
    }
    
    func getParent(_ nodeFound: SCNNode?) -> SCNNode? {
        if let node = nodeFound {
            if node.name == nodeName {
                return node
            } else if let parent = node.parent {
                return getParent(parent)
            }
        }
        return nil
    }
    
}
