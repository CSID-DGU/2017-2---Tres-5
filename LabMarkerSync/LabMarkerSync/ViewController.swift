//
//  ViewController.swift
//  LabMarkerSync
//
//  Created by hyunjun529 on 2018. 3. 26..
//  Copyright © 2018년 hyunjun529. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    // from Stroyboard
    @IBOutlet var scnView: ARSCNView!
    @IBOutlet var btnOnOff: UIButton!
    @IBOutlet var debugBox: UITextView!
    
    // Anchor
    var reAnchor:matrix_float4x4!
    var rePositioning = false
    var detectedDataAnchor: ARAnchor?
    var processing = false
    
    // flag Input
    var flagButton = true
    
    // default Contents Object
    var columnBox = SCNBox(width: 0.1, height: 10.0, length: 0.1, chamferRadius: 1)
    
    var posX: Float!
    var posY: Float!
    var posZ: Float!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scnView.delegate = self
        scnView.session.delegate = self
        scnView.showsStatistics = true
        
        // create SCNScene
        let scene = SCNScene()
        scnView.scene = scene
        scnView.debugOptions = ARSCNDebugOptions.showWorldOrigin
        scnView.antialiasingMode = .multisampling4X
        scnView.automaticallyUpdatesLighting = true
        
        // set column material
        let colors = [UIColor.green, // front
            UIColor.red, // right
            UIColor.blue, // back
            UIColor.yellow, // left
            UIColor.purple, // top
            UIColor.gray] // bottom
        let sideMaterials = colors.map { color -> SCNMaterial in
            let material = SCNMaterial()
            material.diffuse.contents = color
            material.locksAmbientWithDiffuse = true
            return material
        }
        columnBox.materials = sideMaterials
        
        // create corner column
        // for measuring distance
        let sizeSpace = Double(10)
        let sizeSpaceF = sizeSpace / 2.0
        let sizeSpaceB = sizeSpace / 2.0 * (-1.0)
        let cornerNode = SCNNode(geometry: columnBox)
        cornerNode.position = SCNVector3(sizeSpaceF, 0, sizeSpaceF)
        scnView.scene.rootNode.addChildNode(cornerNode.clone())
        cornerNode.position = SCNVector3(sizeSpaceF, 0, sizeSpaceB)
        scnView.scene.rootNode.addChildNode(cornerNode.clone())
        cornerNode.position = SCNVector3(sizeSpaceB, 0, sizeSpaceF)
        scnView.scene.rootNode.addChildNode(cornerNode.clone())
        cornerNode.position = SCNVector3(sizeSpaceB, 0, sizeSpaceB)
        scnView.scene.rootNode.addChildNode(cornerNode.clone())
        
        // scnView session run
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        scnView.session.run(configuration)
        
        // init param
        posX = 0.0
        posY = 0.0
        posZ = 0.0
    }
    
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
                    if let hitTestResult = hitTestResults.first
                    {
                        // If we already have an anchor, update the position of the attached node
                        if let detectedDataAnchor = self.detectedDataAnchor,
                            let node = self.scnView.node(for: detectedDataAnchor)
                        {
                            node.transform = SCNMatrix4(hitTestResult.worldTransform)
                            self.reAnchor = hitTestResult.worldTransform
                            
                        } else {
                            // Create an anchor. The node will be created in delegate methods
                            self.detectedDataAnchor = ARAnchor(transform: hitTestResult.worldTransform)
                            self.scnView.session.add(anchor: self.detectedDataAnchor!)
                            
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
        
        // reAnchor work!
        if self.reAnchor != nil {
            if self.rePositioning == false {
                self.rePositioning = true
                print("=====================================================")
                print("Reset Position")
                print("Move all to ", self.reAnchor)
                print("=====================================================")
                
                let wrapperNode = self.scnView.scene.rootNode.childNodes
                //(withName: nodeName, recursively: true)
                
                for cn in wrapperNode {
                    // 아래 코드는 모든 오브젝트를 가운데로 옮기는 코드
                    // cn.transform = SCNMatrix4(self.reAnchor)
                    cn.localTranslate(by:
                        SCNVector3(SCNMatrix4(self.reAnchor).m41,
                                   SCNMatrix4(self.reAnchor).m42,
                                   SCNMatrix4(self.reAnchor).m43))
                }
            }
            
            // Disable plane detection after the model has been added & reAnchor
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            scnView.session.run(configuration, options: [])
        }
        
        // debug screen
        var dbg = String("Debug \n")
        
        var posDeviceMat4 = scnView.session.currentFrame!.camera.transform
        
        if self.rePositioning {
            posDeviceMat4 = self.reAnchor - scnView.session.currentFrame!.camera.transform
        }
        
        posX = posDeviceMat4.columns.3.x
        posY = posDeviceMat4.columns.3.y
        posZ = posDeviceMat4.columns.3.z
        
        dbg += String(posX) + "\n"
        dbg += String(posY) + "\n"
        dbg += String(posZ) + "\n"
        
//        dbg += "[0][n]\n"
//        dbg += String(frame.camera.transform[0][0]) + "\n"
//        dbg += String(frame.camera.transform[0][1]) + "\n"
//        dbg += String(frame.camera.transform[0][2]) + "\n"
//        dbg += String(frame.camera.transform[0][3]) + "\n"
//
//        dbg += "[1][n]\n"
//        dbg += String(frame.camera.transform[1][0]) + "\n"
//        dbg += String(frame.camera.transform[1][1]) + "\n"
//        dbg += String(frame.camera.transform[1][2]) + "\n"
//        dbg += String(frame.camera.transform[1][3]) + "\n"
//
//        dbg += "[2][n]\n"
//        dbg += String(frame.camera.transform[2][0]) + "\n"
//        dbg += String(frame.camera.transform[2][1]) + "\n"
//        dbg += String(frame.camera.transform[2][2]) + "\n"
//        dbg += String(frame.camera.transform[2][3]) + "\n"
//
//        dbg += "[3][n]\n"
//        dbg += String(frame.camera.transform[3][0]) + "\n"
//        dbg += String(frame.camera.transform[3][1]) + "\n"
//        dbg += String(frame.camera.transform[3][2]) + "\n"
//        dbg += String(frame.camera.transform[3][3]) + "\n"
//
//        if !self.rePositioning
//        {
//            dbg += "\n"
//            dbg += "NOT SYNC" + "\n"
//            dbg += "NOT SYNC" + "\n"
//            dbg += "NOT SYNC" + "\n"
//        }
        
        debugBox.text = dbg
    }
    
    @IBAction func toglePlane(_ sender: Any) {
        flagButton = !flagButton
        if(flagButton)
        {
            //scnView.scene.rootNode.addChildNode(cornerNode)
        }
        else
        {
            //cornerNode.removeFromParentNode()
        }
        
        let url = URL(string: "http://p316.net/tres/lab1")!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let postString = "x=" + String(posX) + "&y=" + String(posY) + "&z=" + String(posZ)
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                // check for fundamental networking error
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                // check for http errors
            }
            
            let responseString = String(data: data, encoding: .utf8)
        }
        task.resume()
    }
    
    func randomFloat(min: Float, max: Float) -> Float {
        return (Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
