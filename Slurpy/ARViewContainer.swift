import SwiftUI
import ARKit
import SceneKit

struct ARViewContainer: UIViewRepresentable {
    @Binding var scaleU: CGFloat
    @Binding var scaleV: CGFloat
    @Binding var offset: CGPoint
    @Binding var rotation: CGFloat

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.delegate = context.coordinator
        arView.automaticallyUpdatesLighting = true

        let config = ARFaceTrackingConfiguration()
        arView.session.run(config)

        // Gesture recognizers
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch))
        arView.addGestureRecognizer(pinch)

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan))
        arView.addGestureRecognizer(pan)

        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation))
        arView.addGestureRecognizer(rotationGesture)

        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARViewContainer
        var faceNode: SCNNode?
        var faceGeometry: ARSCNFaceGeometry?

        init(_ parent: ARViewContainer) {
            self.parent = parent
        }

        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            guard let device = renderer.device, anchor is ARFaceAnchor else { return nil }
            faceGeometry = ARSCNFaceGeometry(device: device)
            faceNode = SCNNode(geometry: faceGeometry)

            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named: "tattoo") // tattoo image in Assets
            material.diffuse.wrapS = .clamp
            material.diffuse.wrapT = .clamp
//            material.transparency = 0.5 // 0 = invisible, 1 = fully opaque
//            material.transparencyMode = .dualLayer
            faceGeometry?.materials = [material]

            updateTextureTransform()

            return faceNode
        }

        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor,
                  let faceGeometry = faceGeometry else { return }
            faceGeometry.update(from: faceAnchor.geometry)
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let view = gesture.view else { return }
            if gesture.numberOfTouches < 2 { return }

            let location1 = gesture.location(ofTouch: 0, in: view)
            let location2 = gesture.location(ofTouch: 1, in: view)

            let dx = abs(location2.x - location1.x)
            let dy = abs(location2.y - location1.y)

            if dx > dy {
                parent.scaleU /= gesture.scale
            } else {
                parent.scaleV /= gesture.scale
            }

            gesture.scale = 1.0
            updateTextureTransform()
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            parent.offset.x -= translation.x / 500 // sensitivity
            parent.offset.y -= translation.y / 500
            gesture.setTranslation(.zero, in: gesture.view)
            updateTextureTransform()
        }

        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            parent.rotation -= gesture.rotation
            gesture.rotation = 0
            updateTextureTransform()
        }

        func updateTextureTransform() {
            guard let material = faceGeometry?.firstMaterial else { return }

            // Pivot → rotate → scale → translate
            var transform = SCNMatrix4MakeTranslation(-0.5, -0.5, 0) // pivot to center
            transform = SCNMatrix4Rotate(transform, Float(parent.rotation), 0, 0, 1)
            transform = SCNMatrix4Scale(transform, Float(parent.scaleU), Float(parent.scaleV), 1)
            transform = SCNMatrix4Translate(transform, Float(0.5 + parent.offset.x), Float(0.5 + parent.offset.y), 0)

            material.diffuse.contentsTransform = transform
        }
    }
}
