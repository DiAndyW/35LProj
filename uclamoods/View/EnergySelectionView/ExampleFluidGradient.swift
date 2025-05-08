import SwiftUI
import FluidGradient

struct ExampleFluidGradient: View {
    var body: some View {
        FluidGradient(blobs: [.red, .green, .blue],
                      highlights: [.yellow, .orange, .purple],
                      speed: 1.0,
                      blur: 0.75)
          .background(.quaternary)
    }
}

#Preview {
    ExampleFluidGradient()
}
