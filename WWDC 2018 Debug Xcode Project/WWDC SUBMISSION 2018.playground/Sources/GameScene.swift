import Foundation
import SpriteKit

public class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //Nodes
    private var ship: SKSpriteNode!

    private var life1: SKShapeNode!
    private var life2: SKShapeNode!
    private var life3: SKShapeNode!
    private var scoreLabel : SKLabelNode!
    
    private var booster1 : SKEmitterNode!
    private var booster2 : SKEmitterNode!
    private var booster3 : SKEmitterNode!
    
    //Scoring
    private var lives = 3
    private var score = 0

    //array of all contacts to be handled in the next frame
    var contactQueue = [SKPhysicsContact]()

    ////////////////////
    //MARK:Scene Setup//
    ////////////////////
    
    public override func sceneDidLoad() {
        size = CGSize(width: 700, height: 1000)
    }

    public override func didMove(to view: SKView) {
        //setup & start generating the song
        setupSong()
        generateSong()

        //add all the nodes
        setupNodes()
        
        //start w/ 3 lives
        lives = 3
        
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
    }
    
    //Sets up nodes at beginning of game
    func setupNodes() {
        //ship node
        ship = scene?.childNode(withName: "ship") as? SKSpriteNode
        ship.physicsBody = SKPhysicsBody(rectangleOf: ship.frame.size)
        ship.physicsBody!.collisionBitMask = PhysicsCategory.None
        ship.physicsBody!.categoryBitMask = PhysicsCategory.Ship
        ship.physicsBody!.contactTestBitMask = PhysicsCategory.Note
        ship.physicsBody!.affectedByGravity = false
        //ship.physicsBody!.isDynamic = false
        ship.zPosition = 100
        
        life1 = scene?.childNode(withName: "life1") as? SKShapeNode
        life2 = scene?.childNode(withName: "life2") as? SKShapeNode
        life3 = scene?.childNode(withName: "life3") as? SKShapeNode
        scoreLabel = scene?.childNode(withName: "score") as? SKLabelNode
        
        //ship booster effects
        let boosterPath = Bundle.main.path(forResource: "booster", ofType: "sks")!
        booster1 = NSKeyedUnarchiver.unarchiveObject(withFile: boosterPath) as! SKEmitterNode
 
        booster1.position.x = ship.position.x + 50
        booster1.position.y = ship.position.y - 30
        booster1.particleScale = 0.1
        booster1.targetNode = self
        
        scene?.addChild(booster1)
        
        booster2 = NSKeyedUnarchiver.unarchiveObject(withFile: boosterPath) as! SKEmitterNode
        
        booster2.position.x = ship.position.x - 50
        booster2.position.y = ship.position.y - 30
        booster2.particleScale = 0.1
        booster2.targetNode = self
        
        scene?.addChild(booster2)
        
        booster3 = NSKeyedUnarchiver.unarchiveObject(withFile: boosterPath) as! SKEmitterNode
        
        booster3.position.x = ship.position.x
        booster3.position.y = ship.position.y - 30
        booster3.particleScale = 0.3
        booster3.targetNode = self
        
        scene?.addChild(booster3)
        
        //stars emitter
        let starsPath = Bundle.main.path(forResource: "stars", ofType: "sks")!
        let stars = NSKeyedUnarchiver.unarchiveObject(withFile: starsPath) as! SKEmitterNode
        
        stars.position.y = 500
        stars.targetNode = self
        
        scene?.addChild(stars)
        
        //asteroid emiiter
        let asteroidsPath = Bundle.main.path(forResource: "asteroid", ofType: "sks")!
        let asteroids = NSKeyedUnarchiver.unarchiveObject(withFile: asteroidsPath) as! SKEmitterNode
        
        asteroids.position.y = 500
        asteroids.targetNode = self
        
        scene?.addChild(asteroids)
        
    }

    func shootBeam() {
        //beam is invisible, but is the node that tracks collisions
        let beam = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 15, height: 15))
        beam.fillColor = .clear
        beam.strokeColor = .clear
        
        //bulletPath is the emitter that makes the bullet look like it does
        let bulletPath = Bundle.main.path(forResource: "bullet", ofType: "sks")!
        let bullet = NSKeyedUnarchiver.unarchiveObject(withFile: bulletPath) as! SKEmitterNode

        //assign physics body properties
        beam.physicsBody = SKPhysicsBody(rectangleOf: beam.frame.size)
        beam.physicsBody!.isDynamic = true
        beam.physicsBody!.affectedByGravity = false
        beam.physicsBody!.categoryBitMask = PhysicsCategory.Bullet
        beam.physicsBody!.collisionBitMask = PhysicsCategory.None
        beam.physicsBody!.contactTestBitMask = PhysicsCategory.Note
        beam.physicsBody!.usesPreciseCollisionDetection = true
        
        //change to CGPoint later; easier to read this wy for now
        beam.position.y = ship.position.y + 50
        beam.position.x = ship.position.x
        bullet.position.y = 7.5
        bullet.position.x = 7.5

        beam.addChild(bullet)
        scene?.addChild(beam)

        //shoot the bullet
        beam.physicsBody!.applyImpulse(CGVector(dx: 0.0, dy: 10.0))
    }

    public func prepareNoteForSpawn(note: String, octave: Int, length: Double) {
        
        let noteWidth = 50.00
        var noteHeight : Double
        var x: Double = 0

        //always start off assuming we have a note and not a delay, this will be proved otherwise in the switch statement
        var isNote = true
        
        //Based on the note we have, spawn it in at the correct x position
        switch note {
            case "C":
                x = noteWidth * -7
            case "D":
                x = noteWidth * -6
            case "E":
                x = noteWidth * -5
            case "F":
                x = noteWidth * -4
            case "G":
                x = noteWidth * -3
            case "A":
                x = noteWidth * -2
            case "B":
                x = noteWidth * -1
            case "C2":
                x = noteWidth * 0
            case "D2":
                x = noteWidth
            case "E2":
                x = noteWidth * 2
            case "F2":
                x = noteWidth * 3
            case "G2":
                x = noteWidth * 4
            case "A2":
                x = noteWidth * 5
            case "B2":
                x = noteWidth * 6
            case "N/A":
                x = 0
                isNote = false
            default:
                isNote = false
                print("this shouldn't happen")
        }

        //is note checks if the note being created is not a rest
        if(isNote) {
            //convert length (in beats) into both height of note (1 beat is 100px in length)
            noteHeight = length * Double(100)
            
            //add the note to the scene
            addNoteWithOptions(height: CGFloat(noteHeight), xPosition: CGFloat(x), in: self)
       }
    }
    
    //Spawns new note to the scene
    public func addNoteWithOptions(height: CGFloat, xPosition: CGFloat, in scene: SKScene) {
        
        let newNote = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 43.75, height: height))
        
        newNote.fillColor = .white
        //center y is set to length so that the end of the collision works properly
        newNote.physicsBody = SKPhysicsBody(rectangleOf: newNote.frame.size)
        
        newNote.physicsBody!.isDynamic = false
        newNote.physicsBody!.affectedByGravity = false
        newNote.physicsBody!.usesPreciseCollisionDetection = true
        
        newNote.physicsBody!.categoryBitMask = PhysicsCategory.Note
        newNote.physicsBody!.collisionBitMask = PhysicsCategory.None
        newNote.physicsBody!.contactTestBitMask = PhysicsCategory.Ship
        
        //change to CGPoint later; easier to read this way for now
        newNote.position.x = CGFloat(xPosition)
        newNote.position.y = 500
        
        scene.addChild(newNote)
        
        //start moving down the screen
        let move = SKAction.moveBy(x: 0, y: -1500, duration: 15/3)
        newNote.run(move)
        
        //to maintain performance, delete note nodes after they leave the screen.
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            newNote.removeFromParent()
        }
    }

    /////////////////////////////
    //MARK:Physics and Contacts//
    /////////////////////////////

    func processContacts(forUpdate currentTime: CFTimeInterval) {
        for contact in contactQueue {
            handle(contact)
            
            if let index = contactQueue.index(of: contact) {
                contactQueue.remove(at: index)
            }
        }
    }
    
    public func handle(_ contact: SKPhysicsContact) {
        if contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil {
            return
        }
        
        let nodeBitmasks = [contact.bodyA.categoryBitMask, contact.bodyB.categoryBitMask]
        
        //bullet hit a note:
        if nodeBitmasks.contains(PhysicsCategory.Note) && nodeBitmasks.contains(PhysicsCategory.Bullet) {
            //access the length of the note we hit to play the correct sound
            if let note = contact.bodyA.node {
                let length = Double((10 * round(note.frame.size.height / 10.0)))
                Sound(input: Double(note.position.x), length: length).playSound(in: self)
            }
            
            score += 1
            scoreLabel.text = "\(score)"
          
            contact.bodyA.node!.removeFromParent()
            contact.bodyB.node!.removeFromParent()
        }
        
        //a note hit the ship:
        if nodeBitmasks.contains(PhysicsCategory.Ship) && nodeBitmasks.contains(PhysicsCategory.Note) {
            //adjust lives
            if (lives > 1) {
                lives = lives - 1
                if lives == 2 {
                   life3.removeFromParent()
                } else if lives == 1 {
                   life2.removeFromParent()
                }
            } else {
                life1.removeFromParent()
                print("he DEAD")
            }
        }
    }
    
    public func didBegin(_ contact: SKPhysicsContact) {
        contactQueue.append(contact)
    }

    //////////////////////////////
    //MARK: Mouse Event Handlers//
    //////////////////////////////
 
    override public func mouseMoved(with event: NSEvent) {
        let location = event.location(in:self)
        // move ship to mouse (only x values)
        ship.position.x = location.x
        booster1.position.x = ship.position.x + 50
        booster1.position.y = ship.position.y
        booster2.position.x = ship.position.x - 50
        booster2.position.y = ship.position.y
        booster3.position.x = ship.position.x
        booster3.position.y = ship.position.y
    }
    
    public override func mouseDown(with event: NSEvent) {
        shootBeam()
    }
 
    ////////////////////
    //MARK: Song Stuff//
    ////////////////////

    let song = Song()
    //var songBPM = 120

    //this function adds all the notes to the array within the Song class
    public func setupSong() {
        // .quarter = .25, half = .5, and so on; fix later
        
        song.addNote(note: "D", octave: 1, length: 0.25)
         song.addDelay(length: 0.5)
        song.addNote(note: "D", octave: 1, length: 0.25)
         song.addDelay(length: 0.5)
        song.addNote(note: "E", octave: 1, length: 0.25)
         song.addDelay(length: 0.5)
        song.addNote(note: "D", octave: 1, length: 0.25)
        song.addDelay(length: 0.5)
        song.addNote(note: "G", octave: 1, length: 0.25)
        song.addDelay(length: 0.5)
        song.addNote(note: "F", octave: 1, length: 0.5)
        song.addDelay(length: 0.5)
        song.addNote(note: "D", octave: 1, length: 0.25)
        song.addDelay(length: 0.5)
        song.addNote(note: "D", octave: 1, length: 0.25)
        song.addDelay(length: 0.5)
        song.addNote(note: "E", octave: 1, length: 0.25)
        song.addDelay(length: 0.5)
        song.addNote(note: "D", octave: 1, length: 0.25)
        song.addDelay(length: 0.5)
        song.addNote(note: "A", octave: 1, length: 0.25)
        song.addDelay(length: 0.5)
        song.addNote(note: "G", octave: 1, length: 0.5)
        song.addDelay(length: 0.5)
        
        /*for _ in 0...5 {
            song.addNote(note: "A", octave: 1, length: 0.25)
            song.addDelay(length: 0.25)
            song.addNote(note: "C", octave: 1, length: 0.5)
            song.addDelay(length: 0.25)
            song.addNote(note: "D", octave: 1, length: 0.25)
            song.addDelay(length: 0.25)
            song.addNote(note: "E", octave: 1, length: 0.25)
            song.addDelay(length: 0.25)
            song.addNote(note: "F", octave: 1, length: 0.25)
            song.addDelay(length: 0.25)
            song.addNote(note: "A2", octave: 1, length: 0.25)
            song.addDelay(length: 0.25)
            song.addNote(note: "C2", octave: 1, length: 0.5)
            song.addDelay(length: 0.25)
            song.addNote(note: "D2", octave: 1, length: 0.25)
            song.addDelay(length: 0.25)
            song.addNote(note: "E2", octave: 1, length: 0.25)
            song.addDelay(length: 0.25)
            song.addNote(note: "F2", octave: 1, length: 0.25)
            song.addDelay(length: 0.25)
        }*/
    }

    var i = -1
    
    //this function takes the array of notes from the Song class and prepares to spawn them into the scene
    public func generateSong() {
        i = i + 1
        if i < (song.songArray.count - 1) {
            if ((song.songArray[i]).0) == "N/A" {
                //delay the next iteration by delay amount
                delay(Double((song.songArray[i]).2)) {
                    self.generateSong()
                }
            } else {
                //spawn note
                prepareNoteForSpawn(note: ((song.songArray[i]).0), octave: ((song.songArray[i]).1), length: ((song.songArray[i]).2))
                //delay the next iteration by length of not playing
                delay(Double((song.songArray[i]).2)) {
                    self.generateSong()
                }
            }
        }
    }
    
    ///////////////////////
    //MARK: Update Frames//
    ///////////////////////
    
    public override func update(_ currentTime: TimeInterval) {
        processContacts(forUpdate: currentTime)
    }
}
