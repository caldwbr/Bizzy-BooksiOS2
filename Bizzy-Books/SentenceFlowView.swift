//
//  SentenceFlowView.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 12/22/23.
//

import SwiftUI

struct SizeKey: PreferenceKey {
    static let defaultValue: [CGSize] = []
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.append(contentsOf: nextValue())
    }
}

func layout(sizes: [CGSize], spacing: CGSize = .init(width: 10, height: 10), containerWidth: CGFloat) -> [CGPoint] {
    var currentPoint: CGPoint = .zero
    var result: [CGPoint] = []
    var lineHeight: CGFloat = 0
    for size in sizes {
        if currentPoint.x + size.width > containerWidth {
            currentPoint.x = 0
            currentPoint.y += lineHeight + spacing.height
            lineHeight = 0
        }
        result.append(currentPoint)
        currentPoint.x += size.width + spacing.width
        lineHeight = max(lineHeight, size.height)
    }
    return result
}

struct SentenceFlowView<Cell: View>: View {
    var elements: [SentenceElement]
    @ViewBuilder var cell: (SentenceElement) -> Cell
    @State private var sizes: [CGSize] = []
    @State private var containerWidth: CGFloat = 0
    
    var body: some View {
        let laidout = layout(sizes: sizes, containerWidth: containerWidth)
        VStack(spacing: 0) {
            GeometryReader { proxy in
                Color.clear.preference(key: SizeKey.self, value: [proxy.size])
            }
            .frame(height: 0)
            .onPreferenceChange(SizeKey.self) { value in
                self.containerWidth = value[0].width
            }
            ZStack(alignment: .topLeading) {
                ForEach(Array(zip(elements, elements.indices)), id: \.0.id) { (element, index) in
                    cell(element)
                        .fixedSize()
                        .background(GeometryReader { proxy in
                            Color.clear.preference(key: SizeKey.self, value: [proxy.size])
                        })
                        .alignmentGuide(.leading, computeValue: { dimension in
                            guard !laidout.isEmpty else { return 0 }
                            return -laidout[index].x
                        })
                        .alignmentGuide(.top, computeValue: { dimension in
                            guard !laidout.isEmpty else { return 0 }
                            return -laidout[index].y
                        })
                }
            }.onPreferenceChange(SizeKey.self, perform: { value in
                self.sizes = value
                print(value)
            })
            .frame(minWidth: 0, maxWidth: .infinity)
        }
    }
}
