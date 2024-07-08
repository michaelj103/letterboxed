//
//  SolveCommand.swift
//
//
//  Created by Michael Brandt on 7/7/24.
//

import Foundation
import ArgumentParser

extension Letterboxed {
    struct SolveCommand: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "solve",
            abstract: "Find solutions for a puzzle given a wordlist"
        )
        
        @Option(name: [.customShort("p"), .customLong("puzzle")], help: "The puzzle: a comma-separated list of edges, e.g. 'abc,def,ghi,jkl'")
        var puzzleStr: String
        
        @Option(name: [.customShort("w"), .customLong("wordlist")], help: "The wordlist file")
        var wordlistFile: String
        
        @Flag(name: [.customShort("b"), .customLong("best-words")], help: "foo")
        var showBestWords: Bool = false
    
        func run() throws {
            let puzzle = try Puzzle(puzzleStr)
            let wordlist = try _readWordlist()
            let validWords = _getValidWords(puzzle, wordlist)
            print("Valid word count: \(validWords.count)")
            
            if showBestWords {
                let bestWords = _getBestWords(validWords, wordlist)
                print("Best Words:")
                for word in bestWords {
                    print(word)
                }
            }
            
            if let answer = _shortestSolution(puzzle, validWords) {
                let path = _constructPath(answer, validWords, wordlist)
                print("Found a solution with \(path.count) steps:")
                print(path.joined(separator: " -> "))
            } else {
                print("No solution found")
            }
        }
        
        // MARK: - Initial Parsing
        
        private func _readWordlist() throws -> [String] {
            let file = File(fileURL: URL(fileURLWithPath: wordlistFile))
            try file.open()
            
            var wordlist: [String] = []
            while let word = try file.readLine() {
                wordlist.append(word.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            return wordlist
        }
        
        private func _getValidWords(_ puzz: Puzzle, _ words: [String]) -> [ValidWordRef] {
            var validList: [ValidWordRef] = []
            for (idx, word) in words.enumerated() {
                guard word.count >= 3 else { continue }
                guard let validWord = puzz.validateWord(word) else { continue }
                validList.append(ValidWordRef(listIndex: idx, word: validWord))
            }
            return validList
        }
        
        // MARK: - Best words
        
        private func _getBestWords(_ validWords: [ValidWordRef], _ wordlist: [String]) -> [String] {
            var maxCount = 0
            var wordsWithCount: [String] = []
            for validWord in validWords {
                let usedLetters = _countBits(validWord.word.mask)
                if usedLetters > maxCount {
                    wordsWithCount = [wordlist[validWord.listIndex]]
                    maxCount = usedLetters
                } else if usedLetters == maxCount {
                    wordsWithCount.append(wordlist[validWord.listIndex])
                }
            }
            
            return wordsWithCount
        }
        
        private func _countBits(_ mask: Int) -> Int {
            var count = 0
            var remaining = mask
            while remaining > 0 {
                if remaining & 1 == 1 {
                    count += 1
                }
                remaining = remaining >> 1
            }
            return count
        }
        
        // MARK: - Graph Traversal
        
        private func _shortestSolution(_ puzzle: Puzzle, _ words: [ValidWordRef]) -> GraphAnswer? {
            var wordIdxByStartLetter: [Character:[Int]] = [:]
            for (idx, wordRef) in words.enumerated() {
                wordIdxByStartLetter[wordRef.word.startChar, default: []].append(idx)
            }
            
            var knownFrom: [GraphState:GraphTraversal] = [:]
            var currentStates = puzzle.sideByLetter.keys.map { GraphState(mask: 0, letter: $0) }
            
            while currentStates.count > 0 {
                var nextStates: [GraphState] = []
                for state in currentStates {
                    for wordIdx in wordIdxByStartLetter[state.letter, default: []] {
                        let wordRef = words[wordIdx]
                        let newMask = state.mask | wordRef.word.mask
                        let newState = GraphState(mask: newMask, letter: wordRef.word.endChar)
                        guard knownFrom[newState] == nil else { continue }
                        // new state reached
                        nextStates.append(newState)
                        let traversal = GraphTraversal(wordIdx: wordIdx, prevState: state)
                        knownFrom[newState] = traversal
                        if newState.mask == puzzle.mask {
                            // found solution
                            let answer = GraphAnswer(finalState: newState, traversals: knownFrom)
                            return answer
                        }
                    }
                }
                currentStates = nextStates
            }
            
            return nil
        }
        
        private func _constructPath(_ answer: GraphAnswer, _ wordRefs: [ValidWordRef], _ wordlist: [String]) -> [String] {
            var reversedPath: [String] = []
            var state = answer.finalState
            while true {
                if state.mask == 0 {
                    // initial state. Done
                    break
                }
                
                let traversal = answer.traversals[state]!
                let wordRef = wordRefs[traversal.wordIdx]
                let word = wordlist[wordRef.listIndex]
                reversedPath.append(word)
                state = traversal.prevState
            }
            
            return reversedPath.reversed()
        }
    }
}

// MARK: - Helper Objects

private struct GraphState: Hashable {
    let mask: Int
    let letter: Character
}

private struct GraphTraversal {
    let wordIdx: Int
    let prevState: GraphState
}

private struct GraphAnswer {
    let finalState: GraphState
    let traversals: [GraphState:GraphTraversal]
}
