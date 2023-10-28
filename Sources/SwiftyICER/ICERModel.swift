//
//  ICERModel.swift
//
//
//  Created by Vincent Kwok on 21/10/23.
//

import SwiftUI
import ICERImpl

class ICERModel: ObservableObject {
    @Published var decodedImg: CGImage?
    @Published var rendering = false

    private var decodeWorkItem: DispatchWorkItem?
    static private let decodeQueue = DispatchQueue(label: "ICERDecode", qos: .userInteractive)
    static private let decodeCache = Cache<Int, CGImage>()

    private func _decode(
        raw: Data,
        stages: UInt8, segments: UInt8,
        filter: icer_filter_types
    ) {
        // Don't bother decoding if first segment header is missing
        // let canStartDecode = raw.count > 2 && raw[0] == 0x5b && raw[1] == 0x60
        if let decoded = try? ICER.instance.decode(
            raw,
            stages: stages, segments: segments, filter: filter,
            type: .yuv16
        ) {
            guard case .rgb888(let r, let g, let b) = decoded.data else {
                return
            }
            var rgb888 = Data()
            rgb888.resetBytes(in: 0..<(r.count/2)*3)
            let compBits = 8
            for i in 0..<r.count/2 {
                rgb888[i*3] = r[i*2]
                rgb888[i*3+1] = g[i*2]
                rgb888[i*3+2] = b[i*2]
            }

            let providerRef = CGDataProvider(data: rgb888 as CFData)
            let cgImage = CGImage(
                width: decoded.width, height: decoded.height,
                bitsPerComponent: compBits, bitsPerPixel: compBits*3, bytesPerRow: decoded.width*3,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                provider: providerRef!, decode: nil, shouldInterpolate: true, intent: .defaultIntent
            )
            // Store the resultant CGImage in a cache
            // Self.decodeCache[raw.hashValue] = img
            DispatchQueue.main.async { [weak self] in
                self?.decodedImg = cgImage
            }
        } else {
            DispatchQueue.main.async { [weak self] in self?.decodedImg = nil }
        }
    }

    func decode(
        data: Data, ignoreCache: Bool = false,
        st: UInt8, seg: UInt8,
        filter: icer_filter_types
    ) {
        decodeWorkItem?.cancel()

        // If data is empty, don't bother enqueueing a work item
        guard !data.isEmpty else {
            decodedImg = nil
            return
        }

        decodeWorkItem = DispatchWorkItem { [unowned self] in
            print("Decoding")
            // If we have a stored CGImage in the cache, use that instead
            // Cache is unnecessary with new throttling
            /* if !ignoreCache, let cachedImg = Self.decodeCache[data.hashValue] {
                print("Cached")
                DispatchQueue.main.async { [unowned self] in decodedImg = cachedImg }
                return
            } */

            DispatchQueue.main.async { [weak self] in self?.rendering = true }
            _decode(raw: data, stages: st, segments: seg, filter: filter)
            DispatchQueue.main.async { [weak self] in self?.rendering = false }
        }
        Self.decodeQueue.asyncAfter(deadline: .now() + .milliseconds(200), execute: decodeWorkItem!)
    }

    deinit {
        decodeWorkItem?.cancel() // Make sure to stop any pending decode runs
    }
}
