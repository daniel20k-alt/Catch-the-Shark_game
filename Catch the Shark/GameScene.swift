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
            let spriteNode = SKSpriteNode(imageNamed: "slicedLife")
            spriteNode.position = CGPoint(x: CGFloat(834 + (i * 70)), y: 720)
            addChild(spriteNode)
            livesImages.append(spriteNode)
        }
    }
    
    func createSlices() {
        
    }
    
    
}
