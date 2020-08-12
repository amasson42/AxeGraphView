//
//  ContentView.swift
//  DataMeasureInspector
//
//  Created by Vistory Group on 10/08/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var mainInspector: MeasurerInspector
    
    @State private var selected: Int = 1
    
    var body: some View {
        ZStack {
            Color(red: 0.15, green: 0.1, blue: 0.2)
            
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            LoadDirectoryButton()
                            Text(self.mainInspector.loadedMeasurementName ?? "-")
                        }
                        HStack {
                            LoadCsvButton()
                            Text(self.mainInspector.loadedRealMesurementName ?? "-")
                        }
                    }
                    .frame(minWidth: 150, minHeight: 50)
                    .padding()
                    
                    Spacer()
                        .frame(minWidth: 30)
                    
                    Picker("Inspected Measure", selection: $mainInspector.inspectedMeasureIndex) {
                        ForEach(0 ..< self.mainInspector.inspectableMeasures.count, id: \.self) { i in
                            Text(self.mainInspector.inspectableMeasures[i])
                        }
                    }
                    .disabled(mainInspector.inspectableMeasures.isEmpty)
                    .frame(minWidth: 200.0)
                    .padding()
                    
                }
                
                AxeGraphView(dataSource: self.mainInspector)
                    .foregroundColor(.white)
                    .frame(maxHeight: .infinity)
                
            }
            
        }
    }
}

struct LoadDirectoryButton: View {
    
    @EnvironmentObject var mainInspector: MeasurerInspector
    
    @State private var hadLoadingError: Bool = false
    @State private var loadingError: Error?
    
    var body: some View {
        Button("Load folder") {
            let dialog = NSOpenPanel()
            dialog.title = "Open Measurements_Result directory"
            dialog.canChooseDirectories = true
            dialog.canChooseFiles = false
            
            if dialog.runModal() == .OK {
                if let targetUrl = dialog.url {
                    do {
                        try self.mainInspector.loadDirectory(url: targetUrl)
                    } catch let e {
                        self.loadingError = e
                        self.hadLoadingError = true
                    }
                }
            }
        }
        .alert(isPresented: $hadLoadingError) {
            Alert(title: Text("Error while loading directory"),
                  message: Text(self.loadingError?.localizedDescription ?? ""))
        }
    }
}

struct LoadCsvButton: View {
    
    @EnvironmentObject var mainInspector: MeasurerInspector
    
    @State private var hadLoadingError: Bool = false
    @State private var loadingError: Error?
    
    var body: some View {
        Button("Load csv file") {
            let dialog = NSOpenPanel()
            dialog.title = "Open real measures file"
            dialog.canChooseDirectories = false
            dialog.canChooseFiles = true
            
            if dialog.runModal() == .OK {
                if let targetUrl = dialog.url {
                    do {
                        try self.mainInspector.loadCsvMeasures(url: targetUrl)
                    } catch let e {
                        self.loadingError = e
                        self.hadLoadingError = true
                    }
                }
            }
        }
        .alert(isPresented: $hadLoadingError) {
            Alert(title: Text("Error while loading file"),
                  message: Text(self.loadingError?.localizedDescription ?? ""))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
