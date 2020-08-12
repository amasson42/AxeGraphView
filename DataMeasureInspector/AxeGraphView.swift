//
//  AxeGraphView.swift
//  DataMeasureInspector
//
//  Created by Vistory Group on 10/08/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import SwiftUI

protocol AxeGraphViewDataSource: ObservableObject {
    var points: [CGPoint] { get }
    var coloredPoints: [Color: [CGPoint]] { get }
    
    var xName: String { get }
    /// Must be a @Published value
    var xBoundValues: Range<CGFloat> { get set }
    var xSegmentCount: Int { get }
    
    var yName: String { get }
    /// Must be a @Published value
    var yBoundValues: Range<CGFloat> { get set }
    var ySegmentCount: Int { get }
    
    var xFormat: String { get }
    var yFormat: String { get }
}

extension AxeGraphViewDataSource {
    var coloredPoints: [Color: [CGPoint]] { [:] }
    var xFormat: String { ".2" }
    var yFormat: String { ".2" }
}

struct AxeGraphView<DataSource: AxeGraphViewDataSource>: View {
    
    @ObservedObject var dataSource: DataSource
    
    private let segmentWidth: CGFloat = 5.0
    private let paddingLength: CGFloat = 17.0
    private let segPoint = CGPoint(x: -15.0, y: 5.0)
    
    @State private var lastDragValue: CGSize?
    @State private var tappedPointIndex: Int = -1
    
