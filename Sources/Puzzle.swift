//
//  Puzzle.swift
//
//
//  Created by Michael Brandt on 7/7/24.
//

import Foundation
import ArgumentParser

struct Puzzle {
    let sideByLetter: [Character:Int]
    let mask: Int
    private let maskByLetter: [Character:Int]
    
    init(_ str: String) throws {
        let splits = str.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        guard splits.count == 4 else {
            throw SimpleErr("Invalid number of sides in puzzle \"\(str)\"")
        }
        
        var fullMask = 0
        var maskByChar: [Character:Int] = [:]
        var sideByChar: [Character:Int] = [:]
        for i in 0..<splits.count {
            guard splits[i].count > 0 else {
                throw SimpleErr("Missing characters for a side in puzzle")
            }
            for ch in splits[i] {
                guard maskByChar[ch] == nil else {
                    // Could theoretically allow this without a huge refactor?
                    throw SimpleErr("Duplicate character '\(ch)' in puzzle")
                }
                sideByChar[ch] = i
                let thisMask = fullMask + 1
                maskByChar[ch] = thisMask
                fullMask |= thisMask
            }
        }
        
        self.sideByLetter = sideByChar
        self.mask = fullMask
        self.maskByLetter = maskByChar
    }
    
    func validateWord(_ word: String) -> ValidWord? {
        guard let firstCh = word.first, let lastCh = word.last else {
            return nil
        }
        
        var mask = 0
        var currentSide = -1
        for ch in word {
            guard let chSide = sideByLetter[ch], let chMask = maskByLetter[ch] else {
                return nil
            }
            guard chSide != currentSide else {
                return nil
            }
            mask |= chMask
            currentSide = chSide
        }
        
        return ValidWord(startChar: firstCh, endChar: lastCh, mask: mask)
    }
}
