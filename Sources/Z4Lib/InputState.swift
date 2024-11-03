
class InputState {
    private var _leftMouseButtonClick: Vec2f
    var leftMouseButtonClickId: PropertyId
    var leftMouseButtonClick: Vec2f {
        set {
            self._leftMouseButtonClick = newValue
            for (index, reactor) in self.reactors.enumerated().reversed() {
                let removeReactor = reactor(self, self.leftMouseButtonClickId)
                if removeReactor {
                    self.reactors.remove(at: index)
                }
            }
        }
        get {
            return self._leftMouseButtonClick
        }
    }

    typealias InputStateReactor = (_ to: InputState, _ changedPropertyId: PropertyId) -> Bool
    private var reactors: [InputStateReactor]

    init() {
        var propertyId = 0

        self._leftMouseButtonClick = .init(x: 0, y: 0)
        self.leftMouseButtonClickId = propertyId
        propertyId += 1

        self.reactors = []
    }

    func registerReactor(_ r: @escaping InputStateReactor) {
        self.reactors.append(r)
    }
}
