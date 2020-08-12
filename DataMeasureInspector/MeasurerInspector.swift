//
//  MeasurerInspector.swift
//  DataMeasureInspector
//
//  Created by Vistory Group on 11/08/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

let ptsC = 100
class MeasurerInspector: ObservableObject, AxeGraphViewDataSource {
    
    @Published var inspectableMeasures: [String] = []
    @Published var inspectedMeasureIndex: Int = 0
    
    @Published var points: [CGPoint] =
        (0...ptsC).map { x in
            (0...ptsC).map { y in
                CGPoint(x: CGFloat(x) / CGFloat(ptsC), y: CGFloat(y) / CGFloat(ptsC))
            }
        }.reduce(into: [CGPoint]()) {
            $0.append(contentsOf: $1)
    }
    
    var coloredPoints: [Color : [CGPoint]] = {
        [Color.red: (0 ..< 100).map { CGPoint(x: 0.01 * CGFloat($0), y: 0.01 * CGFloat($0)) }]
    }()
    
    @Published var xName: String = "x"
    @Published var yName: String = "y"
    @Published var xBoundValues: Range<CGFloat> = 0.0..<1.5
    @Published var yBoundValues: Range<CGFloat> = 0.0..<1.1
    
    let xSegmentCount: Int = 10
    let ySegmentCount: Int = 10
    let xFormat = ".2"
    let yFormat = ".2"
    
    enum LoadingError: String, Error, LocalizedError {
        case incorrectFileContent
        case incorrectMeasurementsFormat
        
        var localizedDescription: String {
            self.rawValue
        }
    }
    
    @Published var loadedMeasurementName: String?
    @Published var loadedRealMesurementName: String?
    
    /// [measurementName: [personName: [value]]
    var measurements: [String: [String: [Double]]] = [:]
    /// [measurementName: [personName: value]]
    var realMeasurements: [String: [String: Double]] = [:]
    
    private var inspectorTwo: AnyCancellable!
    
    init() {
        self.inspectorTwo = self.$inspectedMeasureIndex.sink(receiveValue: { _ in
            DispatchQueue.main.async {
                self.createGraphicValues()
            }
        })
    }
    
    // MARK: - Load directory
    func loadDirectory(url versionUrl: URL) throws {
        self.measurements = [:]
        self.loadedMeasurementName = nil
        
        let personUrls = try FileManager.default.contentsOfDirectory(at: versionUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        for personUrl in personUrls {
            let sessionUrls = try FileManager.default.contentsOfDirectory(at: personUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            for sessionUrl in sessionUrls {
                let jsonUrl = sessionUrl.appendingPathComponent("log.json")
                let logs = try JSONSerialization.jsonObject(with: Data(contentsOf: jsonUrl), options: [])
                if let logsObject = logs as? [String: Any] {
                    
                    guard let personName = logsObject["person"] as? String,
                        let measures = logsObject["measurements"] as? [String: Double] else {
                        throw LoadingError.incorrectMeasurementsFormat
                    }
                    
                    for (measureName, value) in measures {
                        if self.measurements.keys.contains(measureName) {
                            if self.measurements[measureName]!.keys.contains(personName) {
                                self.measurements[measureName]![personName]!.append(value)
                            } else {
                                self.measurements[measureName]![personName] = [value]
                            }
                        } else {
                            self.measurements[measureName] = [personName: [value]]
                        }
                    }
                    
                } else {
                    throw LoadingError.incorrectFileContent
                }
            }
        }
        
        self.loadedMeasurementName = versionUrl.lastPathComponent
        
        self.updateInspectable()
        self.createGraphicValues()
    }
    
    // MARK: - load csv
    func loadCsvMeasures(url csvUrl: URL) throws {
        
        self.realMeasurements = [:]
        self.loadedRealMesurementName = nil
        
        let content = try String(contentsOf: csvUrl)
        
        let lines = content.components(separatedBy: "\n")
        guard lines.isEmpty == false else { throw LoadingError.incorrectFileContent }
        guard lines.count > 1 else { return }
        
        let measureNames = lines[0].components(separatedBy: ",")
        guard measureNames.isEmpty == false else { return }
        
        for i in 1 ..< lines.count {
            let lineValues = lines[i].components(separatedBy: ",")
            if lineValues.count == 1 { continue }
            guard lineValues.count == measureNames.count else {
                throw LoadingError.incorrectMeasurementsFormat
            }
            
            let personName = lineValues[0]
            let measureValues: [Double] = lineValues.map {
                Double($0) ?? 0.0
            }
            
            if measureValues.count == measureNames.count {
                for k in 0 ..< measureNames.count {
                    
                    if self.realMeasurements.keys.contains(measureNames[k]) {
                        self.realMeasurements[measureNames[k]]![personName] = measureValues[k]
                    } else {
                        self.realMeasurements[measureNames[k]] = [personName: measureValues[k]]
                    }
                    
                }
            } else {
                throw LoadingError.incorrectMeasurementsFormat
            }
            
        }
        
        self.loadedRealMesurementName = csvUrl.lastPathComponent
        
        self.updateInspectable()
        self.createGraphicValues()
    }
    
    fileprivate func updateInspectable() {
        self.inspectableMeasures = [String](Set<String>(self.measurements.keys)
            & Set<String>(self.realMeasurements.keys))
    }
    
    // MARK: - Create Graphic
    
    fileprivate func makePointsFor(inspected: String) -> [CGPoint] {
        
        guard self.measurements.isEmpty == false,
            self.realMeasurements.isEmpty == false,
            let measurements = self.measurements[inspected],
            let realMeasurements = self.realMeasurements[inspected]
            else { return [] }
        
        var missingPersons: Set<String> = []
        var presentPersons: Set<String> = []
        
        var points: [CGPoint] = []
        for (personName, values) in measurements {
            guard let realMeasure = realMeasurements[personName] else {
                missingPersons.insert(personName)
                continue
            }
            presentPersons.insert(personName)
            
            for value in values {
                points.append(CGPoint(x: value, y: realMeasure))
            }
            
        }
        
        print("We're missing measure for \(missingPersons) but at least we have \(presentPersons)")
        
        return points
    }
    
    func createGraphicValues() {
        
//        self.points = []
        self.xName = "x"
        self.yName = "y"
        
        guard let inspected = self.inspectableMeasures[safe: self.inspectedMeasureIndex] else {
            return
        }
        
        self.points = self.makePointsFor(inspected: inspected)
        
        let (minPoint, maxPoint) = points.reduce((min: CGPoint.zero, max: CGPoint(x: 1, y: 1))) { (pts, point) in
            (CGPoint(x: min(pts.0.x, point.x), y: min(pts.0.y, point.y)),
             CGPoint(x: max(pts.1.x, point.x), y: max(pts.1.y, point.y)))
        }
        
        self.xBoundValues = minPoint.x ..< maxPoint.x
        self.yBoundValues = minPoint.y ..< maxPoint.y
        
        self.xName = inspected
        self.yName = "real-\(inspected)"
        
        objectWillChange.send()
    }
    
}
