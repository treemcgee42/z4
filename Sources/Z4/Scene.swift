
class Scene {
    var ticksPerSecond = 20
    var tickInterval = 0.05
    var tickAccumulator: Double = 0
    var elapsedTicks = 0

    func tick() {
        if elapsedTicks % ticksPerSecond == 0 {
            print("tick")
        }

        self.elapsedTicks += 1
    }

    func tick(deltaTime: Double) {
        self.tickAccumulator += deltaTime
        while self.tickAccumulator > self.tickInterval {
            self.tick()
            self.tickAccumulator -= tickInterval
        }
    }
}
