//
//  Version.swift
//  jiraupdater
//
//  Created by Shane Zatezalo on 6/16/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation
import Swift
import JiraToolsKit
import Result
import Commandant

private let version = "0.1" // FIXME. See TODO below.

/// Provide the Version of JiraUpdater
public struct VersionCommand: CommandType {
    public let verb = "version"
    public let function = "Display the current version of JiraUpdater"
    
    public func run(options: NoOptions<JiraUpdaterError>) -> Result<(), JiraUpdaterError> {
        print(version) // TODO. How to get a bundle for an app where you're running the app's executable w/o the app?
        return .Success(())
    }
}
