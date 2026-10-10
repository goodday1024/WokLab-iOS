import SpriteKit
import UIKit

@MainActor final class IngredientArt {
    static let shared = IngredientArt()
    private var cache: [Int: UIImage] = [:]
    private let atlas = UIImage(named: "Ingredients")?.cgImage
    func image(_ id: Int, prepared: Bool = false) -> UIImage {
        let key = id + (prepared ? 64 : 0)
        if let image=cache[key] { return image }
        guard let atlas = prepared ? UIImage(named: "Prepared")?.cgImage : atlas else { return UIImage() }
        let w=atlas.width/8, h=atlas.height/8
        let rect=CGRect(x:CGFloat((id%8)*w),y:CGFloat((id/8)*h),width:CGFloat(w),height:CGFloat(h))
        guard let crop=atlas.cropping(to:rect) else { return UIImage() }
        let image=UIImage(cgImage:crop); cache[key]=image; return image
    }
}

@MainActor final class KitchenScene: SKScene {
    weak var engine: KitchenEngine?
    private var food: [SKSpriteNode] = []
    private var ingredientIDs: [Int] = []
    private var station = "洗菜池"
    private var action = "wash"
    private var steam = SKEmitterNode()
    private let spatula = SKNode()
    private var lastPoint: CGPoint?
    private var lastEffect = 0.0
    private var surface: SKShapeNode?
    private var cutCount = 0
    override func didMove(to view: SKView) { backgroundColor = .clear }
    func configure(station: String, ingredients: [Int], action: String) {
        removeAllChildren(); food=[]; ingredientIDs=ingredients; self.station=station; self.action=action; cutCount=0
        backgroundColor = UIColor(red:0.94,green:0.92,blue:0.87,alpha:1)
        let center=CGPoint(x:size.width/2,y:size.height/2)
        let radius=min(size.width,size.height)*0.40
        let hot = station == "炒锅" || station == "煮锅"
        let bowl = SKShapeNode(circleOfRadius:radius)
        bowl.position=center; bowl.fillColor=hot ? UIColor(white:0.12,alpha:1) : UIColor(red:0.70,green:0.81,blue:0.82,alpha:1)
        bowl.strokeColor=hot ? UIColor(white:0.32,alpha:1) : .white; bowl.lineWidth=10
        if station == "砧板" || station == "备料台" {
            let board=SKShapeNode(rectOf:CGSize(width:radius*2.1,height:radius*1.8),cornerRadius:22)
            board.position=center; board.fillColor=UIColor(red:0.72,green:0.51,blue:0.31,alpha:1); board.strokeColor = .clear; addChild(board)
            for i in 0..<12 {
                let line=SKShapeNode(rectOf:CGSize(width:radius*1.8,height:1)); line.position=CGPoint(x:center.x,y:center.y-radius*0.7+CGFloat(i)*radius*0.12); line.fillColor=UIColor.brown.withAlphaComponent(0.25); line.strokeColor = .clear; addChild(line)
            }
        } else { addChild(bowl) }
        let boundary=CGPath(ellipseIn:CGRect(x:center.x-radius+15,y:center.y-radius+15,width:2*(radius-15),height:2*(radius-15)),transform:nil)
        physicsBody=SKPhysicsBody(edgeLoopFrom:boundary); physicsBody?.restitution=0.3
        physicsWorld.gravity = .zero
        let liquid=SKShapeNode(circleOfRadius:radius-12); liquid.position=center; liquid.fillColor=UIColor.cyan.withAlphaComponent(station == "煮锅" ? 0.16 : 0); liquid.strokeColor = .clear; addChild(liquid); surface=liquid
        let panHandle=SKShapeNode(rectOf:CGSize(width:38,height:90),cornerRadius:12); panHandle.fillColor=UIColor(white:0.23,alpha:1); panHandle.strokeColor = .clear; panHandle.position=CGPoint(x:center.x,y:30)
        if hot { addChild(panHandle) }
        steam=SKEmitterNode(); steam.particleTexture=particleTexture(); steam.position=center; steam.particleBirthRate=0; steam.particleLifetime=2; steam.particleLifetimeRange=1; steam.particleSpeed=28; steam.particleSpeedRange=15; steam.emissionAngle = .pi/2; steam.emissionAngleRange = .pi/3; steam.particlePositionRange=CGVector(dx:radius*1.2,dy:radius*0.7); steam.particleAlpha=0.22; steam.particleAlphaSpeed = -0.09; steam.particleScale=0.35; steam.particleScaleSpeed=0.35; steam.particleColorBlendFactor=1; steam.zPosition=20; addChild(steam)
        spatula.removeAllChildren()
        let handle=SKShapeNode(rectOf:CGSize(width:12,height:100),cornerRadius:5); handle.fillColor=UIColor(red:0.50,green:0.29,blue:0.14,alpha:1); handle.strokeColor = .clear; handle.position.y = -50
        let head=SKShapeNode(rectOf:CGSize(width:45,height:40),cornerRadius:8); head.fillColor=UIColor(white:0.77,alpha:1); head.strokeColor = .white
        spatula.addChild(handle); spatula.addChild(head); spatula.position=CGPoint(x:center.x+65,y:center.y-55); spatula.zPosition=25; spatula.isHidden = !hot; addChild(spatula)
    }
    func particleTexture() -> SKTexture {
        let renderer=UIGraphicsImageRenderer(size:CGSize(width:32,height:32))
        return SKTexture(image:renderer.image { ctx in
            UIColor.white.setFill(); ctx.cgContext.fillEllipse(in:CGRect(x:2,y:2,width:28,height:28))
        })
    }
    func addFood() {
        let count=(station == "砧板" || station == "洗菜池") ? 9 : 27
        for i in 0..<count {
            let id=ingredientIDs[i % max(1,ingredientIDs.count)]
            let node=SKSpriteNode(texture:SKTexture(image:IngredientArt.shared.image(id, prepared: station != "洗菜池" && station != "砧板")))
            node.size=CGSize(width:station == "洗菜池" ? 56 : 38,height:station == "洗菜池" ? 56 : 38)
            let a=Double(i)*2.399; let r=sqrt(Double(i+1)/Double(count))*Double(min(size.width,size.height))*0.27
            node.position=CGPoint(x:size.width/2+CGFloat(cos(a)*r),y:size.height/2+CGFloat(sin(a)*r))
            node.userData = ["ingredient": id]
            node.zRotation=CGFloat(a); node.zPosition=5
            node.physicsBody=SKPhysicsBody(circleOfRadius:12); node.physicsBody?.mass=0.03; node.physicsBody?.linearDamping=2; node.physicsBody?.angularDamping=2; node.physicsBody?.restitution=0.25
            addChild(node); food.append(node)
        }
    }
    func tilt(x: Double,y: Double) { physicsWorld.gravity=CGVector(dx:x*8,dy:y*4) }
    func toss() {
        for node in food {
            node.physicsBody?.applyImpulse(CGVector(dx:Double.random(in: -0.9...0.9),dy:Double.random(in:0.5...1.7)))
            node.run(.sequence([.group([.scale(to:1.35,duration:0.2),.rotate(byAngle:.pi,duration:0.3)]),.scale(to:1,duration:0.28)]))
        }
    }
    func renderState(progress: Double,burn: Double,temperature: Double,water: Double) {
        let brown=UIColor(red:0.53,green:0.29,blue:0.08,alpha:1)
        for node in food {
            let id=node.userData?["ingredient"] as? Int ?? 0
            let cooked: UIColor = [16,17,18,20,21,22,23,56].contains(id) ? UIColor(red:0.73,green:0.56,blue:0.39,alpha:1) : id == 19 ? UIColor(red:1,green:0.51,blue:0.34,alpha:1) : [4,5,6,7,10,36].contains(id) ? UIColor(red:0.3,green:0.46,blue:0.13,alpha:1) : id == 1 ? UIColor(red:1,green:0.79,blue:0.15,alpha:1) : brown
            node.color=burn>0.25 ? UIColor(white:0.07,alpha:1) : cooked
            node.colorBlendFactor=CGFloat(min(0.85,max(0,progress*0.40+burn)))
        }
        steam.particleBirthRate=CGFloat(temperature>80 ? min(25,(temperature-80)*0.2) : 0)
        steam.particleColor=burn>0.25 ? .darkGray : .white
        surface?.fillColor=UIColor(red:0.61,green:0.74,blue:0.73,alpha:water>0.05 ? 0.25 : 0.02)
        if water>0.05 && temperature>88 && elapsedTime-lastEffect>0.1 {
            lastEffect=elapsedTime
            let bubble=SKShapeNode(circleOfRadius:CGFloat.random(in:2...6)); bubble.strokeColor=UIColor.white.withAlphaComponent(0.6); bubble.position=CGPoint(x:size.width/2+CGFloat.random(in: -80...80),y:size.height/2+CGFloat.random(in: -80...80)); bubble.zPosition=6; addChild(bubble)
            bubble.run(.sequence([.group([.scale(to:1.8,duration:0.5),.fadeOut(withDuration:0.5)]),.removeFromParent()]))
        }
    }
    private var elapsedTime=0.0
    override func update(_ currentTime: TimeInterval) { elapsedTime=currentTime }
    override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent?) { lastPoint=touches.first?.location(in:self) }
    override func touchesMoved(_ touches:Set<UITouch>,with event:UIEvent?) {
        guard let point=touches.first?.location(in:self),let previous=lastPoint,let engine, engine.running && engine.added else { return }
        let dx=point.x-previous.x,dy=point.y-previous.y
        let distance=hypot(dx,dy); lastPoint=point
        guard distance>1 else { return }
        guard hypot(point.x-size.width/2,point.y-size.height/2) < min(size.width,size.height)*0.43 else { return }
        let contacts = food.filter { hypot($0.position.x-point.x,$0.position.y-point.y)<65 }
        guard !contacts.isEmpty else { return }
        engine.interact(distance:Double(distance))
        spatula.position=point
        for node in food where hypot(node.position.x-point.x,node.position.y-point.y)<65 {
            node.physicsBody?.applyImpulse(CGVector(dx:dx*0.015,dy:dy*0.015)); node.physicsBody?.applyAngularImpulse(0.002)
            if station == "砧板" && distance>5 {
                let id=node.userData?["ingredient"] as? Int ?? 0
                node.texture=SKTexture(image:IngredientArt.shared.image(id,prepared:true))
                node.xScale=max(0.6,node.xScale-0.012); node.yScale=max(0.6,node.yScale-0.012)
            }
        }
        if station == "洗菜池" || station == "砧板" {
            let mark=SKShapeNode(circleOfRadius:station == "洗菜池" ? 8 : 2); mark.fillColor=station == "洗菜池" ? .white : .brown; mark.strokeColor = .clear; mark.alpha=0.6; mark.position=point; mark.zPosition=18; addChild(mark); mark.run(.sequence([.fadeOut(withDuration:0.4),.removeFromParent()]))
        }
    }
    override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?) { lastPoint=nil }
}
