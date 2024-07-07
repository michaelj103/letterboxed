//
//  SimpleErr.swift
//
//
//  Created by Michael Brandt on 7/7/24.
//

import Foundation

struct SimpleErr : Error {
    let description: String
    init(_ desc: String) {
        description = desc
    }
}
