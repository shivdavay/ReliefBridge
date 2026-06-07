// ReliefBridge/Views/DigitalTwin/AircraftSceneView.swift

import SwiftUI
import SceneKit

#if canImport(UIKit)
import UIKit

struct AircraftSceneView: UIViewRepresentable {

    let aircraft: Aircraft
    let isReliefBridgeEngaged: Bool

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = UIColor(red: 0x0B / 255.0, green: 0x14 / 255.0, blue: 0x22 / 255.0, alpha: 1.0)
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = false
        scnView.antialiasingMode = .multisampling4X
        scnView.scene = buildScene(for: aircraft)

        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        scnView.addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        scnView.addGestureRecognizer(pinch)

        context.coordinator.scnView = scnView
        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        applyFlapGlow(in: scnView.scene, engaged: isReliefBridgeEngaged)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func buildScene(for aircraft: Aircraft) -> SCNScene {
        let scene = SCNScene()
        let config = AirframeConfiguration(aircraftType: aircraft.aircraftType)
        let livery = CarrierLivery(carrier: aircraft.carrier)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 38
        cameraNode.position = SCNVector3(0, 1.65, 9.0)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)

        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.28, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)

        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .omni
        keyLight.light?.color = UIColor(white: 0.95, alpha: 1.0)
        keyLight.position = SCNVector3(4.5, 4.0, 7.0)
        scene.rootNode.addChildNode(keyLight)

        let rimLight = SCNNode()
        rimLight.light = SCNLight()
        rimLight.light?.type = .directional
        rimLight.light?.color = UIColor(red: 0.15, green: 0.82, blue: 0.84, alpha: 1.0)
        rimLight.eulerAngles = SCNVector3(-0.35, -0.95, 0)
        scene.rootNode.addChildNode(rimLight)

        let floorNode = SCNNode(geometry: SCNFloor())
        floorNode.geometry?.firstMaterial?.diffuse.contents = UIColor.black.withAlphaComponent(0.0)
        floorNode.geometry?.firstMaterial?.reflective.contents = UIColor.white.withAlphaComponent(0.06)
        floorNode.position = SCNVector3(0, -1.5, 0)
        scene.rootNode.addChildNode(floorNode)

        let pivot = SCNNode()
        pivot.name = "aircraftPivot"
        pivot.eulerAngles = SCNVector3(0.14, -0.4, 0)
        scene.rootNode.addChildNode(pivot)

        let fuselage = SCNNode(geometry: SCNCylinder(radius: config.fuselageRadius, height: config.fuselageLength))
        fuselage.name = "fuselage"
        fuselage.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        fuselage.geometry?.firstMaterial = material(
            diffuse: livery.bodyColor,
            metalness: 0.28,
            roughness: 0.22
        )
        pivot.addChildNode(fuselage)

        let nose = SCNNode(geometry: SCNSphere(radius: config.fuselageRadius * 1.04))
        nose.name = "nose"
        nose.scale = SCNVector3(1.35, 0.88, 0.88)
        nose.position = vector(config.fuselageLength / 2.0 - (config.fuselageRadius * 0.55), 0, 0)
        nose.geometry?.firstMaterial = material(
            diffuse: livery.bodyColor,
            metalness: 0.24,
            roughness: 0.18
        )
        pivot.addChildNode(nose)

        let cockpit = SCNNode(
            geometry: SCNBox(
                width: config.fuselageRadius * 0.85,
                height: config.fuselageRadius * 0.18,
                length: config.fuselageRadius * 1.1,
                chamferRadius: config.fuselageRadius * 0.05
            )
        )
        cockpit.position = vector(config.fuselageLength / 2.0 - (config.fuselageRadius * 0.25), config.fuselageRadius * 0.23, 0)
        cockpit.geometry?.firstMaterial = material(
            diffuse: UIColor(red: 0.18, green: 0.23, blue: 0.30, alpha: 0.96),
            metalness: 0.14,
            roughness: 0.18
        )
        pivot.addChildNode(cockpit)

        let tailCone = SCNNode(geometry: SCNCone(topRadius: 0.04, bottomRadius: config.fuselageRadius * 0.92, height: config.tailConeLength))
        tailCone.name = "tailCone"
        tailCone.eulerAngles = SCNVector3(0, 0, -Float.pi / 2)
        tailCone.position = vector(-(config.fuselageLength / 2.0) - (config.tailConeLength / 2.0) + (config.fuselageRadius * 1.15), 0, 0)
        tailCone.geometry?.firstMaterial = material(
            diffuse: livery.bodyColor,
            metalness: 0.26,
            roughness: 0.26
        )
        pivot.addChildNode(tailCone)

        let cheatline = SCNNode(
            geometry: SCNBox(
                width: config.fuselageLength * 0.88,
                height: config.fuselageRadius * 0.16,
                length: config.fuselageRadius * 1.78,
                chamferRadius: config.fuselageRadius * 0.06
            )
        )
        cheatline.position = vector(0, config.fuselageRadius * 0.02, 0)
        cheatline.geometry?.firstMaterial = material(
            diffuse: livery.cheatlineColor,
            metalness: 0.12,
            roughness: 0.32
        )
        pivot.addChildNode(cheatline)

        let cargoDoor = SCNNode(
            geometry: SCNBox(
                width: config.fuselageLength * 0.22,
                height: config.fuselageRadius * 0.72,
                length: 0.02,
                chamferRadius: 0.02
            )
        )
        cargoDoor.position = vector(config.fuselageLength * 0.06, config.fuselageRadius * 0.02, config.fuselageRadius * 0.92)
        cargoDoor.geometry?.firstMaterial = material(
            diffuse: UIColor.white.withAlphaComponent(0.22),
            metalness: 0.18,
            roughness: 0.40
        )
        pivot.addChildNode(cargoDoor)

        let tailFin = SCNNode(
            geometry: SCNBox(
                width: config.tailFinDepth,
                height: config.tailFinHeight,
                length: config.tailFinSpan,
                chamferRadius: 0.03
            )
        )
        tailFin.name = "tailFin"
        tailFin.pivot = SCNMatrix4MakeTranslation(0, -Float(config.tailFinHeight / 2.0), 0)
        tailFin.position = vector(-config.fuselageLength / 2.0 + (config.fuselageRadius * 0.5), config.fuselageRadius * 0.1, 0)
        tailFin.eulerAngles = SCNVector3(0, 0, config.tailSweep)
        tailFin.geometry?.firstMaterial = material(
            diffuse: livery.tailColor,
            metalness: 0.30,
            roughness: 0.24
        )
        pivot.addChildNode(tailFin)

        let horizontalStab = makeWing(
            halfSpan: config.horizontalTailHalfSpan,
            rootChord: config.horizontalTailChord,
            tipChord: config.horizontalTailTipChord,
            thickness: config.wingThickness * 0.82,
            color: livery.bodyColor
        )
        horizontalStab.position = vector(-config.fuselageLength / 2.0 + (config.fuselageRadius * 0.25), config.fuselageRadius * 0.05, 0)
        horizontalStab.eulerAngles = SCNVector3(0, 0, 0.10)
        pivot.addChildNode(horizontalStab)

        let mainWing = makeWing(
            halfSpan: config.wingHalfSpan,
            rootChord: config.wingRootChord,
            tipChord: config.wingTipChord,
            thickness: config.wingThickness,
            color: livery.bodyColor
        )
        mainWing.name = "mainWing"
        mainWing.position = SCNVector3(config.wingAnchorX, config.wingAnchorY, 0)
        mainWing.eulerAngles = SCNVector3(0, 0, config.wingIncidence)
        pivot.addChildNode(mainWing)

        let flapHighlight = SCNNode(
            geometry: SCNBox(
                width: config.wingRootChord * 0.26,
                height: config.wingThickness * 0.9,
                length: config.wingHalfSpan * 1.1,
                chamferRadius: 0.02
            )
        )
        flapHighlight.name = "flap"
        flapHighlight.position = SCNVector3(config.wingAnchorX - Float(config.wingRootChord * 0.18), config.wingAnchorY - 0.01, 0)
        flapHighlight.geometry?.firstMaterial = material(
            diffuse: UIColor(red: 0.72, green: 0.80, blue: 0.86, alpha: 0.72),
            metalness: 0.18,
            roughness: 0.30
        )
        pivot.addChildNode(flapHighlight)

        for engineIndex in 0..<config.engineCount {
            let zDirection: Float = engineIndex % 2 == 0 ? 1 : -1
            let pairIndex = Float(engineIndex / 2)
            let foreAftOffset = Float(config.engineCount == 4 ? (pairIndex == 0 ? 0.4 : -0.35) : 0.0)
            let engine = SCNNode(geometry: SCNCylinder(radius: config.engineRadius, height: config.engineLength))
            engine.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            engine.position = SCNVector3(
                config.wingAnchorX + foreAftOffset,
                config.wingAnchorY - Float(config.engineDrop),
                zDirection * Float(config.engineSpanOffset)
            )
            engine.geometry?.firstMaterial = material(
                diffuse: livery.engineColor,
                metalness: 0.74,
                roughness: 0.22
            )
            pivot.addChildNode(engine)
        }

        let titleNode = textNode(text: aircraft.flightIdentifier, color: UIColor.white.withAlphaComponent(0.92), fontSize: 0.26)
        titleNode.position = SCNVector3(-1.65, 1.55, 0)
        scene.rootNode.addChildNode(titleNode)

        let subtitleNode = textNode(text: aircraft.aircraftType, color: livery.tailColor.withAlphaComponent(0.86), fontSize: 0.16)
        subtitleNode.position = SCNVector3(-1.65, 1.18, 0)
        scene.rootNode.addChildNode(subtitleNode)

        let routeNode = textNode(text: aircraft.routeLabel, color: UIColor(red: 0.60, green: 0.69, blue: 0.82, alpha: 0.92), fontSize: 0.14)
        routeNode.position = SCNVector3(-1.65, 0.90, 0)
        scene.rootNode.addChildNode(routeNode)

        applyFlapGlow(in: scene, engaged: isReliefBridgeEngaged)
        return scene
    }

    private func makeWing(
        halfSpan: CGFloat,
        rootChord: CGFloat,
        tipChord: CGFloat,
        thickness: CGFloat,
        color: UIColor
    ) -> SCNNode {
        let wingShape = UIBezierPath()
        wingShape.move(to: CGPoint(x: 0, y: 0))
        wingShape.addLine(to: CGPoint(x: rootChord, y: 0))
        wingShape.addLine(to: CGPoint(x: tipChord, y: halfSpan))
        wingShape.addLine(to: CGPoint(x: 0, y: halfSpan * 0.88))
        wingShape.close()

        let wingGeometry = SCNShape(path: wingShape, extrusionDepth: thickness)
        wingGeometry.firstMaterial = material(
            diffuse: color,
            metalness: 0.26,
            roughness: 0.28
        )

        let rightWing = SCNNode(geometry: wingGeometry)
        rightWing.pivot = SCNMatrix4MakeTranslation(Float(rootChord * 0.32), 0, Float(thickness / 2.0))
        rightWing.eulerAngles = SCNVector3(Float.pi / 2, 0, -Float.pi / 2)

        let leftWing = rightWing.clone()
        leftWing.scale = SCNVector3(1, 1, -1)

        let wingAssembly = SCNNode()
        wingAssembly.addChildNode(rightWing)
        wingAssembly.addChildNode(leftWing)
        return wingAssembly
    }

    private func material(diffuse: UIColor, metalness: CGFloat, roughness: CGFloat) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = diffuse
        material.metalness.contents = metalness
        material.roughness.contents = roughness
        material.lightingModel = .physicallyBased
        return material
    }

    private func vector(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat) -> SCNVector3 {
        SCNVector3(Float(x), Float(y), Float(z))
    }

    private func textNode(text: String, color: UIColor, fontSize: CGFloat) -> SCNNode {
        let geometry = SCNText(string: text, extrusionDepth: 0.02)
        geometry.font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        geometry.flatness = 0.1
        geometry.firstMaterial?.diffuse.contents = color
        geometry.firstMaterial?.emission.contents = color.withAlphaComponent(0.14)

        let node = SCNNode(geometry: geometry)
        let (minBounds, maxBounds) = geometry.boundingBox
        node.pivot = SCNMatrix4MakeTranslation(minBounds.x, minBounds.y, minBounds.z)
        let width = maxBounds.x - minBounds.x
        if width > 0 {
            node.scale = SCNVector3(0.32, 0.32, 0.32)
        }
        return node
    }

    private func applyFlapGlow(in scene: SCNScene?, engaged: Bool) {
        guard let scene,
              let flapNode = scene.rootNode.childNode(withName: "flap", recursively: true),
              let material = flapNode.geometry?.firstMaterial else { return }

        material.emission.contents = engaged
            ? UIColor(red: 0x25 / 255.0, green: 0xD7 / 255.0, blue: 0xA0 / 255.0, alpha: 1.0)
            : UIColor.black
    }

    final class Coordinator: NSObject {
        weak var scnView: SCNView?

        private var rotationX: Float = 0.14
        private var rotationY: Float = -0.4
        private var cameraDistance: Float = 9.0
        private let minDistance: Float = 4.2
        private let maxDistance: Float = 18.0

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let scnView else { return }
            let translation = gesture.translation(in: scnView)
            let sensitivity: Float = 0.0048

            rotationY += Float(translation.x) * sensitivity
            rotationX += Float(translation.y) * sensitivity
            rotationX = max(-Float.pi / 2.7, min(Float.pi / 2.7, rotationX))

            applyRotation(to: scnView)
            gesture.setTranslation(.zero, in: scnView)
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let scnView else { return }
            let scale = Float(gesture.scale)
            cameraDistance = max(minDistance, min(maxDistance, cameraDistance / scale))
            gesture.scale = 1.0
            applyZoom(to: scnView)
        }

        private func applyRotation(to scnView: SCNView) {
            guard let pivot = scnView.scene?.rootNode.childNode(withName: "aircraftPivot", recursively: false) else {
                return
            }
            pivot.eulerAngles = SCNVector3(rotationX, rotationY, 0)
        }

        private func applyZoom(to scnView: SCNView) {
            guard let cameraNode = scnView.scene?.rootNode.childNodes.first(where: { $0.camera != nil }) else {
                return
            }
            cameraNode.position = SCNVector3(0, 1.65, cameraDistance)
        }
    }
}

