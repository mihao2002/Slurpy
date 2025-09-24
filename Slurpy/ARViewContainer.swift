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
        let anchor = AnchorEntity(.face)
        anchor.addChild(sphere)
        arView.scene.addAnchor(anchor)
        
        sphere.name = "tongueTipMarker"
        
        context.coordinator.tongueMarker = sphere
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var tongueMarker: ModelEntity?
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard let faceAnchor = frame.anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
            
            DispatchQueue.main.async {
                if let tongueMarker = self.tongueMarker {
                    if let tongueOut = faceAnchor.blendShapes[.tongueOut] as? Float {
                        if tongueOut > 0.5 {
                            tongueMarker.isEnabled = true
                            tongueMarker.position = SIMD3<Float>(
                                faceAnchor.transform.columns.3.x,
                                faceAnchor.transform.columns.3.y - 0.02,
                                faceAnchor.transform.columns.3.z - 0.05
                            )
                        } else {
                            tongueMarker.isEnabled = false
                        }
                    }
                }
            }
        }
    }
}
