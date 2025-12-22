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
    var backgroundColor: UIColor = .systemBackground
    var showFloor: Bool = true
    var floorColor: UIColor = .systemBackground
    var showShadow: Bool = true
    
    var groundTextureName: String? = nil
    var scrollSpeed: Float = 0.5
    var textureScale: Float = 4.0

    static var sideViewWalking: CharacterSceneConfig {
        CharacterSceneConfig(
            animationFileName: "Walking.dae",
            mirrorCharacter: true,
            cameraOffset: SCNVector3(x: -3, y: 0, z: 0),
            showFloor: true,
            showShadow: true
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
        
        if config.showShadow {
            enableShadowCasting(on: containerNode)
        }

        let targetNode = findHipNode(in: containerNode) ?? containerNode
        
        if config.showFloor {
            setupFloor(in: scene, config: config)
        }
        
        if config.showShadow {
            setupLighting(in: scene, tracking: targetNode)
        }
        
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
    
    private static func setupFloor(in scene: SCNScene, config: CharacterSceneConfig) {
        if let textureName = config.groundTextureName,
           let textureImage = UIImage(named: textureName) {
            setupTexturedFloor(in: scene, config: config, texture: textureImage)
        } else {
            setupSolidColorFloor(in: scene, config: config)
        }
    }
    
    private static func setupTexturedFloor(in scene: SCNScene, config: CharacterSceneConfig, texture: UIImage) {
        let floorGeometry = SCNPlane(width: 10, height: 10)
        
        let floorMaterial = SCNMaterial()
        floorMaterial.diffuse.contents = texture
        floorMaterial.diffuse.wrapS = .repeat
        floorMaterial.diffuse.wrapT = .repeat
        
        let scale = config.textureScale
        floorMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(scale, scale, 1)
        
        floorMaterial.lightingModel = .physicallyBased
        floorMaterial.roughness.contents = 0.8
        floorGeometry.materials = [floorMaterial]
        
        let floorNode = SCNNode(geometry: floorGeometry)
        floorNode.name = "TexturedFloor"
        floorNode.eulerAngles.x = -.pi / 2
        floorNode.position = SCNVector3(0, 0, 0)
        floorNode.castsShadow = false
        
        scene.rootNode.addChildNode(floorNode)
        
        let scrollSpeed = config.scrollSpeed
        let cycleDuration: TimeInterval = 1.0 / Double(scrollSpeed)
        
        let scrollOneCycle = SCNAction.customAction(duration: cycleDuration) { node, elapsedTime in
            let progress = Float(elapsedTime / cycleDuration)
            let transform = SCNMatrix4Mult(
                SCNMatrix4MakeScale(scale, scale, 1),
                SCNMatrix4MakeTranslation(0, progress, 0)
            )
            floorMaterial.diffuse.contentsTransform = transform
        }
        
        let repeatScroll = SCNAction.repeatForever(scrollOneCycle)
        floorNode.runAction(repeatScroll)
        
        if config.showShadow {
            let shadowPlane = SCNPlane(width: 10, height: 10)
            let shadowMaterial = SCNMaterial()
            shadowMaterial.diffuse.contents = UIColor.clear
            shadowMaterial.lightingModel = .shadowOnly
            shadowMaterial.writesToDepthBuffer = false
            shadowPlane.materials = [shadowMaterial]
            
            let shadowNode = SCNNode(geometry: shadowPlane)
            shadowNode.name = "ShadowPlane"
            shadowNode.eulerAngles.x = -.pi / 2
            shadowNode.position = SCNVector3(0, 0.001, 0)
            shadowNode.castsShadow = false
            
            scene.rootNode.addChildNode(shadowNode)
        }
    }
    
    private static func setupSolidColorFloor(in scene: SCNScene, config: CharacterSceneConfig) {
        let floorGeometry = SCNPlane(width: 100, height: 100)
        
        let floorMaterial = SCNMaterial()
        floorMaterial.diffuse.contents = config.floorColor
        floorMaterial.lightingModel = .constant
        floorMaterial.writesToDepthBuffer = true
        floorMaterial.readsFromDepthBuffer = true
        floorGeometry.materials = [floorMaterial]
        
        let floorNode = SCNNode(geometry: floorGeometry)
        floorNode.name = "Floor"
        floorNode.eulerAngles.x = -.pi / 2
        floorNode.position = SCNVector3(0, 0, 0)
        floorNode.castsShadow = false
        
        scene.rootNode.addChildNode(floorNode)
        
        if config.showShadow {
            let shadowPlane = SCNPlane(width: 100, height: 100)
            let shadowMaterial = SCNMaterial()
            shadowMaterial.diffuse.contents = UIColor.clear
            shadowMaterial.lightingModel = .shadowOnly
            shadowMaterial.writesToDepthBuffer = false
            shadowPlane.materials = [shadowMaterial]
            
            let shadowNode = SCNNode(geometry: shadowPlane)
            shadowNode.name = "ShadowPlane"
            shadowNode.eulerAngles.x = -.pi / 2
            shadowNode.position = SCNVector3(0, 0.001, 0)
            shadowNode.castsShadow = false
            
            scene.rootNode.addChildNode(shadowNode)
        }
    }
    
    private static func setupLighting(in scene: SCNScene, tracking targetNode: SCNNode) {
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.intensity = 1000
        directionalLight.color = UIColor.white
        directionalLight.castsShadow = true
        directionalLight.shadowMode = .deferred
        directionalLight.shadowColor = UIColor.black.withAlphaComponent(0.5)
        directionalLight.shadowRadius = 3.0
        directionalLight.shadowSampleCount = 8
        directionalLight.shadowMapSize = CGSize(width: 2048, height: 2048)
        directionalLight.orthographicScale = 5
        directionalLight.zNear = 0.1
        directionalLight.zFar = 100
        
        let lightNode = SCNNode()
        lightNode.name = "DirectionalLight"
        lightNode.light = directionalLight
        lightNode.position = SCNVector3(x: -5, y: 10, z: 5)
        lightNode.eulerAngles = SCNVector3(x: -.pi / 3, y: -.pi / 4, z: 0)
        
        scene.rootNode.addChildNode(lightNode)
        
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 400
        ambientLight.color = UIColor.white
        
        let ambientNode = SCNNode()
        ambientNode.name = "AmbientLight"
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
    }
    
    private static func enableShadowCasting(on node: SCNNode) {
        node.castsShadow = true
        for child in node.childNodes {
            enableShadowCasting(on: child)
        }
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