private struct AirframeConfiguration {
    let fuselageLength: CGFloat
    let fuselageRadius: CGFloat
    let tailConeLength: CGFloat
    let wingHalfSpan: CGFloat
    let wingRootChord: CGFloat
    let wingTipChord: CGFloat
    let wingThickness: CGFloat
    let wingAnchorX: Float
    let wingAnchorY: Float
    let wingIncidence: Float
    let tailFinHeight: CGFloat
    let tailFinSpan: CGFloat
    let tailFinDepth: CGFloat
    let tailSweep: Float
    let horizontalTailHalfSpan: CGFloat
    let horizontalTailChord: CGFloat
    let horizontalTailTipChord: CGFloat
    let engineCount: Int
    let engineRadius: CGFloat
    let engineLength: CGFloat
    let engineDrop: CGFloat
    let engineSpanOffset: CGFloat

    init(aircraftType: String) {
        if aircraftType.contains("747") {
            fuselageLength = 5.6
            fuselageRadius = 0.29
            tailConeLength = 1.0
            wingHalfSpan = 3.0
            wingRootChord = 1.55
            wingTipChord = 0.48
            wingThickness = 0.12
            wingAnchorX = 0.35
            wingAnchorY = 0.02
            wingIncidence = 0.06
            tailFinHeight = 1.28
            tailFinSpan = 0.72
            tailFinDepth = 0.12
            tailSweep = 0.22
            horizontalTailHalfSpan = 1.28
            horizontalTailChord = 0.56
            horizontalTailTipChord = 0.22
            engineCount = 4
            engineRadius = 0.18
            engineLength = 0.82
            engineDrop = 0.30
            engineSpanOffset = 1.04
        } else if aircraftType.contains("777") {
            fuselageLength = 5.2
            fuselageRadius = 0.27
            tailConeLength = 0.92
            wingHalfSpan = 2.8
            wingRootChord = 1.42
            wingTipChord = 0.46
            wingThickness = 0.11
            wingAnchorX = 0.24
            wingAnchorY = 0.0
            wingIncidence = 0.05
            tailFinHeight = 1.20
            tailFinSpan = 0.66
            tailFinDepth = 0.11
            tailSweep = 0.18
            horizontalTailHalfSpan = 1.18
            horizontalTailChord = 0.50
            horizontalTailTipChord = 0.20
            engineCount = 2
            engineRadius = 0.21
            engineLength = 0.94
            engineDrop = 0.33
            engineSpanOffset = 1.18
        } else if aircraftType.contains("A330") {
            fuselageLength = 4.95
            fuselageRadius = 0.26
            tailConeLength = 0.86
            wingHalfSpan = 2.62
            wingRootChord = 1.36
            wingTipChord = 0.46
            wingThickness = 0.11
            wingAnchorX = 0.18
            wingAnchorY = -0.02
            wingIncidence = 0.05
            tailFinHeight = 1.10
            tailFinSpan = 0.62
            tailFinDepth = 0.11
            tailSweep = 0.17
            horizontalTailHalfSpan = 1.08
            horizontalTailChord = 0.48
            horizontalTailTipChord = 0.20
            engineCount = 2
            engineRadius = 0.19
            engineLength = 0.82
            engineDrop = 0.30
            engineSpanOffset = 1.08
        } else {
            fuselageLength = 4.7
            fuselageRadius = 0.24
            tailConeLength = 0.82
            wingHalfSpan = 2.35
            wingRootChord = 1.24
            wingTipChord = 0.42
            wingThickness = 0.10
            wingAnchorX = 0.10
            wingAnchorY = -0.04
            wingIncidence = 0.05
            tailFinHeight = 1.02
            tailFinSpan = 0.58
            tailFinDepth = 0.10
            tailSweep = 0.15
            horizontalTailHalfSpan = 0.98
            horizontalTailChord = 0.42
            horizontalTailTipChord = 0.18
            engineCount = 2
            engineRadius = 0.17
            engineLength = 0.72
            engineDrop = 0.28
            engineSpanOffset = 0.96
        }
    }
}

