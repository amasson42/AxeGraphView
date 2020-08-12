//
//  SwiftUIExtensions.swift
//  DataMeasureInspector
//
//  Created by Vistory Group on 11/08/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import SwiftUI

extension Path {
    
    mutating func addSegment(from: CGPoint, to: CGPoint) {
        self.move(to: from)
        self.addLine(to: to)
    }
    
}

struct MouseGestureView: NSViewRepresentable {
    
    let moveCallback: ((CGPoint) -> ())?
    let clickCallback: ((CGPoint) -> ())?
    let trackCallback: ((Bool) -> ())?
    
    init(move: ((CGPoint) -> ())? = nil,
         click: ((CGPoint) -> ())? = nil,
         track: ((Bool) -> ())? = nil) {
        self.moveCallback = move
        self.clickCallback = click
        self.trackCallback = track
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let clickGesture = NSClickGestureRecognizer(target: context.coordinator,
                                               action: #selector(Coordinator.click))
        view.addGestureRecognizer(clickGesture)
        
        
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(gestureView: self)
    }
    
    class Coordinator: NSObject {
        var clickCallback: ((CGPoint) -> Void)?
        var moveCallback: ((CGPoint) -> Void)?
        var trackCallback: ((Bool) -> Void)?
        
        init(gestureView: MouseGestureView) {
            self.clickCallback = gestureView.clickCallback
            self.moveCallback = gestureView.moveCallback
            self.trackCallback = gestureView.trackCallback
        }
        
        @objc func click(_ gesture: NSClickGestureRecognizer) {
            self.clickCallback?(gesture.location(in: gesture.view))
        }
        
    }
    
}

extension Collection {
    
    public func minIndex(by comp: (Element, Element) throws -> Bool) rethrows -> Index? {
        guard self.isEmpty == false else { return nil }
        var minIndex: Index = self.startIndex
        for index in self.indices.dropFirst() {
            if try comp(self[index], self[minIndex]) {
                minIndex = index
            }
        }
        return minIndex
    }
    
}
