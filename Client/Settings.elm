module Settings exposing (..)

import Domain.Core exposing (..)
import Tests.TestAPI as TestAPI exposing (..)
import Services.Server as Services exposing (..)


configuration : Configuration
configuration =
    Isolation


type Configuration
    = Integration
    | Isolation


type alias Dependencies =
    { tryLogin : Loginfunction
    , latestLinks : LatestLinksfunction
    , contributors : Contributorsfunction
    , contributor : Contributorfunction
    , links : ContentTypefunction
    , topicLinks : TopicLinksfunction
    , usernameToId : UserNameToIdfunction
    , connections : Connectionsfunction
    }


runtime : Dependencies
runtime =
    case configuration of
        Integration ->
            Dependencies
                Services.tryLogin
                Services.latestLinks
                Services.contributors
                Services.contributor
                Services.links
                Services.topicLinks
                Services.usernameToId
                Services.connections

        Isolation ->
            Dependencies
                TestAPI.tryLogin
                TestAPI.latestLinks
                TestAPI.contributors
                TestAPI.contributor
                TestAPI.links
                TestAPI.topicLinks
                TestAPI.usernameToId
                TestAPI.connections