private struct CarrierLivery {
    let bodyColor: UIColor
    let cheatlineColor: UIColor
    let tailColor: UIColor
    let engineColor: UIColor

    init(carrier: CargoCarrier) {
        switch carrier {
        case .fedex:
            bodyColor = UIColor(red: 0.84, green: 0.85, blue: 0.88, alpha: 1.0)
            cheatlineColor = UIColor(red: 0.37, green: 0.20, blue: 0.54, alpha: 1.0)
            tailColor = UIColor(red: 0.98, green: 0.45, blue: 0.15, alpha: 1.0)
            engineColor = UIColor(red: 0.54, green: 0.57, blue: 0.62, alpha: 1.0)
        case .ups:
            bodyColor = UIColor(red: 0.80, green: 0.80, blue: 0.78, alpha: 1.0)
            cheatlineColor = UIColor(red: 0.26, green: 0.20, blue: 0.16, alpha: 1.0)
            tailColor = UIColor(red: 0.48, green: 0.35, blue: 0.21, alpha: 1.0)
            engineColor = UIColor(red: 0.42, green: 0.40, blue: 0.37, alpha: 1.0)
        case .dhl:
            bodyColor = UIColor(red: 0.95, green: 0.88, blue: 0.62, alpha: 1.0)
            cheatlineColor = UIColor(red: 0.79, green: 0.08, blue: 0.12, alpha: 1.0)
            tailColor = UIColor(red: 0.86, green: 0.12, blue: 0.14, alpha: 1.0)
            engineColor = UIColor(red: 0.46, green: 0.46, blue: 0.44, alpha: 1.0)
        }
    }
}

#else

struct AircraftSceneView: View {
    let aircraft: Aircraft
    let isReliefBridgeEngaged: Bool

    var body: some View {
        ZStack {
            Theme.Colors.background
            VStack(spacing: 10) {
                Image(systemName: "airplane")
                    .font(.system(size: 52))
                    .foregroundColor(isReliefBridgeEngaged ? Theme.Colors.efficiencyGreen : Theme.Colors.secondaryText)
                Text(aircraft.flightIdentifier)
                    .font(Theme.Fonts.monospacedDigit(size: 16, weight: .bold))
                    .foregroundColor(Theme.Colors.primaryText)
                Text("\(aircraft.aircraftType) • \(aircraft.routeLabel)")
                    .font(Theme.Fonts.sansSerif(size: 12))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
    }
}

#endif
