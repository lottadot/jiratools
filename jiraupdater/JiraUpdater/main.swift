//
//  main.swift
//  JiraUpdater
//
//  Created by Shane Zatezalo on 6/15/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation
import Swift
import JiraToolsKit
import Result
import Commandant

if let jiraUpdaterPath = NSBundle.mainBundle().executablePath {
    setenv("JIRAUPDATER_PATH", jiraUpdaterPath, 0)
}

/// TODO JiraUpdater's bundle identifier ?!?
//public let JiraUpdaterBundleIdentifier = NSBundle(forClass: Project.self).bundleIdentifier!

struct JiraUpdaterResult {
    var success = false
    var error: NSError? = nil
    var data: AnyObject? = nil
}

let registry = CommandRegistry<JiraUpdaterError>()
registry.register(VersionCommand())

let helpCommand = HelpCommand(registry: registry)
registry.register(helpCommand)

let updateCommand = UpdateCommand()
registry.register(updateCommand)

let changelogCommand = ChangelogCommand()
registry.register(changelogCommand)

let commentCommand = CommentCommand()
registry.register(commentCommand)

registry.main(defaultVerb: helpCommand.verb) { error in
    fputs(error.description + "\n", stderr)
}

NSApp.run()