    var body: some View {
        GeometryReader<AnyView> { proxy in
            
            let xName = self.dataSource.xName
            let yName = self.dataSource.yName
            let xBounds = self.dataSource.xBoundValues
            let yBounds = self.dataSource.yBoundValues
            let xCount = self.dataSource.xSegmentCount
            let yCount = self.dataSource.ySegmentCount
            let xFormat = "%\(self.dataSource.xFormat)f"
            let yFormat = "%\(self.dataSource.yFormat)f"
            let points = self.dataSource.points
            let coloredPoints = self.dataSource.coloredPoints.map { ($0, $1) }
            let namedPoints: [(position: CGPoint, name: String)] = [
                (CGPoint(x: -0.1, y: -0.1), "The origin"),
                (CGPoint(x: 0, y: -0.1), "The origin"),
                (CGPoint(x: 0, y: -0.1), "The origin"),
                (CGPoint(x: 0, y: -0.1), "The origin")
            ]
            
            let segmentWidth = self.segmentWidth
            let segPoint = self.segPoint
            let pointOrigin = CGPoint(x: 0, y: proxy.size.height)
            let pointMax = CGPoint(x: proxy.size.width, y: 0)
            
            /// Convert [0; 1] -> [0; proxy]
            func insetCoords(_ p: CGPoint) -> CGPoint {
                pointOrigin + (pointMax - pointOrigin) * p
            }
            
            /// Convert [0; proxy] -> [0; 1]
            func reverseInsetCoords(_ p: CGPoint) -> CGPoint {
                (p - pointOrigin) / (pointMax - pointOrigin)
            }
            
            /// Convert [x, y] -> [0; 1]
            func graphCoords(_ p: CGPoint) -> CGPoint {
                CGPoint(x: (p.x - xBounds.lowerBound) / xBounds.width,
                        y: (p.y - yBounds.lowerBound) / yBounds.width)
            }
            
            /// Convert [0; 1] -> [x; y]
            func reverseGraphCoords(_ p: CGPoint) -> CGPoint {
                CGPoint(x: p.x * xBounds.width + xBounds.lowerBound,
                        y: p.y * yBounds.width + yBounds.lowerBound)
            }
            
            func addPoint(_ p: CGPoint, toPath path: inout Path) {
                path.addSegment(from: CGPoint(x: p.x - segmentWidth, y: p.y),
                                to: CGPoint(x: p.x + segmentWidth, y: p.y))
                path.addSegment(from: CGPoint(x: p.x, y: p.y - segmentWidth),
                                to: CGPoint(x: p.x, y: p.y + segmentWidth))
            }
            
            return AnyView(ZStack(alignment: .topLeading) {
                
                Path { path in
                    
                    path.addSegment(from: pointOrigin, to: insetCoords(CGPoint(x: 0, y: 1)))
                    path.addSegment(from: pointOrigin, to: insetCoords(CGPoint(x: 1, y: 0)))
                    
                    for i in 1 ... xCount {
                        let point = CGPoint(x: CGFloat(i) / CGFloat(xCount), y: 0)
                        let botSegment = insetCoords(point) + CGPoint(x: 0, y: segmentWidth)
                        let topSegment = insetCoords(point) + CGPoint(x: 0, y: -segmentWidth)
                        path.addSegment(from: botSegment, to: topSegment)
                    }
                    
                    for i in 1 ... yCount {
                        let point = CGPoint(x: 0, y: CGFloat(i) / CGFloat(yCount))
                        let botSegment = insetCoords(point) + CGPoint(x: segmentWidth, y: 0)
                        let topSegment = insetCoords(point) + CGPoint(x: -segmentWidth, y: 0)
                        path.addSegment(from: botSegment, to: topSegment)
                    }
                    
                }
                .stroke()
                
                Text(xName)
                    .offset(CGSize(insetCoords(CGPoint(x: 0.5, y: 0.0))
                        + CGPoint(x: 0, y: 1.5 * self.paddingLength)
                        + CGPoint(x: 0, y: -8)))
                
                Text(yName)
                    .rotationEffect(.degrees(-90), anchor: .topLeading)
                    .offset(CGSize(insetCoords(CGPoint(x: 0.0, y: 0.5))
                        + CGPoint(x: -2 * self.paddingLength, y: 0)
                        + CGPoint(x: -2, y: 0)))
                
                ForEach(1 ... xCount, id: \.self) { i in
                    Text(String(format: xFormat,
                                xBounds.lowerBound + CGFloat(i) * (xBounds.width / CGFloat(xCount))))
                        .offset(CGSize(insetCoords(CGPoint(x: CGFloat(i) / CGFloat(xCount), y: 0))
                            + segPoint))
                }
                
                ForEach(0 ... yCount, id: \.self) { i in
                    Text(String(format: yFormat,
                                yBounds.lowerBound + CGFloat(i) * (yBounds.width / CGFloat(yCount))))
                        .offset(CGSize(insetCoords(CGPoint(x: 0, y: CGFloat(i) / CGFloat(yCount)))
                            + segPoint
                            + CGPoint(x: -segmentWidth, y: -segmentWidth)
                        ))
                }
                
                Path { path in
                    for point in points {
                        addPoint(insetCoords(graphCoords(point)), toPath: &path)
                    }
                }
                .stroke()
                
                ForEach(0 ..< coloredPoints.count, id: \.self) { i in
                    Path { path in
                        for point in coloredPoints[i].1 {
                            addPoint(insetCoords(graphCoords(point)), toPath: &path)
                        }
                    }
                    .stroke(coloredPoints[i].0)
                }
                
                ForEach(0 ..< namedPoints.count, id: \.self) { i in
                    NamedPoint(showInfo: self.tappedPointIndex == i, info: namedPoints[i].name)
                        .offset(CGSize(insetCoords(graphCoords(namedPoints[i].position))))
                }
                
            }
            .frame(minWidth: 50.0, idealWidth: 600.0, minHeight: 50.0, idealHeight: 600.0)
            .background(Color(red: 0, green: 0, blue: 0, opacity: 0.01))
                /* MARK: - Gestures */
            .overlay(MouseGestureView(click: { clickLocation in
                let graphClickLocation = CGPoint(x: clickLocation.x,
                                                 y: proxy.size.height - clickLocation.y)
                print("graphClick = \(graphClickLocation)")
                print("in proxy = \(reverseInsetCoords(graphClickLocation))")
                print("in graph = \(reverseGraphCoords(reverseInsetCoords(graphClickLocation)))")
                let graphLocation = reverseGraphCoords(reverseInsetCoords(graphClickLocation))
                guard namedPoints.isEmpty == false else { return }
                let minIndex = namedPoints.minIndex {
                    ($0.position - graphLocation).squaredNorme() < ($1.position - graphLocation).squaredNorme()
                }!
                self.tappedPointIndex = minIndex
            }))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let dragOffset: CGSize
                        if let lastDrag = self.lastDragValue {
                            dragOffset = value.translation - lastDrag
                        } else {
                            dragOffset = value.translation
                        }
                        
                        self.lastDragValue = value.translation
                        
                        let offset = -1 * dragOffset
                            * CGSize(width: self.dataSource.xBoundValues.width,
                                     height: -self.dataSource.yBoundValues.width)
                            / CGSize(width: proxy.size.width, height: proxy.size.height)
                        
                        self.dataSource.xBoundValues = self.dataSource.xBoundValues + offset.width
                        self.dataSource.yBoundValues = self.dataSource.yBoundValues + offset.height
                }
                .onEnded { _ in
                    self.lastDragValue = nil
            })
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            
                })
            )
        }
        .padding(self.paddingLength)
        .padding([.bottom, .leading], self.paddingLength)
        
    }
    
    struct NamedPoint: View {
        
        let showInfo: Bool
        let info: String
        private let size = CGSize(width: 10, height: 10)
        
        var body: some View {
            
            Path { path in
                path.addSegment(from: CGPoint(x: -0.5 * size.width, y: 0.0),
                                to: CGPoint(x: 0.5 * size.width, y: 0.0))
                path.addSegment(from: CGPoint(x: 0.0, y: -0.5 * size.height),
                                to: CGPoint(x: 0.0, y: 0.5 * size.height))
            }
            .stroke(self.showInfo ? Color.green : Color.red)
            
        }
    }
}

struct AxeGraphView_Previews: PreviewProvider {
    
    class DataSourceExample: AxeGraphViewDataSource {
        var points: [CGPoint] { [
            CGPoint(x: 0.8, y: 0.5),
            CGPoint(x: 0.9, y: -0.2)
            ] }
        var coloredPoints: [Color: [CGPoint]] { [
            .red: [
                CGPoint(x: 0.1, y: 0.8),
                CGPoint(x: 0.2, y: 0.8)
            ],
            .blue: [
                CGPoint(x: 0.7, y: 0.2),
                CGPoint(x: 0.6, y: 0.2)
            ]
            ] }
        
        var xName: String { "The X Axis" }
        var xBoundValues: Range<CGFloat> { get {0.1 ..< 1.7} set {} }
        var xSegmentCount: Int { 8 }
        
        var yName: String { "The Y Axis" }
        var yBoundValues: Range<CGFloat> { get {-0.5 ..< 1.2} set {} }
        var ySegmentCount: Int { 6 }
    }
    
    static var previews: some View {
        AxeGraphView(dataSource: DataSourceExample())
    }
}
