import SwiftUI

struct ContentView: View {
    @State private var scaleU: CGFloat = 1.0
    @State private var scaleV: CGFloat = 1.0
    @State private var offset: CGPoint = .zero
    @State private var rotation: CGFloat = 0.0

    var body: some View {
        ARViewContainer(scaleU: $scaleU, scaleV: $scaleV, offset: $offset, rotation: $rotation)
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
