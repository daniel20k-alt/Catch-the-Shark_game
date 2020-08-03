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
            let spriteNode = SKSpriteNode(imageNamed: "LifeGone")
            spriteNode.position = CGPoint(x: CGFloat(834 + (i * 70)), y: 720)
            addChild(spriteNode)
            livesImages.append(spriteNode)
        }
    }
    
    func createSlices() {
     
        activeSlice1 = SKShapeNode()
        activeSlice1.zPosition = 2
        activeSlice1.strokeColor = UIColor(red: 46, green: 134, blue: 222, alpha: 1)
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
}
