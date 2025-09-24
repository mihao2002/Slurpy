import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true
        arView.session.run(config)
        arView.session.delegate = context.coordinator
        
        // Add tongue tip marker
        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.01))
        sphere.model?.materials = [SimpleMaterial(color: .red, isMetallic: true)]
        sphere.isEnabled = false
        
        let anchor = AnchorEntity(.face)
        anchor.addChild(sphere)
        arView.scene.addAnchor(anchor)
        
        context.coordinator.tongueMarker = sphere
        context.coordinator.anchor = anchor
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var tongueMarker: ModelEntity?
        var anchor: AnchorEntity?
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard let faceAnchor = frame.anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
            
            DispatchQueue.main.async {
                if let tongueMarker = self.tongueMarker {
                    if let tongueOut = faceAnchor.blendShapes[.tongueOut] as? Float {
                        if tongueOut > 0.5 {
                            tongueMarker.isEnabled = true
                            
                            // Approximate position in front of mouth
                            let offset = Float(tongueOut) * 0.05 // extend as tongueOut increases
                            tongueMarker.position = SIMD3<Float>(0, -0.02, -0.1 - offset)
                            
                        } else {
                            tongueMarker.isEnabled = false
                        }
                    }
                }
            }
        }
    }
}
