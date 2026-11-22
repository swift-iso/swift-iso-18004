extension ISO.`18004` {
    public struct Mask: Sendable, Hashable {
        public let reference: Int

        public init?(_ reference: Int) {
            guard (0...7).contains(reference) else { return nil }
            self.reference = reference
        }
    }
}

extension ISO.`18004`.Mask {
    public static let all: [Self] = (0...7).compactMap(Self.init)

    func inverts(row i: Int, column j: Int) -> Bool {
        switch reference {
        case 0: (i + j) % 2 == 0
        case 1: i % 2 == 0
        case 2: j % 3 == 0
        case 3: (i + j) % 3 == 0
        case 4: (i / 2 + j / 3) % 2 == 0
        case 5: i * j % 2 + i * j % 3 == 0
        case 6: (i * j % 2 + i * j % 3) % 2 == 0
        default: ((i + j) % 2 + i * j % 3) % 2 == 0
        }
    }
}
