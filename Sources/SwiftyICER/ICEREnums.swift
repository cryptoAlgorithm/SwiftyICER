//
//  ICEREnums.swift
//  Exposed ICER enums
//
//  Created by Vincent Kwok on 22/10/23.
//

import Foundation
import ICERImpl

public enum ICERFilter: UInt32 {
    case filterA = 0
    case filterB
    case filterC
    case filterD
    case filterE
    case filterF
    case filterQ
}

public enum ICERStatus: Int8, CustomStringConvertible {
    case ok = 0
    case integerOverflow = -1
    case outputBufTooSmall = -2
    case tooManySegments = -3
    case tooManyStages = -4
    case byteQuotaExceeded = -5
    case bitplaneOutOfRange = -6
    case decoderOutOfData = -7
    case decoderInvalidData = -8
    case packetCountExceeded = -9
    case fatalError = -10

    public var description: String {
        switch self {
        case .ok: return "ok"
        case .integerOverflow: return "Integer overflow"
        case .outputBufTooSmall: return "Output buffer too small"
        case .tooManySegments: return "Too many segments"
        case .tooManyStages: return "Too many stages"
        case .byteQuotaExceeded: return "Byte quota exceeded"
        case .bitplaneOutOfRange: return "Bitplane out of range"
        case .decoderOutOfData: return "Decoder out of data"
        case .decoderInvalidData: return "Invalid decoder data"
        case .packetCountExceeded: return "Packet count exceeded"
        case .fatalError: return "Fatal error"
        }
    }
}
