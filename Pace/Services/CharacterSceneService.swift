//
//  CharacterSceneService.swift
//  Pace
//
//  Created by kartikay on 19/12/25.
//


import SceneKit
import SwiftUI
import UIKit

struct CharacterSceneConfig {
    var animationFileName: String
    var characterHeight: Float = 2.0
    var mirrorCharacter: Bool = true
    var cameraOffset: SCNVector3 = SCNVector3(x: -4.0, y: 1.0, z: 1)
    var lookAtYOffset: Float = -0.15
    var fieldOfView: CGFloat = 41
    var backgroundColor: UIColor = .white

    static var sideViewWalking: CharacterSceneConfig {
        CharacterSceneConfig(
            animationFileName: "Walking.dae",
            mirrorCharacter: true,
            cameraOffset: SCNVector3(x: -3, y: 0, z: 0)
        )
    }
}

class CharacterSceneService {
    static func createScene(with config: CharacterSceneConfig) -> SCNScene {
        guard let scene = SCNScene(named: config.animationFileName) else {
            print("Failed to load scene: \(config.animationFileName)")
            return SCNScene()
        }

        let containerNode = setupCharacterContainer(
            in: scene,
            targetHeight: config.characterHeight,
            mirror: config.mirrorCharacter
        )

        let targetNode = findHipNode(in: containerNode) ?? containerNode
        setupFollowCamera(
            in: scene,
            tracking: targetNode,
            config: config
        )

        scene.background.contents = config.backgroundColor
        return scene
    }

    static func createWalkingScene(fileName: String) -> SCNScene {
        var config = CharacterSceneConfig.sideViewWalking
        config.animationFileName = fileName
        return createScene(with: config)
    }

    private static func setupCharacterContainer(
        in scene: SCNScene,
        targetHeight: Float,
        mirror: Bool
    ) -> SCNNode {
        let (minBound, maxBound) = scene.rootNode.boundingBox
        let characterHeight = maxBound.y - minBound.y
        let characterWidth = maxBound.x - minBound.x
        let characterDepth = maxBound.z - minBound.z

        let centerX = (minBound.x + maxBound.x) / 2
        let centerZ = (minBound.z + maxBound.z) / 2

        let maxDimension = max(characterHeight, characterWidth, characterDepth)
        let scaleFactor = targetHeight / maxDimension

        let containerNode = SCNNode()
        containerNode.name = "CharacterContainer"

        let childrenToMove = scene.rootNode.childNodes.filter { $0.camera == nil }
        for child in childrenToMove {
            child.removeFromParentNode()
            containerNode.addChildNode(child)
        }

        let xScale = mirror ? -scaleFactor : scaleFactor
        containerNode.scale = SCNVector3(xScale, scaleFactor, scaleFactor)

        containerNode.position = SCNVector3(
            -centerX * scaleFactor,
            -minBound.y * scaleFactor,
            -centerZ * scaleFactor
        )

        scene.rootNode.addChildNode(containerNode)
        return containerNode
    }

    private static func setupFollowCamera(
        in scene: SCNScene,
        tracking targetNode: SCNNode,
        config: CharacterSceneConfig
    ) {
        let lookAtTarget = SCNNode()
        lookAtTarget.name = "CameraTarget"
        scene.rootNode.addChildNode(lookAtTarget)

        let cameraNode = SCNNode()
        cameraNode.name = "FollowCamera"
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = config.fieldOfView
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 100
        scene.rootNode.addChildNode(cameraNode)

        let cameraOffset = config.cameraOffset
        let lookAtYOffset = config.lookAtYOffset

        let lookAtConstraint = SCNLookAtConstraint(target: lookAtTarget)
        lookAtConstraint.isGimbalLockEnabled = true

        let followConstraint = SCNTransformConstraint.positionConstraint(
            inWorldSpace: true
        ) { (node, currentPosition) -> SCNVector3 in
            let characterPos = targetNode.presentation.worldPosition
            return SCNVector3(
                characterPos.x + cameraOffset.x,
                characterPos.y + cameraOffset.y,
                characterPos.z + cameraOffset.z
            )
        }

        let targetFollowConstraint = SCNTransformConstraint.positionConstraint(
            inWorldSpace: true
        ) { (node, currentPosition) -> SCNVector3 in
            let characterPos = targetNode.presentation.worldPosition
            return SCNVector3(
                characterPos.x,
                characterPos.y + lookAtYOffset,
                characterPos.z
            )
        }

        lookAtTarget.constraints = [targetFollowConstraint]
        cameraNode.constraints = [followConstraint, lookAtConstraint]
    }

    private static func findHipNode(in node: SCNNode) -> SCNNode? {
        let hipNames = [
            "mixamorig:Hips", "Hips", "pelvis", "Pelvis",
            "root", "Root", "Armature", "mixamorig_Hips",
        ]

        if let name = node.name {
            for hipName in hipNames {
                if name.lowercased().contains(hipName.lowercased()) {
                    return node
                }
            }
        }

        for child in node.childNodes {
            if let found = findHipNode(in: child) {
                return found
            }
        }
        return nil
    }
}

#Preview {
    let config = CharacterSceneConfig(
        animationFileName: "Walking.dae",
        characterHeight: 1.5,
        mirrorCharacter: true,
        cameraOffset: SCNVector3(x: -4, y: 0, z: 0),
        lookAtYOffset: -0.15,
        fieldOfView: 35,
        backgroundColor: .white
    )

    return SceneView(
        scene: CharacterSceneService.createScene(with: config),
        options: [.autoenablesDefaultLighting]
    )
}
