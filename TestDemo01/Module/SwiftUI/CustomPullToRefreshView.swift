//
//  CustomPullToRefreshView.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/12.
//

import SwiftUI

struct GridLayout: Layout {
    var columns: Int
    var spacing: CGFloat = 10
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let width = proposal.width ?? .infinity
        let itemWidth = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        var totalHeight: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            if index % columns == 0 && index != 0 {
                totalHeight += currentRowHeight + spacing
                currentRowHeight = 0
            }
            
            let itemSize = subview.sizeThatFits(.init(width: itemWidth, height: nil))
            currentRowHeight = max(currentRowHeight, itemSize.height)
        }
        totalHeight += currentRowHeight
        
        return CGSize(width: width, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        
        let width = bounds.width
        let itemWidth = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        var point = bounds.origin
        var currentRowHeight: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            if index % columns == 0 && index != 0 {
                point.x = bounds.origin.x
                point.y += currentRowHeight + spacing
                currentRowHeight = 0
            }
            
            let itemSize = subview.sizeThatFits(.init(width: itemWidth, height: nil))
            subview.place(
                at: CGPoint(x: point.x + itemWidth / 2, y: point.y + itemSize.height / 2),
                anchor: .center,
                proposal: .init(width: itemWidth, height: itemSize.height)
            )
            
            point.x += itemWidth + spacing
            currentRowHeight = max(currentRowHeight, itemSize.height)
        }
    }
}

struct WaterfallLayout: Layout {
    var columns: Int
    var spacing: CGFloat = 8
    
    struct Cache {
        var columnHeights: [CGFloat]
    }
    
    func makeCache(subviews: Subviews) -> Cache {
        Cache(columnHeights: Array(repeating: 0, count: columns))
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        
        let width = proposal.width ?? .infinity
        let columnWidth = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        
        // 重置列高度
        cache.columnHeights = Array(repeating: 0, count: columns)
        
        for subview in subviews {
            let itemSize = subview.sizeThatFits(.init(width: columnWidth, height: nil))
            if let minHeightIndex = cache.columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset {
                cache.columnHeights[minHeightIndex] += itemSize.height + spacing
            }
        }
        
        let maxHeight = cache.columnHeights.max() ?? 0
        return CGSize(width: width, height: maxHeight - spacing) // 减去最后一个spacing
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        guard !subviews.isEmpty else { return }
        
        let columnWidth = (bounds.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        var columnHeights = Array(repeating: bounds.minY, count: columns)
        
        for subview in subviews {
            let itemSize = subview.sizeThatFits(.init(width: columnWidth, height: nil))
            
            if let minHeightIndex = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset {
                let xPosition = bounds.minX + CGFloat(minHeightIndex) * (columnWidth + spacing)
                let yPosition = columnHeights[minHeightIndex]
                
                subview.place(
                    at: CGPoint(x: xPosition + columnWidth / 2, y: yPosition + itemSize.height / 2),
                    anchor: .center,
                    proposal: .init(width: columnWidth, height: itemSize.height)
                )
                
                columnHeights[minHeightIndex] += itemSize.height + spacing
            }
        }
    }
}

// 使用示例
struct GridContentView: View {
    var body: some View {
        WaterfallLayout(columns: 2) {
            ForEach(0..<10) { index in
                Text("Item \(index)")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.blue.opacity(0.2))
            }
        }
        .padding()
    }
}

// MARK: - 修复后的使用示例
struct RefreshableScrollView_Previews: PreviewProvider {
   
    static var previews: some View {
        GridContentView()
    }
}

//#Preview {
//    RefreshableScrollView()
//}
