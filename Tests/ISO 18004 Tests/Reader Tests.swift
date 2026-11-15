#if canImport(CoreImage)
    import CoreGraphics
    import CoreImage
    import Foundation
    import ISO_18004
    import Testing

    enum `ISO_18004 Reader Tests` {}

    extension `ISO_18004 Reader Tests` {
        @Suite struct Test {
            @Suite struct Integration {}
        }
    }

    extension `ISO_18004 Reader Tests`.Test.Integration {
        static func read(_ symbol: ISO_18004.Symbol) -> String? {
            let scale = 8
            let side = symbol.extent * scale
            var pixels = [UInt8](repeating: 255, count: side * side)
            for y in 0..<symbol.size {
                for x in 0..<symbol.size where symbol[x, y] {
                    for dy in 0..<scale {
                        for dx in 0..<scale {
                            pixels[((y + ISO_18004.Symbol.quiet) * scale + dy) * side + (x + ISO_18004.Symbol.quiet) * scale + dx] = 0
                        }
                    }
                }
            }
            guard let provider = CGDataProvider(data: Data(pixels) as CFData),
                let drawn = unsafe CGImage(
                    width: side,
                    height: side,
                    bitsPerComponent: 8,
                    bitsPerPixel: 8,
                    bytesPerRow: side,
                    space: CGColorSpaceCreateDeviceGray(),
                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                    provider: provider,
                    decode: nil,
                    shouldInterpolate: false,
                    intent: .defaultIntent
                )
            else { return nil }
            let image = CIImage(cgImage: drawn)
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
            return detector?.features(in: image).compactMap { ($0 as? CIQRCodeFeature)?.messageString }.first
        }

        static let texts = [
            "example.org",
            "0123456789012345678901234567890123456789",
            "HTTPS://EXAMPLE.ORG/A-PATH/0123456789",
            "otpauth://totp/Example:person%40example.org?secret=JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP&issuer=Example",
            String(repeating: "0123456789ABCDEFGHIJ", count: 30),
            String(repeating: "abcdefghijklmnopqrstuvwxyz0123456789", count: 30),
        ]

        @Test(arguments: ISO_18004.Correction.Level.allCases)
        func `a symbol is read back by the system's own reader as the text it was made from`(_ level: ISO_18004.Correction.Level) throws {
            for text in Self.texts {
                let symbol = try #require(ISO_18004.Symbol(Array(text.utf8), level: level))
                #expect(Self.read(symbol) == text, "\(text) at \(level), version \(symbol.version.number), \(symbol.mode)")
            }
        }

        @Test(arguments: ISO_18004.Mask.all)
        func `every mask is read back`(_ mask: ISO_18004.Mask) throws {
            let symbol = try #require(ISO_18004.Symbol(Array("example.org".utf8), level: .quartile, version: ISO_18004.Version(7), mask: mask))
            #expect(Self.read(symbol) == "example.org")
        }
    }
#endif
