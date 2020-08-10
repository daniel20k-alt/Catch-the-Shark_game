//
//  GameScene.swift
//  Catch the Shark
//
//  Created by DDDD on 01/08/2020.
//  Copyright © 2020 MeerkatWorks. All rights reserved.
//

import AVFoundation
import SpriteKit

enum ForceEnemies {
    case never, always, random
}

enum SequenceType: CaseIterable {
    case oneNoEnemy, one, twoWithOneEnemy, two, three, four, chain, fastChain
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
    
    var activeSlice1: SKShapeNode! //TODO: modify this into water bubbles
    var activeSlice2: SKShapeNode! //TODO: modify this into water bubbles
    
    var activeSlicePoints = [CGPoint]()
    var isSwooshSoundActive = false
    var allActiveAnimals = [SKSpriteNode]()
    var enemiesSoundEffect: AVAudioPlayer? //to modify later, not sure if it should stay
    
    var popupTime = 0.9 //amount of time waiting from the enemy destroyed and the one created
    var sequence = [SequenceType]()
    var sequencePosition = 0 //player position relative to sequence array
    var chainDelay = 3.0 //time to wait until creating a new enemy
    var nextSequenceQueued = true
    
    var isGameEnded = false
    
    override func didMove(to view: SKView) {
        
        let randomizedBackground = Int.random(in: 1...2) //TODO: change second background dimensions, looks very bad
        let background = SKSpriteNode(imageNamed: "sea_background\(randomizedBackground)")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1 // in the back
        addChild(background)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -6) //-9.8 world default
        physicsWorld.speed = 0.85 // see if this works for underwater
        
        createScore()
        createLives()
        createSlices()
        
        sequence = [.oneNoEnemy, .two, .twoWithOneEnemy, .oneNoEnemy, .oneNoEnemy, .chain, .one, .four, .oneNoEnemy]
        
        for _ in 0...1000 {
            if let nextSequence = SequenceType.allCases.randomElement() {
                sequence.append(nextSequence)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            [weak self] in self?.tossEnemies()
        }
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
        //TODO: maybe modify color to be transparent or have water bubble particles instead
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
        guard isGameEnded == false else { return }
        
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        activeSlicePoints.append(location)
        redrawActiveSlice()
        
        //TODO: swoosh sound to be modified with a certain water sound
        if !isSwooshSoundActive {
            playSwooshSound()
        }
        
        let nodesAtPoint = nodes(at: location)
        
        for case let node as SKSpriteNode in nodesAtPoint {
            if node.name == "enemy" {
                
                //destroying the creatures
                if let emitter = SKEmitterNode(fileNamed: "waves") {
                    emitter.position = node.position
                    emitter.particleLifetime = 1
                    addChild(emitter)
                }
                
                node.name = ""
                node.physicsBody?.isDynamic = false
                
                let scaleOut = SKAction.scale(to: 0.001, duration: 0.3)
                let fadeOut = SKAction.fadeOut(withDuration: 0.2)
                let group = SKAction.group([scaleOut, fadeOut])
                
                //aici poate add emitter cu waves
                
                let seq = SKAction.sequence([group, .removeFromParent()])
                node.run(seq)
                
                score += 1
                
                if let index = allActiveAnimals.firstIndex(of: node) {
                    allActiveAnimals.remove(at: index)
                }
                
                run(SKAction.playSoundFileNamed("splash_small.wav", waitForCompletion: false))
                
            } else if node.name == "fishContainer" {
                
                
                guard let fishContainer = node.parent as? SKSpriteNode else {
                    continue }
                
                //TODO: see maybe this emitter to move to enemies
                
                if let emitter = SKEmitterNode(fileNamed: "waves") {
                    emitter.position = fishContainer.position
                    addChild(emitter)
                }
                
                node.name = ""
                fishContainer.physicsBody?.isDynamic = false
                
                let scaleOut = SKAction.scale(to: 0.001, duration: 0.2)
                let fadeOut = SKAction.fadeOut(withDuration: 0.2)
                let group = SKAction.group([scaleOut, fadeOut])
                
                let seq = SKAction.sequence([group, .removeFromParent()])
                
                if let index = allActiveAnimals.firstIndex(of: fishContainer) {
                    allActiveAnimals.remove(at: index)
                }
                
                run(SKAction.playSoundFileNamed("splash.wav", waitForCompletion: false))
                
                endGame(triggeredByFish: true)
            }
        }
    }
    
