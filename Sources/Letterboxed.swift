//
//  Letterboxed.swift
//
//
//  Created by Michael Brandt on 7/7/24.
//

import ArgumentParser

@main
struct Letterboxed : ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "letterboxed",
        abstract: "Tool for solving the word game 'letterboxed'",
        subcommands: [SolveCommand.self]
    )
}
