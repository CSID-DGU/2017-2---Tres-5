//
//  ViewController.m
//  HelloWorld
//
//  Created by hyunjun529 on 2017. 10. 12..
//  Copyright © 2017년 hyunjun529. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <ARSCNViewDelegate>

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;

@end

    
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set the view's delegate
    self.sceneView.delegate = self;
    
    // Show statistics such as fps and timing information
    self.sceneView.showsStatistics = YES;
    
    // Create a new scene
    SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/honoka/honoka.scn"];
    
    
    // h529 : add Honoka
    SCNNode *node = [scene.rootNode childNodeWithName:@"__socks_0_2_1_1" recursively:NO];
    
    SCNVector4 vec4_rot = SCNVector4Make(0, 1.0f, 0, M_PI/2);
    SCNVector3 vec3_scl = SCNVector3Make(0.15f, 0.15f, 0.15f);
    SCNMatrix4 mat4_translation = SCNMatrix4MakeTranslation(0.0f, -0.5f, -1.0f);
    SCNVector4 vec4_rot2 = SCNVector4Make(0, 1.0f, 0, -M_PI / 8);
    
    NSArray<SCNNode *> *nodes =  scene.rootNode.childNodes;
    
    for (int i = 0; i < [nodes count]; i++){
        nodes[i].rotation = vec4_rot;
        nodes[i].scale = vec3_scl;
        nodes[i].transform = mat4_translation;
        nodes[i].rotation = vec4_rot2;
    }
    
    
    // h529 : add cube
    // The 3D cube geometry we want to draw
    SCNBox *boxGeometry = [SCNBox
                           boxWithWidth:0.1
                           height:0.0
                           length:0.1
                           chamferRadius:0.0];
    
    // The node that wraps the geometry so we can add it to the scene
    SCNNode *boxNode = [SCNNode nodeWithGeometry:boxGeometry];
    
    // Position the box just in front of the camera
    boxNode.position = SCNVector3Make(0, 0, 0);
    
    // rootNode is a special node, it is the starting point of all
    // the items in the 3D scene
    [scene.rootNode addChildNode: boxNode];
    

    // h529 : add Planes
    // A dictionary of all the current planes being rendered in the scene
    self.planes = [NSMutableDictionary new];
    

    // h529 : DEBUG OPTION
    self.sceneView.autoenablesDefaultLighting = YES;
    
    self.sceneView.debugOptions =
        ARSCNDebugOptionShowWorldOrigin |
        ARSCNDebugOptionShowFeaturePoints;
    
    
    // Set the scene to the view
    self.sceneView.scene = scene;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Create a session configuration
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];

    // Specify that we do want to track horizontal planes. Setting this will cause the ARSCNViewDelegate
    // methods to be called when scenes are detected
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    
    // Run the view's session
    [self.sceneView.session runWithConfiguration:configuration];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Pause the view's session
    [self.sceneView.session pause];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - ARSCNViewDelegate

/*
// Override to create and configure nodes for anchors added to the view's session.
- (SCNNode *)renderer:(id<SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor {
    SCNNode *node = [SCNNode new];
 
    // Add geometry to the node...
 
    return node;
}
*/

/**
 Called when a new node has been mapped to the given anchor.
 
 @param renderer The renderer that will render the scene.
 @param node The node that maps to the anchor.
 @param anchor The added anchor.
 */
- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    if (![anchor isKindOfClass:[ARPlaneAnchor class]]) {
        return;
    }
    
    // When a new plane is detected we create a new SceneKit plane to visualize it in 3D
    Plane *plane = [[Plane alloc] initWithAnchor: (ARPlaneAnchor *)anchor];
    [self.planes setObject:plane forKey:anchor.identifier];
    [node addChildNode:plane];
}

/**
 Called when a node has been updated with data from the given anchor.
 
 @param renderer The renderer that will render the scene.
 @param node The node that was updated.
 @param anchor The anchor that was updated.
 */
- (void)renderer:(id <SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    Plane *plane = [self.planes objectForKey:anchor.identifier];
    if (plane == nil) {
        return;
    }
    
    // When an anchor is updated we need to also update our 3D geometry too. For example
    // the width and height of the plane detection may have changed so we need to update
    // our SceneKit geometry to match that
    [plane update:(ARPlaneAnchor *)anchor];
}

/**
 Called when a mapped node has been removed from the scene graph for the given anchor.
 
 @param renderer The renderer that will render the scene.
 @param node The node that was removed.
 @param anchor The anchor that was removed.
 */
- (void)renderer:(id <SCNSceneRenderer>)renderer didRemoveNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    // Nodes will be removed if planes multiple individual planes that are detected to all be
    // part of a larger plane are merged.
    [self.planes removeObjectForKey:anchor.identifier];
}

/**
 Called when a node will be updated with data from the given anchor.
 
 @param renderer The renderer that will render the scene.
 @param node The node that will be updated.
 @param anchor The anchor that was updated.
 */
- (void)renderer:(id <SCNSceneRenderer>)renderer willUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
}

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    
}

- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
}

@end
