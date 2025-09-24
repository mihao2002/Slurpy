import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Disable live camera feed so markers are visible
        arView.environment.background = .color(.black)
        arView.cameraMode = .nonAR
        
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true
        arView.session.run(config)
        arView.session.delegate = context.coordinator
        
        context.coordinator.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        var tongueMarker: ModelEntity?
        var anchor: AnchorEntity?
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
            
            // Create marker
            let sphere = ModelEntity(mesh: .generateSphere(radius: 0.01))
            sphere.model?.materials = [SimpleMaterial(color: .red, isMetallic: true)]
            sphere.isEnabled = false
            
            let anchor = AnchorEntity(anchor: faceAnchor)
            anchor.addChild(sphere)
            
            self.arView?.scene.addAnchor(anchor)
            self.tongueMarker = sphere
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard let faceAnchor = frame.anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
            
            DispatchQueue.main.async {
                if let tongueMarker = self.tongueMarker {
                    if let tongueOut = faceAnchor.blendShapes[.tongueOut] as? Float {
                        if tongueOut > 0.2 { // threshold to show marker
                            tongueMarker.isEnabled = true
                            
                            // Place marker slightly in front of mouth
                            tongueMarker.position = SIMD3<Float>(0, -0.03, -0.06 - tongueOut * 0.05)
                        } else {
                            tongueMarker.isEnabled = false
                        }
                    }
                }
            }
        }
    }
}
