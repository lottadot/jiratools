## Jira Update Tool

#### Description 

A macOS command line program to change the status of a [JIRA](https://www.atlassian.com/software/jira) ticket (and optionally post a comment to the ticket).

#### Why?

I created this to use it in our CI Environment. And also, possibly in the future, use the included Framework in future Jira related tools and features.

##### How To use this?

```
 ./jiraupdater help
Available commands:

   comment   Comment on a Jira Ticket
   help      Display general or command-specific help
   update    Update a Jira Ticket
   version   Display the current version of JiraUpdater
```

ie 

```
 ./jiraupdater help update
Update a Jira Ticket

[--endpoint (string)]
	the JIRA API EndPoint URL ie http://jira.example.com/

[--username (string)]
	the username to authenticate with

[--password (string)]
	the password to authenticate with

[--issueid (string)]
	the Jira Ticket Id/Key

[--transitionname (string)]
	the Jira Transition to apply ie 'QA Ready'

[--comment (string)]
	the comment to post to the issue. Optional.
```

```
jiraupdater update --endpoint "http://localhost:2990/jira" --username mysecretusername --password mysecretpassword  --issueid TP1-1 --transitionname "QA Ready"
``` 
or

```
jiraupdater update --endpoint "http://localhost:2990/jira" --username mysecretusername --password mysecretpassword  --issueid TP1-1 --transitionname "QA Ready" --comment "This is available in v1.0 build #30 2016-06-16"
``` 
or

```
jiraupdater comment --endpoint "http://localhost:2990/jira" --username mysecretusername --password mysecretpassword  --issueid TP1-1 --comment "Bugs Bunny is funny."
```
##### Security

If you'd like to use this in a CI setup, you can alternatively provide the URL, username and password via environment variables:

```
export JIRAUPDATER_ENDPOINT=http://localhost:2990/jira
export JIRAUPDATER_USERNAME=yourusername
export JIRAUPDATER_PASSWORD=yourpassword
```

###### Things to note

* Basic Authentication must be enabled on your `JIRA` installation.
* Some JIRA setups (can) prevent posting a comment when transitioning ('`Updating`' in `jiraupdatetool-speak`) an issue from one Workflow status to another. And it won't necessarily return an error in this configuration when attempted. If your Jira setup is like this, either consider changing the setup, or don't use `--comment` with `update`. Instead post the comment with `--comment` alone.

##### Trial Jira Instance

If you would like to try this but are hesitant to run it against your production `JIRA` instance, you can run a local development instance of `Jira` fairly easily. Follow the directions in the [JiraLottadotTools](https://github.com/lottadot/JiraLottadotTools) project.

###### Resources

* [JIRA API Docs](https://docs.atlassian.com/jira/REST/6.4.6/)
* [Atlassian Developers Homepage](https://developer.atlassian.com/index.html)
* [JIRA](https://www.atlassian.com/software/jira)

#### Get started

```
git clone https://github.com/lottadot/jiratools.git
cd jiratools
carthage bootstrap
open JiraTools.xcworkspace
```

Then build the Xcode project with the `jiraupdater` build scheme. In the build products directory in your Derived Data you'll find the `jiraupdater` command line app.

## JiraToolsKit

JiraToolsKit is a macOS framework (written in swift) to communicate with the JIRA API. The command line jiraupdater uses the JiraToolsKit framework to communicate with JIRA. It is small and lightweight. It is in no way meant to be 100% **complete** towards the `JIRA` API - their API is **huge** - pull requests appreciated :)


### License

JiraUpdateTool And JiraToolksKit is released under the MIT License.

### Copyright

(c) 2016 Lottadot LLC. All Rights Reserved.

