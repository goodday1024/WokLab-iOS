import SwiftUI
import CoreMotion
import Combine

@MainActor final class KitchenEngine: ObservableObject {
    let recipe: Recipe
    @Published var index = 0
    @Published var elapsed = 0.0
    @Published var exposure = 0.0
    @Published var temperature = 22.0
    @Published var flame = 0.65
    @Published var speed = 1.0
    @Published var running = false
    @Published var done = false
    @Published var actions = 0.0
    @Published var burn = 0.0
    @Published var results: [StageResult] = []
    @Published var motionStatus = "动作感应待启动"
    @Published var added = false
    @Published var water = 0.0
    let motion = CMMotionManager()
    let scene = KitchenScene(size: CGSize(width: 380, height: 380))
    var timer: AnyCancellable?
    var lastTick = Date()
    var lastToss = Date.distantPast
    var heatError = 0.0
    var step: CookingStep { recipe.steps[index] }
    var hot: Bool { ["炒锅","煮锅"].contains(step.station) }
    var ready: Bool { added && (hot || actions >= 6) }
    var score: Int { results.isEmpty ? 0 : Int(results.map(\.score).reduce(0,+) / Double(results.count)) }
    init(recipe: Recipe) {
        self.recipe = recipe
        scene.scaleMode = .resizeFill
        scene.engine = self
        configure()
    }
    func configure() {
        elapsed=0; exposure=0; actions=0; burn=0; heatError=0; added=false
        water = step.station == "煮锅" ? 1 : 0
        scene.configure(station: step.station, ingredients: step.ingredients, action: step.action)
    }
    func start() {
        guard timer == nil else { return }
        lastTick = Date()
        timer = Timer.publish(every: 1.0/30, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        if motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval = 1.0/30
            motion.startDeviceMotionUpdates()
            motionStatus = "倾斜手机移锅 · 轻抬手腕颠锅"
        } else { motionStatus = "感应不可用，可使用颠锅按钮" }
    }
    func stop() { timer?.cancel(); timer=nil; motion.stopDeviceMotionUpdates(); running=false }
    func tick() {
        let now = Date(); let real = min(0.1, now.timeIntervalSince(lastTick)); lastTick=now
        guard running && !done else { return }
        if let m=motion.deviceMotion {
            scene.tilt(x: m.gravity.x, y: m.gravity.y)
            let impulse = abs(m.userAcceleration.z) + abs(m.rotationRate.x)*0.18
            if impulse > 1.05 && now.timeIntervalSince(lastToss)>0.85 && hot {
                toss()
            }
        }
        let dt = real * speed
        if hot {
            let target = water > 0.05 ? 22 + flame*85 : 22 + flame*240
            temperature += (target-temperature)*min(1,dt/14)
            if added {
                elapsed += dt
                let reference = step.station == "煮锅" ? 98.0 : 22 + step.heat*240
                exposure += dt * CookingMath.thermalRate(temperature: temperature, reference: reference)
                heatError += abs(flame-step.heat)*dt
                if temperature>185 && actions < elapsed/14 { burn += dt*0.0015 }
                if exposure > step.seconds+step.tolerance { burn += dt*0.001 }
                water=max(0,water-dt*max(0,temperature-85)*0.00003)
            }
        } else if added { elapsed += dt }
        scene.renderState(progress: exposure/max(1,step.seconds), burn: burn, temperature: temperature, water: water)
    }
    func add() { guard !added else { return }; added=true; running=true; scene.addFood() }
    func interact(distance: Double) {
        guard running && added else { return }
        actions += min(0.45, distance/120)
    }
    func toss() {
        guard running && added && hot && step.station == "炒锅" else { return }
        guard Date().timeIntervalSince(lastToss)>0.6 else { return }
        lastToss=Date(); actions += 1; scene.toss()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    func finishStep() {
        guard ready else { return }
        let measured = hot ? exposure : elapsed
        let tq = CookingMath.timeQuality(elapsed: measured, ideal: step.seconds, tolerance: step.tolerance)
        let hq = hot ? max(0,1-heatError/max(1,elapsed)*2.5) : 1
        let needed = hot ? (step.station == "煮锅" ? 2.0 : max(3,elapsed/16)) : 6
        results.append(StageResult(title: step.title, time: tq, heat: hq, technique: min(1,actions/needed), burn: burn))
        if index+1 == recipe.steps.count {
            done=true; running=false
            let key="best_"+recipe.id
            UserDefaults.standard.set(max(score, UserDefaults.standard.integer(forKey:key)), forKey:key)
        } else { index += 1; configure() }
    }
}
