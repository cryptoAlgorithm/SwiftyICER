//
//  ICERImage.swift
//  CubesatGS
//
//  Created by Vincent Kwok on 25/3/23.
//

import SwiftUI
import Combine
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

public struct ICERImage: View, Equatable {
    let data: Data
    let stages: UInt8
    let segments: UInt8
    let filter: icer_filter_types

    @State private var hovered = false

    @StateObject private var model = ICERModel()

    public init(_ data: Data, stages: UInt8, segments: UInt8, filter: ICERFilter) {
        self.data = data
        self.stages = stages
        self.segments = segments
        self.filter = icer_filter_types.init(rawValue: filter.rawValue)
    }

    private static func saveToDisk(continuation: @escaping (URL) -> Void) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.allowsOtherFileTypes = false
        savePanel.title = "Save Image"
        savePanel.message = "Choose a location to save this image to"
        savePanel.beginSheetModal(for: NSApp.windows.first!) { res in
            guard res == .OK else {
                print("Save dialog cancelled by user")
                return
            }
            continuation(savePanel.url!)
        }
    }

    @ViewBuilder
    private func saveButton(image: CGImage) -> some View {
        Button {
            Self.saveToDisk { url in
                let bmRep = NSBitmapImageRep(cgImage: image)
                guard let pngData = bmRep.representation(using: .png, properties: [:]) else {
                    print("Failed to get PNG representation")
                    return
                }
                try? pngData.write(to: url)
            }
        } label: {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 18))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .help("Save Image")
        .buttonStyle(.plain)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .padding(4)
    }

    @ViewBuilder
    private func imageInfo(width: Int, height: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Image size")
                .textCase(.uppercase)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(width)x\(height)px").font(.callout)

            Text("Stream size")
                .textCase(.uppercase)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 2)
            Text("\(data.count)B")

            Text("Total stages")
                .textCase(.uppercase)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 2)
            Text("\(stages)").font(.callout)

            Text("Total segs")
                .textCase(.uppercase)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 2)
            Text("\(segments)").font(.callout)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .strokeBorder(.gray.opacity(0.2), lineWidth: 1)
                .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(.thinMaterial))
        }
        .padding(4)
    }

    public var body: some View {
        ZStack {
            if let img = model.decodedImg {
                Image(nsImage: NSImage(cgImage: img, size: .init(width: img.width, height: img.height)))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(alignment: .topTrailing) {
                        // Save button on top right
                        if hovered { saveButton(image: img) }
                    }
                    .overlay(alignment: .bottomLeading) {
                        if hovered { imageInfo(width: img.width, height: img.height) }
                    }
            } else {
                Image(systemName: "questionmark.square.dashed")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxHeight: .infinity)
            }
        }
        .overlay {
            if model.rendering { ProgressView().controlSize(.large) }
        }
        // Maybe find a better way to do this?
        .onChange(of: data) { newData in
            model.decode(data: newData, st: stages, seg: segments, filter: filter)
        }
        .onChange(of: stages) { newSt in
            model.decode(data: data, ignoreCache: true, st: newSt, seg: segments, filter: filter)
        }
        .onChange(of: segments) { newSeg in
            model.decode(data: data, ignoreCache: true,
                            st: stages, seg: newSeg, filter: filter)
        }
        .onChange(of: filter) { newFilter in
            model.decode(data: data, ignoreCache: true,
                            st: stages, seg: segments, filter: newFilter)
        }
        .onAppear { model.decode(data: data, st: stages, seg: segments, filter: filter) }
        .onHover { hovered = $0 }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.data == rhs.data
        && lhs.stages == rhs.stages && lhs.segments == rhs.segments
        && lhs.filter == rhs.filter
    }
}
