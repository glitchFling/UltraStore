//
//  SplashView.swift
//  SideStore
//
//  Created by Magesh K on 14/8/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import SwiftUI

@MainActor
final class SplashViewModel: ObservableObject {
    @Published var status: String = ""
    @Published var isReadyToExit = false

    func updateStatus(_ text: String) {
        status = text
    }
}

struct SplashView: View {
    @ObservedObject var viewModel: SplashViewModel
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stretch: CGFloat = 0
    @State private var isFlying = false
    @State private var didBeginExit = false

    var body: some View {
        GeometryReader { geometry in
            let logoSize = min(geometry.size.width * 0.48, 220)

            ZStack {
                Color.black.ignoresSafeArea()

                ZStack {
                    UltraStoreLogoBowl()
                        .stroke(.white, style: StrokeStyle(lineWidth: logoSize * 0.11, lineCap: .round))
                        .opacity(isFlying ? 0 : 1)

                    UltraStoreLaunchArrow(stretch: stretch)
                        .fill(.white)
                        .scaleEffect(isFlying ? 3.2 : 1, anchor: .center)
                        .rotationEffect(.degrees(isFlying ? 42 : 0))
                        .offset(
                            x: isFlying ? geometry.size.width : 0,
                            y: isFlying ? -geometry.size.height : 0
                        )
                }
                .frame(width: logoSize, height: logoSize)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("UltraStore")

                VStack {
                    Spacer()
                    Text(viewModel.status)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                        .opacity(didBeginExit ? 0 : 1)
                        .padding(.bottom, 48)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: viewModel.isReadyToExit) {
            guard viewModel.isReadyToExit, !didBeginExit else { return }
            didBeginExit = true

            guard !reduceMotion else {
                onFinished()
                return
            }

            // The curved exit and main-screen handoff need proper testing on-device.
            withAnimation(.easeInOut(duration: 0.6)) {
                stretch = 1
            }
            do {
                try await Task.sleep(nanoseconds: 600_000_000)
                try Task.checkCancellation()
                withAnimation(.easeIn(duration: 0.65)) {
                    isFlying = true
                }
                try await Task.sleep(nanoseconds: 180_000_000)
                try Task.checkCancellation()
                onFinished()
            } catch {
                // SwiftUI cancels this task if the splash is removed.
            }
        }
    }
}

// The static U is separate from the arrow so only the right arm stretches.
private struct UltraStoreLogoBowl: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.29, y: rect.height * 0.32))
        path.addLine(to: CGPoint(x: rect.width * 0.29, y: rect.height * 0.63))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.71, y: rect.height * 0.63),
            control1: CGPoint(x: rect.width * 0.29, y: rect.height * 0.94),
            control2: CGPoint(x: rect.width * 0.71, y: rect.height * 0.94)
        )
        return path
    }
}

private struct UltraStoreLaunchArrow: Shape {
    var stretch: CGFloat

    var animatableData: CGFloat {
        get { stretch }
        set { stretch = newValue }
    }

    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }

        // Bend left around the upper half of the U, with a vertical tangent at the tip.
        let tipX = 0.71 - 0.38 * stretch
        let tipY = 0.20 - 0.26 * stretch
        let headWidth = 0.10 + 0.035 * stretch
        let headHeight = 0.14 + 0.04 * stretch
        let neckY = tipY + headHeight
        var shaft = Path()
        shaft.move(to: point(0.71, 0.63))
        shaft.addCurve(
            to: point(tipX, neckY),
            control1: point(0.71 - 0.72 * stretch, 0.52),
            control2: point(tipX, neckY + 0.12)
        )
        var arrow = shaft.strokedPath(StrokeStyle(lineWidth: rect.width * 0.11, lineCap: .butt))
        var head = Path()
        head.move(to: point(tipX, tipY))
        head.addLine(to: point(tipX + headWidth, neckY))
        head.addLine(to: point(tipX - headWidth, neckY))
        head.closeSubpath()
        arrow.addPath(head)
        return arrow
    }
}
