//
//  ContentView.swift
//  PincushionDistortion
//
//  Created by Samuel McGarry on 9/18/23.
//

import SwiftUI
import Wave
import QuartzCore

struct ContentView: View {

    static let distortionRestingPosition = CGPoint(x: 0.5, y: 0.5)
    static let distortionRestingSize: CGFloat = 0
    static let distortionDraggingSize: CGFloat = 0.5

    @State var distortionCenter = distortionRestingPosition
    @State var distortionSize = distortionRestingSize
    @State var initialTouchLocation: CGPoint? = nil

    @State var distortionPositionAnimator = SpringAnimator<CGPoint>(
        spring: .init(dampingRatio: 0.92, response: 0.2),
        value: distortionRestingPosition
    )

    @State var distortionSizeAnimator = SpringAnimator<CGFloat>(
        spring: .init(dampingRatio: 0.3, response: 0.8),
        value: distortionRestingSize
    )
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let maxSampleOffset = CGSize(width: 40, height: 40)

            ZStack {
                Color.black.ignoresSafeArea()
                Image("colorlines")
                    .resizable()
                    .frame(width: proxy.size.height, height: proxy.size.height)
                    .aspectRatio(contentMode: .fit)
                    .layerEffect(
                        ShaderLibrary.pincushionDistortion(
                            .boundingRect,
                            .float2(distortionCenter.x, distortionCenter.y),
                            .float(distortionSize)
                        ),
                        maxSampleOffset: maxSampleOffset
                    )
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged{ value in
                        if initialTouchLocation == nil {
                            let newX = value.startLocation.x / size.height
                            let newY = value.startLocation.y / size.height
                            initialTouchLocation = CGPoint(x: newX, y: newY)
                        }

                        guard let initialTouchLocation else {
                            return
                        }

                        let translation = value.translation
                        let normTranslation = CGPoint(
                            x: translation.width / size.height,
                            y: translation.height / size.height
                        )

                        let newDistortionCenter = CGPoint(
                            x: initialTouchLocation.x + normTranslation.x,
                            y: initialTouchLocation.y + normTranslation.y
                        )

                        distortionPositionAnimator.spring = .init(dampingRatio: 0.92, response: 0.2)
                        distortionPositionAnimator.target = newDistortionCenter
                        distortionPositionAnimator.start()

                        distortionSizeAnimator.spring = .init(dampingRatio: 0.3, response: 0.8)
                        distortionSizeAnimator.target = Self.distortionDraggingSize
                        distortionSizeAnimator.start()
                    }
                    .onEnded { value in
                        let liftOffVelocity = value.velocity

                        distortionSizeAnimator.spring = .init(dampingRatio: 0.7, response: 0.6)
                        distortionSizeAnimator.velocity = CGFloat(liftOffVelocity.width / size.width)
                        distortionSizeAnimator.target = Self.distortionRestingSize
                        distortionSizeAnimator.start()
                        
                        initialTouchLocation = nil
                    }
            )
            .onAppear {
                distortionPositionAnimator.valueChanged = { value in
                    distortionCenter = value
                }

                distortionSizeAnimator.valueChanged = { value in
                    distortionSize = value
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
