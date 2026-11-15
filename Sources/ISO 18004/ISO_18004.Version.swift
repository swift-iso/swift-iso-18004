extension ISO_18004 {
    public struct Version: Sendable, Hashable, Comparable {
        public let number: Int

        public init?(_ number: Int) {
            guard (1...40).contains(number) else { return nil }
            self.number = number
        }

        public static func < (lhs: Self, rhs: Self) -> Bool { lhs.number < rhs.number }
    }
}

extension ISO_18004.Version {
    public static let all: [Self] = (1...40).compactMap(Self.init)

    public var size: Int { number * 4 + 17 }
}
