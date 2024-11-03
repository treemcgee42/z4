
class WindowState {
    private var _windowSize: Size<Int>
    var windowSizeId: PropertyId
    var windowSize: Size<Int> {
        set {
            self._windowSize = newValue
            for (index, reactor) in self.reactors.enumerated().reversed() {
                let removeReactor = reactor(self, self.windowSizeId)
                if removeReactor {
                    self.reactors.remove(at: index)
                }
            }
        }
        get {
            return self._windowSize
        }
    }

    private var _framebufferSize: Size<Int>
    var framebufferSizeId: PropertyId
    var framebufferSize: Size<Int> {
        set {
            self._framebufferSize = newValue
            for (index, reactor) in self.reactors.enumerated().reversed() {
                let removeReactor = reactor(self, self.framebufferSizeId)
                if removeReactor {
                    self.reactors.remove(at: index)
                }
            }
        }
        get {
            return self._framebufferSize
        }
    }

    typealias WindowStateReactor = (_ to: WindowState, _ changedPropertyId: PropertyId) -> Bool
    private var reactors: [WindowStateReactor]

    init() {
        var propertyId = 0

        self._windowSize = .init(width: 0, height: 0)
        self.windowSizeId = propertyId
        propertyId += 1

        self._framebufferSize = .init(width: 0, height: 0)
        self.framebufferSizeId = propertyId
        propertyId += 1

        self.reactors = []
    }

    func registerReactor(_ r: @escaping WindowStateReactor) {
        self.reactors.append(r)
    }
}