    func endGame(triggeredByFish: Bool) {
        guard isGameEnded == false else { return }
        
        isGameEnded = true
        physicsWorld.speed = 0
        isUserInteractionEnabled = false
        
        enemiesSoundEffect?.stop()
        enemiesSoundEffect = nil
        
        if triggeredByFish {
            livesImages[0].texture = SKTexture(imageNamed: "LifeGone")
            livesImages[1].texture = SKTexture(imageNamed: "LifeGone")
            livesImages[2].texture = SKTexture(imageNamed: "LifeGone")
        }
        
        //TODO: make a label appear on the screen which shows that the game is over, and allows user to choose to restart
    }
    
    func playSwooshSound() {
        isSwooshSoundActive = true
        
        //TODO: water sound still has to be modified, doesn't sound right
        let soundName = "water_flow_tide.mp3"
        
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
    
    func createEnemy(forceFish: ForceEnemies = .random) {
        
        let enemy: SKSpriteNode
        
        var animalType = Int.random(in: 1...10)
        
        if forceFish == .never {
            animalType = 1
        } else if forceFish == .always {
            animalType = 0
        }
        
        if animalType == 0 {
            
            enemy = SKSpriteNode()
            enemy.zPosition = 1
            enemy.name = "fishContainer"
            
            let fishImage = SKSpriteNode(imageNamed: "good1")
            fishImage.name = "fishContainer"
            enemy.addChild(fishImage)
            
            if enemiesSoundEffect != nil {
                enemiesSoundEffect?.stop()
                enemiesSoundEffect = nil
            }
        
    } else {
    var randomImageNo = Int.random(in: 1...6)
    enemy = SKSpriteNode(imageNamed: "bad\(randomImageNo)")
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
    allActiveAnimals.append(enemy)
}

func substractLife () {
    lives -= 1
    
    run(SKAction.playSoundFileNamed("wrong.caf", waitForCompletion: false))
    
    var life: SKSpriteNode
    
    if lives == 2 {
        life = livesImages[0]
    } else if lives == 1 {
        life = livesImages[1]
    } else {
        life = livesImages[2]
        endGame(triggeredByFish: false)
    }
    
    life.texture = SKTexture(imageNamed: "LifeGone")
    life.xScale = 1.3
    life.yScale = 1.3
    life.run(SKAction.scale(to: 1, duration: 0.1))
    
    
    
}

override func update(_ currentTime: TimeInterval) {
    
    if allActiveAnimals.count > 0 {
        for (index, node) in allActiveAnimals.enumerated().reversed() {
            if node.position.y < -140 {
                node.removeAllActions()
                
                if node.name == "enemy" {
                    node.name = ""
                    substractLife()
                    
                    node.removeFromParent()
                    allActiveAnimals.remove(at: index)
                    
                } else if node.name == "fishContainer" {
                    node.name = ""
                    node.removeFromParent()
                    allActiveAnimals.remove(at: index)
                }
            }
        }
    } else {
        if !nextSequenceQueued {
            DispatchQueue.main.asyncAfter(deadline: .now() + popupTime) {
                [weak self] in self?.tossEnemies()
            }
            nextSequenceQueued = true
        }
    }
    
    var fishOnScreenCount = 0
    
    for node in allActiveAnimals {
        if node.name == "fishContainer" {
            fishOnScreenCount += 1
            break
        }
    }
    
    if fishOnScreenCount == 0 {
        // no sounds should be made, at the push sound should be stopped
        
        enemiesSoundEffect?.stop()
        enemiesSoundEffect = nil
    }
}

func tossEnemies() {
    guard isGameEnded == false else { return }
    
    popupTime *= 0.991
    chainDelay *= 0.99
    physicsWorld.speed *= 1.02
    
    let sequenceType = sequence[sequencePosition]
    
    switch sequenceType {
    case .oneNoEnemy:
        createEnemy(forceFish: .never)
        
    case .one:
        createEnemy()
        
    case .twoWithOneEnemy:
        createEnemy(forceFish: .never)
        createEnemy(forceFish: .always)
        
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
