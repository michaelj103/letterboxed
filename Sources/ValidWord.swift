//
//  ValidWord.swift
//
//
//  Created by Michael Brandt on 7/7/24.
//

import Foundation

struct ValidWord {
    let startChar: Character
    let endChar: Character
    let mask: Int
}

struct ValidWordRef {
    let listIndex: Int // index in the wordlist
    let word: ValidWord
}
