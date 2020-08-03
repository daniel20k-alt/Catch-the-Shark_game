//
//  GameScene.swift
//  Catch the Shark
//
//  Created by DDDD on 01/08/2020.
//  Copyright © 2020 MeerkatWorks. All rights reserved.
//

import SpriteKit

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
}
