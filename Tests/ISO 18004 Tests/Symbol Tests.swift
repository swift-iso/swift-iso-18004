import Testing

@testable import ISO_18004

enum `ISO.18004.Symbol Tests` {}

extension `ISO.18004.Symbol Tests` {
    @Suite struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

extension `ISO.18004.Symbol Tests`.Test.Unit {
    @Test
    func `the annex example 01234567 at 1-M gives the standard's data and error correction codewords`() throws {
        let version = try #require(ISO.`18004`.Version(1))
        let data = ISO.`18004`.Symbol.codewords(Array("01234567".utf8), mode: .numeric, level: .medium, version: version)
        #expect(data == [0x10, 0x20, 0x0C, 0x56, 0x61, 0x80, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11])
        let all = ISO.`18004`.Symbol.interleaved(data, level: .medium, version: version)
        #expect(Array(all.suffix(10)) == [0xA5, 0x24, 0xD4, 0xC1, 0xED, 0x36, 0xC7, 0x87, 0x2C, 0x55])
    }

    @Test
    func `capacities match the standard's table for versions 1 and 40`() throws {
        let one = try #require(ISO.`18004`.Version(1))
        let forty = try #require(ISO.`18004`.Version(40))
        let expected: [(ISO.`18004`.Correction.Level, [Int], [Int])] = [
            (.low, [41, 25, 17], [7089, 4296, 2953]),
            (.medium, [34, 20, 14], [5596, 3391, 2331]),
            (.quartile, [27, 16, 11], [3993, 2420, 1663]),
            (.high, [17, 10, 7], [3057, 1852, 1273]),
        ]
        for (level, first, last) in expected {
            #expect([ISO.`18004`.Mode.numeric, .alphanumeric, .byte].map { one.capacity($0, level) } == first)
            #expect([ISO.`18004`.Mode.numeric, .alphanumeric, .byte].map { forty.capacity($0, level) } == last)
        }
    }

    @Test
    func `the mode is the most compact one that holds the data`() {
        #expect(ISO.`18004`.Mode(Array("0123456789".utf8)) == .numeric)
        #expect(ISO.`18004`.Mode(Array("HELLO WORLD".utf8)) == .alphanumeric)
        #expect(ISO.`18004`.Mode(Array("hello".utf8)) == .byte)
    }

    @Test
    func `a symbol takes the smallest version that holds its data`() throws {
        #expect(ISO.`18004`.Symbol(Array("example.org".utf8), level: .medium)?.size == 21)
        #expect(ISO.`18004`.Symbol([UInt8](repeating: 0x61, count: 200), level: .medium)?.version.number == 10)
        #expect(ISO.`18004`.Symbol([UInt8](repeating: 0x61, count: 2953), level: .low)?.version.number == 40)
        #expect(ISO.`18004`.Symbol(Array(repeating: UInt8(ascii: "7"), count: 41), level: .low)?.version.number == 1)
    }

    @Test
    func `the format information names the level and the mask`() throws {
        let symbol = try #require(ISO.`18004`.Symbol(Array("example.org".utf8), level: .low, mask: ISO.`18004`.Mask(4)))
        #expect(symbol.mask.reference == 4)
        let rows = symbol.modules
        let bits = (0...5).map { rows[$0][8] } + [rows[7][8], rows[8][8], rows[8][7]] + (9..<15).map { rows[8][14 - $0] }
        let read = bits.enumerated().reduce(0) { $0 | ($1.element ? 1 << $1.offset : 0) } ^ 0x5412
        #expect(read >> 10 == 0b01_100)
    }
}

extension `ISO.18004.Symbol Tests`.Test.`Edge Case` {
    @Test
    func `data no symbol holds is refused`() {
        #expect(ISO.`18004`.Symbol([UInt8](repeating: 0x61, count: 2954), level: .low) == nil)
        #expect(ISO.`18004`.Symbol([UInt8](repeating: 0x61, count: 1274), level: .high) == nil)
    }

    @Test
    func `a version or mode that cannot hold the data is refused`() throws {
        #expect(ISO.`18004`.Symbol([UInt8](repeating: 0x61, count: 200), level: .medium, version: ISO.`18004`.Version(9)) == nil)
        #expect(ISO.`18004`.Symbol(Array("abc".utf8), level: .medium, mode: .numeric) == nil)
        #expect(ISO.`18004`.Version(0) == nil)
        #expect(ISO.`18004`.Version(41) == nil)
        #expect(ISO.`18004`.Mask(8) == nil)
    }

    @Test
    func `empty data makes a version 1 symbol`() {
        #expect(ISO.`18004`.Symbol([], level: .high)?.version.number == 1)
    }
}
