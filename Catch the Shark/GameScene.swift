//
//  GameScene.swift
//  Catch the Shark
//
//  Created by DDDD on 01/08/2020.
//  Copyright © 2020 MeerkatWorks. All rights reserved.
//

import AVFoundation
import SpriteKit

enum ForceSharks {
    case never, always, random
}

enum SequenceType: CaseIterable {
    case oneNoShark, one, twoWithOneShark, two, three, four, chain, fastChain
}

class GameScene: SKScene {
    
    var gameScore: SKLabelNode!
    
    var score = 0 {
        didSet {
            gameScore.text = "Score: \(score)"
        }
    }
    
    var livesImages = [SKSpriteNode]()
    var lives = 3
    
    var activeSlice1: SKShapeNode!
    var activeSlice2: SKShapeNode!
    
    var activeSlicePoints = [CGPoint]()
    var isSwooshSoundActive = false
    var activeEnemies = [SKSpriteNode]()
    var sharkSoundEffect: AVAudioPlayer?
    
    var popupTime = 0.9 //amount of time waiting from the enemy destroyed and the one created
    var sequence = [SequenceType]()
    var sequencePosition = 0 //player position relative to sequence array
    var chainDelay = 3.0 //time to wait until creating a new enemy
    var nextSequenceQueued = true
    
