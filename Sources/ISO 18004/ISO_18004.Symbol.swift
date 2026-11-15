extension ISO_18004 {
    public struct Symbol: Sendable, Hashable {
        public let version: ISO_18004.Version
        public let level: ISO_18004.Correction.Level
        public let mode: ISO_18004.Mode
        public let mask: ISO_18004.Mask
        public let modules: [Bool]

        public init?(
            _ data: [UInt8],
            level: ISO_18004.Correction.Level,
            mode: ISO_18004.Mode? = nil,
            version: ISO_18004.Version? = nil,
            mask: ISO_18004.Mask? = nil
        ) {
            let mode = mode ?? ISO_18004.Mode(data)
            guard mode.holds(data),
                let smallest = ISO_18004.Version.all.first(where: { $0.capacity(mode, level) >= data.count })
            else { return nil }
            let version = version ?? smallest
            guard version >= smallest else { return nil }
            let codewords = Self.interleaved(
                Self.codewords(data, mode: mode, level: level, version: version),
                level: level,
                version: version
            )
            let drawn = Self.drawn(codewords, version: version)
            let candidates = mask.map { [$0] } ?? ISO_18004.Mask.all
            var chosen = candidates[0]
            var best: [Bool] = []
            var lowest = Int.max
            for candidate in candidates {
                let masked = Self.masked(drawn.dark, reserved: drawn.reserved, version: version, level: level, mask: candidate)
                let penalty = Self.penalty(masked, size: version.size)
                if penalty < lowest {
                    lowest = penalty
                    best = masked
                    chosen = candidate
                }
            }
            self.version = version
            self.level = level
            self.mode = mode
            self.mask = chosen
            self.modules = best
        }
    }
}

extension ISO_18004.Symbol {
    public static let quiet = 4

    public var size: Int { version.size }

    public var extent: Int { size + 2 * Self.quiet }

    public subscript(x: Int, y: Int) -> Bool { modules[y * size + x] }
}
