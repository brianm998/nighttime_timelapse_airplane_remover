import Foundation
import CoreGraphics
import Cocoa

/*

This file is part of the Nightime Timelapse Airplane Remover (ntar).

ntar is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

ntar is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with ntar. If not, see <https://www.gnu.org/licenses/>.

*/


@available(macOS 10.15, *)
var updateableProgressMonitor: UpdateableProgressMonitor?

@available(macOS 10.15, *)
actor UpdateableProgressMonitor {
    let number_of_frames: Int
    let maxConcurrent: Int
    
    var frames: [FrameProcessingState: Set<FrameAirplaneRemover>] = [:]
    init(frameCount: Int, maxConcurrent: Int) {
        self.number_of_frames = frameCount
        self.maxConcurrent = maxConcurrent
    }

    func stateChange(for frame: FrameAirplaneRemover, to new_state: FrameProcessingState) {
        let frame_index = frame.frame_index

        for state in FrameProcessingState.allCases {
            if state == new_state { continue }
            if var state_items = frames[state] {
                state_items.remove(frame)
                frames[state] = state_items
            }
        }
        if var set = frames[new_state] {
            set.insert(frame)
            frames[new_state] = set
        } else {
            frames[new_state] = [frame]
        }

        redraw()
    }

    func redraw() {

        guard let updateable = updateable else { return }

        var updates: [() async -> Void] = []
        
        if let detectingOutliers = frames[.detectingOutliers] {
            let progress =
              Double(detectingOutliers.count) /
              Double(self.maxConcurrent)        // XXX self.maxConcurrent
            updates.append() {
                await updateable.log(name: "detectingOutliers",
                                     message: progress_bar(length: self.maxConcurrent, // XXX get max number of frames
                                                           progress: progress) +
                                       " \(detectingOutliers.count) frames detecting outliers",
                                     value: 1)
            }
        }
        if let interFrameProcessing = frames[.interFrameProcessing] {
            let progress =
              Double(interFrameProcessing.count) /
              Double(self.maxConcurrent)        // XXX 36
            updates.append() {
                await updateable.log(name: "interFrameProcessing",
                                     message: progress_bar(length: self.maxConcurrent, // XXX get max number of frames
                                                           progress: progress) +
                                       " \(interFrameProcessing.count) frames inter frame processing",
                                     value: 3)
            }
            
        }
        if let outlierProcessingComplete = frames[.outlierProcessingComplete] {
            let progress =
              Double(outlierProcessingComplete.count) /
              Double(self.maxConcurrent)        // XXX 36
            updates.append() {
                await updateable.log(name: "outlierProcessingComplete",
                                     message: progress_bar(length: self.maxConcurrent, // XXX get max number of frames
                                                           progress: progress) +
                                       " \(outlierProcessingComplete.count) frames outlier processing complete",
                                     value: 4)
            }
        }
        if let painting = frames[.painting] {
            let progress =
              Double(painting.count) /
              Double(self.maxConcurrent)        // XXX self.maxConcurrent
            updates.append() {
                await updateable.log(name: "painting",
                                     message: progress_bar(length: self.maxConcurrent, // XXX get max number of frames
                                                           progress: progress) +
                                       " \(painting.count) frames painting",
                                     value: 5)
            }
        }
        if let writingOutputFile = frames[.writingOutputFile] {
            let progress =
              Double(writingOutputFile.count) /
              Double(self.maxConcurrent)        // XXX self.maxConcurrent
            updates.append() {
                await updateable.log(name: "writingOutputFile",
                                     message: progress_bar(length: self.maxConcurrent, // XXX get max number of frames
                                                           progress: progress) +
                                       " \(writingOutputFile.count) frames writing to disk",
                                     value: 6)
            }
        }
        if let complete = frames[.complete] {
            let progress =
              Double(complete.count) /
              Double(self.number_of_frames)
            updates.append() {
                await updateable.log(name: "complete",
                                     message: progress_bar(length: 50, progress: progress) +
                                       " \(complete.count) / \(self.number_of_frames) frames complete",
                                     value: 100)
            }
        } else {
            // log crap here
        }

        let fuck = updates
        
        Task(priority: .high) { for update in fuck { await update() } }
        
    }
}
