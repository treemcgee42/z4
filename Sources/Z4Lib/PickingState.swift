
class PickingState {
    private var _clickRay: Ray
    var clickRayId: PropertyId
    var clickRay: Ray {
        set {
            self._clickRay = newValue
            for (index, reactor) in self.reactors.enumerated().reversed() {
                let removeReactor = reactor(self, self.clickRayId)
                if removeReactor {
                    self.reactors.remove(at: index)
                }
            }
        }
        get {
            return self._clickRay
        }
    }

    typealias PickingStateReactor = (_ to: PickingState, _ changedPropertyId: PropertyId) -> Bool
    private var reactors: [PickingStateReactor]

    init() {
        var propertyId = 0

        self._clickRay = .init(origin: Vec3f(x: 0, y: 0, z: 0),
                               direction: Vec3f(x: 0, y: 0, z: 0))
        self.clickRayId = propertyId
        propertyId += 1

        self.reactors = []
    }

    func registerReactor(_ r: @escaping PickingStateReactor) {
        self.reactors.append(r)
    }
}
