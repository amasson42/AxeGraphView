//
//  StandardExtensions.swift
//  DataMeasureInspector
//
//  Created by Vistory Group on 10/08/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import Foundation

// MARK: - Core Graphic

extension CGPoint: AdditiveArithmetic {
    
    public static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    public static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    public static func * (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
    }
    
    public static func / (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x / rhs.x, y: lhs.y / rhs.y)
    }
    
    public static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    
    public static func * (lhs: CGFloat, rhs: CGPoint) -> CGPoint {
        rhs * lhs
    }
    
    public static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
    
    public func squaredNorme() -> CGFloat {
        x * x + y * y
    }
    
}

extension CGSize: AdditiveArithmetic {
     
    init(_ point: CGPoint) {
        self.init(width: point.x, height: point.y)
    }
    
    public static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    
    public static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    public static func * (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width * rhs.width, height: lhs.height * rhs.height)
    }
    
    public static func / (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width / rhs.width, height: lhs.height / rhs.height)
    }
    
    public static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    
    public static func * (lhs: CGFloat, rhs: CGSize) -> CGSize {
        rhs * lhs
    }
    
    public static func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
    }
    
}

// MARK: - Simple types

extension Range where Bound: AdditiveArithmetic {
    
    var width: Bound {
        self.upperBound - self.lowerBound
    }
    
    public static func + (lhs: Self, rhs: Bound) -> Self {
        (lhs.lowerBound + rhs) ..< (lhs.upperBound + rhs)
    }
    
    public static func - (lhs: Self, rhs: Bound) -> Self {
        (lhs.lowerBound - rhs) ..< (lhs.lowerBound - rhs)
    }
    
}

extension Double {
    
    init(parse: String, orThrow error: Error) throws {
        if let value = Self(parse) {
            self = value
        } else {
            throw error
        }
    }
    
}

// MARK: - Collection

extension Sequence where Element: Hashable {
    
    public static func & (lhs: Self, rhs: Self) -> Set<Element> {
        Set<Element>(lhs).intersection(Set<Element>(rhs))
    }
    
    public static func | (lhs: Self, rhs: Self) -> Set<Element> {
        Set<Element>(lhs).union(Set<Element>(rhs))
    }
    
}

extension Array {
    
    public subscript(safe index: Self.Index) -> Element? {
        return self.indices.contains(index) ? self[index] : nil
    }
    
    public subscript(_ indices: [Index]) -> Self {
        var ret = Self()
        ret.reserveCapacity(indices.count)
        indices.forEach {
            ret.append(self[$0])
        }
        return ret
    }
    
    public func sorted(by areInIncreasingOrder: (Element, Element) throws -> Bool,
                       withIndicesFor indexFor: (Element) throws -> Index?) rethrows -> [Element] {
        return try self.sorted { (lhs, rhs) -> Bool in
            let (li, ri) = try (indexFor(lhs), indexFor(rhs))
            return li != nil ? (ri != nil ? li! < ri! : true) : (ri != nil ? false : try areInIncreasingOrder(lhs, rhs))
        }
    }
}

extension Dictionary {
    
    public subscript(_ indices: [Key]) -> Self {
        var ret: Self = [:]
        ret.reserveCapacity(indices.count)
        indices.forEach {
            ret[$0] = self[$0]
        }
        return ret
    }
    
}
