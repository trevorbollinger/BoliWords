//
//  FlowLayout.swift
//  BoliWords
//
//  Created by Antigravity on 3/18/26.
//

import SwiftUI

/// A Layout that wraps its children to the next line when they overflow the available width.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var currentPoint = CGPoint.zero
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentPoint.x + size.width > width {
                // New line
                currentPoint.x = 0
                currentPoint.y += lineHeight + spacing
                lineHeight = 0
            }
            
            currentPoint.x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = max(totalHeight, currentPoint.y + lineHeight)
            totalWidth = max(totalWidth, currentPoint.x)
        }
        
        return CGSize(width: min(width, totalWidth), height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentPoint = CGPoint(x: bounds.minX, y: bounds.minY)
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentPoint.x + size.width > bounds.maxX {
                // New line
                currentPoint.x = bounds.minX
                currentPoint.y += lineHeight + spacing
                lineHeight = 0
            }
            
            subview.place(at: currentPoint, proposal: ProposedViewSize(size))
            
            currentPoint.x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
