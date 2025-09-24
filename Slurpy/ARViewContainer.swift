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

        context.coordinator.arView = arView

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        var faceAnchorEntity: AnchorEntity?

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                if let faceAnchor = anchor as? ARFaceAnchor {
                    let anchorEntity = AnchorEntity(anchor: faceAnchor)
                    faceAnchorEntity = anchorEntity
                    arView?.scene.addAnchor(anchorEntity)

                    // Create a mesh for face geometry
                    if let mesh = try? MeshResource.generate(from: faceAnchor.geometry) {
                        let material = SimpleMaterial(color: .cyan, isMetallic: false)
                        let faceEntity = ModelEntity(mesh: mesh, materials: [material])
                        anchorEntity.addChild(faceEntity)
                    }
                }
            }
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard let faceAnchor = frame.anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
            if let anchorEntity = faceAnchorEntity {
                anchorEntity.anchor = faceAnchor
            }
        }
    }
}