    override func didMove(to view: SKView) {
        
        let background = SKSpriteNode(imageNamed: "sea_background")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1 // in the back
        addChild(background) // adding background
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -6) //-9.8 world default
        physicsWorld.speed = 0.85 // see if this works for underwater
        
        
        createScore()
        createLives()
        createSlices()
    }
    
    
    func createScore() {
        
        gameScore = SKLabelNode(fontNamed: "Chalkduster")
        gameScore.horizontalAlignmentMode = .left
        gameScore.fontSize = 48
        addChild(gameScore)
        
        gameScore.position = CGPoint(x: 8, y: 8)
        score = 0 //triggering the didSet
    }
    
    func  createLives() {
        
        for i in 0..<3 {
            let spriteNode = SKSpriteNode(imageNamed: "Life")
            spriteNode.position = CGPoint(x: CGFloat(834 + (i * 70)), y: 720)
            addChild(spriteNode)
            livesImages.append(spriteNode)
        }
    }
    
    func createSlices() {
        
        activeSlice1 = SKShapeNode()
        activeSlice1.zPosition = 2
        activeSlice1.strokeColor = UIColor(red: 72, green: 219, blue: 251, alpha: 1)
        activeSlice1.lineWidth = 9
        
        activeSlice2 = SKShapeNode()
        activeSlice2.zPosition = 3
        activeSlice2.strokeColor = UIColor(red: 84, green: 160, blue: 255, alpha: 1)
        activeSlice2.lineWidth = 5
        
        addChild(activeSlice1)
        addChild(activeSlice2)
        
        /* see these pallettes, all are blue-ish
         rgb(46, 134, 222)
         rgb(72, 219, 251)
         rgb(84, 160, 255)
         generator at https://flatuicolors.com/palette/ca */
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        activeSlicePoints.append(location)
        redrawActiveSlice()
        
        if !isSwooshSoundActive {
            playSwooshSound()
        }
    }
    
    func playSwooshSound() {
        isSwooshSoundActive = true
        
        let randomNumber = Int.random(in: 1...3)
        let soundName = "swoosh\(randomNumber).caf"
        
        let swooshSound = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        //this ensure that no multiple sounds are played at once
        run(swooshSound) { [weak self] in
            self?.isSwooshSoundActive = false
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeSlice1.run(SKAction.fadeOut(withDuration: 0.25))
        activeSlice2.run(SKAction.fadeOut(withDuration: 0.25))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        activeSlicePoints.removeAll(keepingCapacity: true)
        
        let location = touch.location(in: self)
        activeSlicePoints.append(location)
        
        redrawActiveSlice()
        
        activeSlice1.removeAllActions()
        activeSlice2.removeAllActions()
        
        activeSlice1.alpha = 1
        activeSlice2.alpha = 2
    }
    
    // redrawing the sliced shapes
    func redrawActiveSlice() {
        
        if activeSlicePoints.count < 2 {
            activeSlice1.path = nil
            activeSlice2.path = nil
            return
        }
        
        if activeSlicePoints.count > 12 {
            activeSlicePoints.removeFirst(activeSlicePoints.count - 12)
        }
        
        let path = UIBezierPath()
        path.move(to: activeSlicePoints[0])
        
        for i in 1..<activeSlicePoints.count {
            path.addLine(to: activeSlicePoints[i])
        }
        
        activeSlice1.path = path.cgPath
        activeSlice2.path = path.cgPath
    }
    
    func createEnemy(forceSharks: ForceSharks = .random) {
        
        let enemy: SKSpriteNode
        
        var enemyType = Int.random(in: 1...10)
        
        if forceSharks == .never {
            enemyType = 1
        } else if forceSharks == .always {
            enemyType = 0
        }
        
        if enemyType == 0 {
            
            enemy = SKSpriteNode()
            enemy.zPosition = 1
            enemy.name = "sharkContainer"
            
            let sharkImage = SKSpriteNode(imageNamed: "shark")
            sharkImage.name = "shark"
            enemy.addChild(sharkImage)
            
            if sharkSoundEffect != nil {
                sharkSoundEffect?.stop()
                sharkSoundEffect = nil
            }
            
            if let path = Bundle.main.url(forResource: "slicingFuse", withExtension: ".caf") {
                if let sound = try? AVAudioPlayer(contentsOf: path) {
                    sharkSoundEffect = sound
                    sound.play()
                }
            }
            
            if let emitter = SKEmitterNode(fileNamed: "sliceFuse") {
                emitter.position = CGPoint(x: 76, y: 64)
                enemy.addChild(emitter)
            }
            
            
        } else {
            var randomImageNo = Int.random(in: 1...3)
            enemy = SKSpriteNode(imageNamed: "good\(randomImageNo)")
            run(SKAction.playSoundFileNamed("launch.caf", waitForCompletion: false))
            enemy.name = "enemy"
        }
        
        //the position of each creature will be here, theoretically
        
        
        
        let randomPosition = CGPoint(x: Int.random(in: 64...960), y: -128)
        enemy.position = randomPosition
        
        let randomAngularVelocity = CGFloat.random(in: -3...3)
        let randomXVelocity: Int
        
        if randomPosition.x < 256 {
            randomXVelocity = Int.random(in: 8...15)
        } else if randomPosition.x < 512 {
            randomXVelocity = Int.random(in: 3...5)
        } else if randomPosition.x < 768 {
            randomXVelocity = -Int.random(in: 3...5)
        } else {
            randomXVelocity = -Int.random(in: 8...15)
        }
        
        let randomYVelocity = Int.random(in: 24...32)
        
        
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 64)
        enemy.physicsBody?.velocity = CGVector(dx: randomXVelocity * 40, dy: randomYVelocity * 40)
        enemy.physicsBody?.angularVelocity = randomAngularVelocity
        enemy.physicsBody?.collisionBitMask = 0
        
        addChild(enemy)
        activeEnemies.append(enemy)
    }
    
    override func update(_ currentTime: TimeInterval) {
        var sharksOnScreenCount = 0
        
        for node in activeEnemies {
            if node.name == "sharkContainer" {
                sharksOnScreenCount += 1
                break
            }
        }
        
        if sharksOnScreenCount == 0 {
            // no sounds should be made, at the push sound should be stopped
            
            sharkSoundEffect?.stop()
            sharkSoundEffect = nil
        }
    }
    
    func tossEnemies() {
        popupTime *= 0.991
        chainDelay *= 0.99
        physicsWorld.speed *= 1.02
        
        let sequenceType = sequence[sequencePosition]
        
        switch sequenceType {
        case .oneNoShark:
            createEnemy(forceSharks: .never)
            
        case .one:
            createEnemy()
            
        case .twoWithOneShark:
            createEnemy(forceSharks: .never)
            createEnemy(forceSharks: .always)
            
        case .two:
            createEnemy()
            createEnemy()
            
        case .three:
            createEnemy()
            createEnemy()
            createEnemy()
            
        case .four:
            createEnemy()
            createEnemy()
            createEnemy()
            createEnemy()
            
        case .chain:
            createEnemy()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0)) {
                [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 2)) {
                [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 3)) {
                [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 4)) {
                [weak self] in self?.createEnemy() }
            
        case .fastChain:
            createEnemy()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0)) {
                [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 2)) {
                [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 3)) {
                [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 4)) {
                [weak self] in self?.createEnemy() }
        }
        sequencePosition += 1
        nextSequenceQueued = false
    }
}
