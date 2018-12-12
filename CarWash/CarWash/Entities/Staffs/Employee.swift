//
//  Staff.swift
//  Employee
//
//  Created by Student on 10/25/18.
//  Copyright © 2018 Student. All rights reserved.
//

import Foundation

class Employee<ProcessedObject: MoneyGiver>: Person {
    

    var processingObjectsIsEmpty: Bool {
        return self.processingObjects.isEmpty
    }
    
    override var state: State {
        get { return self.atomicState.value }
        set {
            
            //self.atomicState.modify {
                guard self.state != newValue else { return }
                
                if newValue == .available && !self.processingObjectsIsEmpty {
                    self.atomicState.value = .busy
                    self.processingObjects.dequeue().do(self.asyncDoWork)
                } else {
                    self.atomicState.value = newValue
                }
                self.notify(state: self.atomicState.value)
            //}
        }
    }
    
    private let queue: DispatchQueue
    private let durationOfWork: ClosedRange<Double>
    private let processingObjects = Queue<ProcessedObject>()
    
    init(
        id: Int,
        durationOfWork: ClosedRange<Double> = 0.0...1.0,
        queue: DispatchQueue = .background
    ) {
        self.durationOfWork = durationOfWork
        self.queue = queue
        super.init(id: id)
    }
    
    func performProcessing(object: ProcessedObject) { }
    
    func completeProcessing(object: ProcessedObject) { }
    
    func completePerformWork() {
        if let processingObject = self.processingObjects.dequeue() {
            self.asyncDoWork(with: processingObject)
        } else {
            self.state = .waitForProcessing
        }
    }
    
    func performWork(
        processedObject: ProcessedObject
    ) {
        //self.synchronize {
            //var state = self.state
            self.atomicState.modify { state in
                if state == .available {
                    state = .busy
                    self.asyncDoWork(with: processedObject)
                } else {
                    self.processingObjects.enqueue(processedObject)
                }
            }
        //}
    }
    
    private func asyncDoWork(with
        processedObject: ProcessedObject
    ) {
        self.queue.asyncAfter(deadline: .afterRandomInterval(in: self.durationOfWork)) {
            self.performProcessing(object: processedObject)
            self.completeProcessing(object: processedObject)
            self.completePerformWork()
        }
    }
}