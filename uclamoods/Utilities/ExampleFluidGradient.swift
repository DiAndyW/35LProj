//
//  ContentView.swift
//  FluidGradientExample
//
//  Created by João Gabriel Pozzobon dos Santos on 28/11/22.
//

import SwiftUI
import FluidGradient

struct ContentView: View {
    @State var colors: [Color] = []
    @State var highlights: [Color] = [.white]
    
    @State var speed = 0.2
    
    let colorPool: [Color] = [Color(hex: "459DF4"), Color(hex: "9180FD"), .black]
    
    var body: some View {
        VStack {
            gradient
                .backgroundStyle(.black)
                .cornerRadius(16)
                .padding(4)
            
            HStack {
                Button("Randomize colors", action: setColors)
                Slider(value: $speed, in: 0...5)
            }.padding(4)
        }
        .padding(16)
        .navigationTitle("FluidGradient")
        .onAppear(perform: setColors)
        .background(.black)
    }
    
    func setColors() {
        colors = []
        highlights = [.white]
        for _ in 0...Int.random(in: 5...5) {
            colors.append(colorPool.randomElement()!)
        }
        for _ in 0...Int.random(in: 5...5) {
            highlights.append(colorPool.randomElement()!)
        }
    }
    
    var gradient: some View {
        FluidGradient(blobs: colors,
                      highlights: highlights,
                      speed: speed)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
