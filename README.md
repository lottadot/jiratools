## Jira tools

### 

This repo will contain a collection of tiny useful tools for Jira and CI. As of 2016-08-18 it consists of only one tool, `jiraupdater`.

### Jira Updater Tool


#### Description 

A macOS command line program to change the status of [JIRA](https://www.atlassian.com/software/jira) ticket(s) (and optionally post a comment to the ticket).

#### Why?

I created this to use it in our CI Environment. And also, possibly in the future, use the included Framework in future Jira related tools and features.

##### How To use this?

```
 jiraupdater help
Available commands:

   changelog   Update Jira tickets from a Changelog file. Default filename 'CHANGELOG'
   comment     Comment on a Jira Ticket
   help        Display general or command-specific help
   update      Update a Jira Ticket
   version     Display the current version of JiraUpdater
```

ie 

```
 jiraupdater help update
Update a Jira Ticket

[--endpoint (string)]
	the JIRA API EndPoint URL ie http://jira.example.com/

[--username (string)]
	the username to authenticate with

[--password (string)]
	the password to authenticate with

[--transitionname (string)]
	the Jira Transition to apply ie 'QA Ready'

[--issueids (string)]
	comma delim'd issue list. Atleast one is required.

[--comment (string)]
	the comment to post to the issue. Optional.
```

```
jiraupdater update --endpoint "http://localhost:2990/jira" --username mysecretusername --password mysecretpassword  --issueid TP1-1 --transitionname "QA Ready"
``` 
or

```
jiraupdater update --endpoint "http://localhost:2990/jira" --username mysecretusername --password mysecretpassword  --issueids TP1-1 --transitionname "QA Ready" --comment "This is available in v1.0 build #30 2016-06-16"
``` 
or

```
jiraupdater comment --endpoint "http://localhost:2990/jira" --username mysecretusername --password mysecretpassword  --issueids TP1-1 --comment "Bugs Bunny is funny."
```
or
```
jiraupdater comment --endpoint "http://localhost:2990/jira" --username mysecretusername --password mysecretpassword  --issueids TP1-1,TP=2 --comment "Ready for QA in v2.1 build #10"
```

Or if you'd like it to parse a changelog: (see [ChangelogKit](https://github.com/lottadot/Changelogkit) and [ChangelogParser](https://github.com/lottadot/ChangelogParser))

```
$ jiraupdater help changelog
Update Jira tickets from a Changelog

[--endpoint (string)]
	the JIRA API EndPoint URL ie http://jira.example.com/

[--username (string)]
	the username to authenticate with

[--password (string)]
	the password to authenticate with

[--transitionname (string)]
	the Jira Transition to apply ie 'QA Ready'

[--comment (string)]
	the templated ({VERSION}, {BUILDNUMBER}) comment to post to the issue. Optional.

[--file (string)]
	The absolute path of the changelog file to use.
```

so

```
jiraupdater changelog --endpoint "http://localhost:2990/jira" --username mysecretusername --password mysecretpassword  --file CHANGELOG --comment "Ready for QA in v2.1 build #10"
```

or, since we default to a filename of `CHANGELOG` (note it's case specific depending on your file system choices):

```
jiraupdater changelog --endpoint "http://localhost:2990/jira" --username mysecretusername --password mysecretpassword --comment "Ready for QA in v2.1 build #10"
```

or if you're providing Jira Endpoint information via environment variables:

```
jiraupdater changelog --comment "Ready for QA in v2.1 build #10"
```

or, at it's *most simplest* let it build the comment text for you based on the version/build information in the `CHANGELOG` file:

```
jiraupdater changelog
```

##### Security

As a convenience (ie you'd like to use this in a CI setup, etc), you can alternatively provide the URL, username and password via environment variables:

```
export JIRAUPDATER_ENDPOINT=http://localhost:2990/jira
export JIRAUPDATER_USERNAME=yourusername
export JIRAUPDATER_PASSWORD=yourpassword
```

###### Things to note

* Basic Authentication *must* be enabled on your `JIRA` installation.
* Some JIRA setups (can) prevent posting a comment when transitioning ('`Updating`' in `jiraupdatetool-speak`) an issue from one Workflow status to another. And it won't necessarily return an error in this configuration when attempted. If your Jira setup is like this, either:

1. consider changing the setup, or 
2. don't use `--comment` with `update`. Instead post the comment with `comment` command alone.

As of version `0.3.4`, we have tested this against Jira versions up to `1000.552.6` build number `100018` build revision `e2f2197b6871d3361a4e256e981b8b6c4e00960b` (you can view that information in your cloud host with this URL `https://example.atlassian.net/secure/admin/ViewSystemInfo.jspa`.

##### Trial Jira Instance

###### The new Cloud way

Jira will now create a development instance for you in the cloud. I highly recommend this method: [Jira Cloud Development Environment Information](https://developer.atlassian.com/blog/2016/04/cloud-ecosystem-dev-env/).

###### The old local way

If you would like to try this but are hesitant to run it against your production `JIRA` instance, you can run a local development instance of `Jira` fairly easily. Follow the directions in the [JiraLottadotTools](https://github.com/lottadot/JiraLottadotTools) project.

###### Resources

* [JIRA API Docs](https://docs.atlassian.com/jira/REST/6.4.6/)
* [Atlassian Developers Homepage](https://developer.atlassian.com/index.html)
* [JIRA](https://www.atlassian.com/software/jira)

#### Get started - Installation

You have a number of choices for installation (we recommend the homebrew method):

##### From Source into /usr/local/bin
```
git clone https://github.com/lottadot/jiratools.git
cd jiratools
make prefix_install
```
##### From a package into /usr/local/bin
```
git clone https://github.com/lottadot/jiratools.git
cd jiratools
make install
```

##### Homebrew Tap

```
brew tap lottadot/homebrew-formulae
brew install jiratools
```

### License

JiraUpdateTool is released under the MIT License.

### Copyright

(c) 2016 Lottadot LLC. All Rights Reserved.

