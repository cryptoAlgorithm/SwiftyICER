//
//  ICER.swift
//  CubesatGS
//
//  Created by Vincent Kwok on 23/3/23.
//

import Foundation
import ICERImpl

/// Wrapper for C ICER methods.
///
/// > Warning: Do not instantiate this struct directly - rather, use the provided
/// > singleton ``ICER/instance`` instead.
public struct ICER {
    private init() {
        icer_init()
    }

    /// An instance of the wrapper
    ///
    /// Provides a single instance that is used throughout the application's whole lifespan.
    static let instance = Self()

    static fileprivate let MAX_SIZE = 1000*1000
}

public extension ICER {
    /// Represents an decoded ICER image
    struct DecodedData {
        /// Raw image data
        ///
        /// Currently, only 8-bit grayscale is supported
        let data: ImgData
        enum ImgData {
            case rgb888(Data, Data, Data)
            case grayscale(Data)
        }

        /// Width of image
        let width: Int
        /// Height of image
        let height: Int
    }

    enum DecodeOption {
        case gray16
        case gray8
        case yuv16
        case yuv8
    }

    enum DecodeError: Error, CustomStringConvertible {
        case icerError(_ status: icer_status)
        case invalidStages
        case invalidSegments

        public var description: String {
            switch self {
            case .icerError(let status):
                return "ICER decoding failure: \(status)"
            case .invalidStages:
                return "Invalid number of stages"
            case .invalidSegments:
                return "Invalid number of segments"
            }
        }
    }

    /// Decode an ICER-encoded data stream
    ///
    /// - Parameters:
    ///   - encoded: ICER-encoded data
    ///   - stages: Stages paramter to encode image
    ///   - segments: Segments used to encode image
    ///   - filter: Filter used to encode image
    /// - Throws: ``DecodeError`` if image decode failed
    func decode(
        _ encoded: Data,
        stages: UInt8, segments: UInt8, filter: icer_filter_types,
        type: DecodeOption = .gray16
    ) throws -> DecodedData {
        guard stages <= ICER_MAX_DECOMP_STAGES else { throw DecodeError.invalidStages }
        guard segments <= ICER_MAX_SEGMENTS else { throw DecodeError.invalidSegments }

        var w = 0, h = 0
        // Make copy of data for decoding operation so as to not mutate original one
        let enc = Data(encoded)
        let data: DecodedData.ImgData = try enc.withUnsafeBytes { ptr in
            let encodedAddr = ptr.baseAddress!.assumingMemoryBound(to: UInt8.self)
            switch type {
            case .gray16:
                let decoded = Data(count: Self.MAX_SIZE)
                var dec = decoded // Make copy for modification
                return try dec.withUnsafeMutableBytes { decBuf in
                    let decBufAddr = decBuf.bindMemory(to: UInt16.self).baseAddress!
                    let res = icer_decompress_image_uint16(
                        decBufAddr, &w, &h, decoded.count,
                        encodedAddr, encoded.count,
                        stages, filter, segments
                    )
                    guard res == ICER_RESULT_OK.rawValue else {
                        throw DecodeError.icerError(.init(res))
                    }
                    return .grayscale(decoded)
                }
            case .gray8:
                let decoded = Data(count: Self.MAX_SIZE)
                var dec = decoded // Make copy for modification
                return try dec.withUnsafeMutableBytes { decBuf in
                    let decBufAddr = decBuf.bindMemory(to: UInt8.self).baseAddress!
                    let res = icer_decompress_image_uint8(
                        decBufAddr, &w, &h, decoded.count,
                        encodedAddr, encoded.count,
                        stages, filter, segments
                    )
                    guard res == ICER_RESULT_OK.rawValue else {
                        throw DecodeError.icerError(.init(res))
                    }
                    return .grayscale(decoded)
                }
            case .yuv16:
                var yBuf = Data(count: ICER.MAX_SIZE), uBuf = Data(count: ICER.MAX_SIZE), vBuf = Data(count: ICER.MAX_SIZE)
                let res = yBuf.withUnsafeMutableBytes { yPtr in
                    let y = yPtr.baseAddress!.assumingMemoryBound(to: UInt16.self)
                    return uBuf.withUnsafeMutableBytes { uPtr in
                        let u = uPtr.baseAddress!.assumingMemoryBound(to: UInt16.self)
                        return vBuf.withUnsafeMutableBytes { vPtr in
                            let v = vPtr.baseAddress!.assumingMemoryBound(to: UInt16.self)
                            let ret = icer_decompress_image_yuv_uint16(y, u, v, &w, &h, Self.MAX_SIZE, encodedAddr, encoded.count, stages, filter, segments)
                            yuv_to_rgb888_inplace(y, u, v, w, h, w)
                            return ret
                        }
                    }
                }
                guard res == ICER_RESULT_OK.rawValue else {
                    throw DecodeError.icerError(.init(res))
                }
                // Convert back to RGB888
                // yBuf.copyBytes(to: decBuf)
                // uBuf.copyBytes(to: decBuf.advanced(by: w*h*2))
                // uBuf.copyBytes(to: decBuf.advanced(by: w*h*2*2))

                //Self.yuv_to_rgb888_packed(y_channel: yBuf, u_channel: uBuf, v_channel: vBuf, w: w, h: h)
                //    .copyBytes(to: decBuf)
                return .rgb888(yBuf, uBuf, vBuf)
            default: return .grayscale(Data())
            }
        }
        return .init(data: data, width: w, height: h)
    }
}
