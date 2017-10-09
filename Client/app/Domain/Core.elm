module Domain.Core exposing (..)


initForm : Form
initForm =
    Form "" "" "" "" ""


type alias Form =
    { firstName : String
    , lastName : String
    , email : String
    , password : String
    , confirm : String
    }


type alias Credentials =
    { email : String
    , password : String
    , loggedIn : Bool
    }


initTopics : List Topic
initTopics =
    []


type alias Portfolio =
    { answers : List Link
    , articles : List Link
    , videos : List Link
    , podcasts : List Link
    }


initPortfolio : Portfolio
initPortfolio =
    { answers = []
    , articles = []
    , videos = []
    , podcasts = []
    }


type Linksfrom
    = FromOther
    | FromPortal


type SubscriptionUpdate
    = Subscribe Id Id
    | Unsubscribe Id Id


type alias Provider =
    { profile : Profile
    , topics : List Topic
    , portfolio : Portfolio
    , filteredPortfolio : Portfolio
    , recentLinks : List Link
    , followers : Members
    , subscriptions : Members
    }


type Members
    = Members (List Provider)


initSubscription : Members
initSubscription =
    Members []


initProvider : Provider
initProvider =
    Provider initProfile initTopics initPortfolio initPortfolio [] initSubscription initSubscription


type alias Portal =
    { provider : Provider
    , sourcesNavigation : Bool
    , addLinkNavigation : Bool
    , linksNavigation : Bool
    , requested : ProviderRequest
    , newSource : Source
    , newLinks : NewLinks
    }


initPortal : Portal
initPortal =
    { provider = initProvider
    , sourcesNavigation = False
    , addLinkNavigation = False
    , linksNavigation = False
    , requested = EditProfile
    , newSource = initSource
    , newLinks = initNewLinks
    }


type alias Profile =
    { id : Id
    , firstName : Name
    , lastName : Name
    , email : Email
    , imageUrl : Url
    , bio : String
    , sources : List Source
    }


initProfile : Profile
initProfile =
    { id = Id undefined
    , firstName = Name undefined
    , lastName = Name undefined
    , email = Email undefined
    , imageUrl = Url undefined
    , bio = undefined
    , sources = []
    }


type Id
    = Id String


getId : Id -> String
getId id =
    let
        (Id value) =
            id
    in
        value


type Name
    = Name String


getName : Name -> String
getName name =
    let
        (Name value) =
            name
    in
        value


type Email
    = Email String


getEmail : Email -> String
getEmail email =
    let
        (Email value) =
            email
    in
        value


type Title
    = Title String


getTitle : Title -> String
getTitle title =
    let
        (Title value) =
            title
    in
        value


type Url
    = Url String


getUrl : Url -> String
getUrl url =
    let
        (Url value) =
            url
    in
        value


type alias Topic =
    { name : String, isFeatured : Bool }


getTopic : Topic -> String
getTopic topic =
    topic.name


type Platform
    = Platform String


getPlatform : Platform -> String
getPlatform platform =
    let
        (Platform value) =
            platform
    in
        value


type alias Link =
    { profile : Profile
    , title : Title
    , url : Url
    , contentType : ContentType
    , topics : List Topic
    , isFeatured : Bool
    }


type alias LinkToCreate =
    { base : Link, currentTopic : Topic }


initLink : Link
initLink =
    { profile = initProfile
    , title = Title ""
    , url = Url ""
    , contentType = Unknown
    , topics = []
    , isFeatured = False
    }


initLinkToCreate : LinkToCreate
initLinkToCreate =
    { base = initLink
    , currentTopic = Topic "" False
    }


type alias NewLinks =
    { current : LinkToCreate
    , canAdd : Bool
    , added : List Link
    }


initNewLinks : NewLinks
initNewLinks =
    { current = initLinkToCreate, canAdd = False, added = [] }


type alias Source =
    { platform : String, username : String, linksFound : Int }


initSource : Source
initSource =
    Source "" "" 0


type ProviderRequest
    = ViewSources
    | ViewLinks
    | AddLink
    | EditProfile
    | ViewSubscriptions
    | ViewFollowers
    | ViewProviders
    | ViewRecent



-- INTERFACES


type alias Sourcesfunction =
    Id -> List Source


type alias AddSourcefunction =
    Id -> Source -> Result String (List Source)


type alias RemoveSourcefunction =
    Id -> Source -> Result String (List Source)


type alias AddLinkfunction =
    Id -> Link -> Result String Portfolio


type alias RemoveLinkfunction =
    Id -> Link -> Result String Portfolio


type alias UserNameToIdfunction =
    String -> Id


type alias SuggestedTopicsfunction =
    String -> List Topic


type alias Followfunction =
    Id -> Id -> Result String ()


type alias Unsubscribefunction =
    Id -> Id -> Result String ()


type ContentType
    = Article
    | Video
    | Podcast
    | Answer
    | All
    | Unknown



-- FUNCTIONS


toggleFilter : Provider -> ( Topic, Bool ) -> Provider
toggleFilter provider ( topic, include ) =
    let
        contentTypeLinks contentType =
            case contentType of
                Article ->
                    provider.portfolio
                        |> getLinks All
                        |> List.filter (\l -> l.contentType == Article)

                Video ->
                    provider.portfolio
                        |> getLinks All
                        |> List.filter (\l -> l.contentType == Video)

                Podcast ->
                    provider.portfolio
                        |> getLinks All
                        |> List.filter (\l -> l.contentType == Podcast)

                Answer ->
                    provider.portfolio |> getLinks All |> List.filter (\l -> l.contentType == Answer)

                _ ->
                    []

        toggleTopic contentType links =
            if include then
                links |> List.append (contentTypeLinks contentType)
            else
                links |> List.filter (\link -> not (link.topics |> hasMatch topic))

        filtered =
            provider.filteredPortfolio
    in
        { provider
            | filteredPortfolio =
                { answers = filtered.answers |> toggleTopic Answer
                , articles = filtered.articles |> toggleTopic Article
                , videos = filtered.videos |> toggleTopic Video
                , podcasts = filtered.podcasts |> toggleTopic Podcast
                }
        }


compareLinks : Link -> Link -> Order
compareLinks a b =
    if a.isFeatured then
        LT
    else if b.isFeatured then
        GT
    else
        EQ


getLinks : ContentType -> Portfolio -> List Link
getLinks contentType links =
    case contentType of
        Answer ->
            links.answers

        Article ->
            links.articles

        Podcast ->
            links.podcasts

        Video ->
            links.videos

        Unknown ->
            []

        All ->
            links.answers
                ++ links.articles
                ++ links.podcasts
                ++ links.videos


hasMatch : Topic -> List Topic -> Bool
hasMatch topic topics =
    topics |> toTopicNames |> List.member (getTopic topic)


portfolioExists : Portfolio -> Bool
portfolioExists portfolio =
    not <| portfolio == initPortfolio


undefined : String
undefined =
    "undefined"


topicUrl : Id -> Topic -> Url
topicUrl id topic =
    Url undefined


toUrl : Link -> String
toUrl link =
    getUrl link.url


toTopicNames : List Topic -> List String
toTopicNames topics =
    topics |> List.map (\topic -> topic.name)


providerTopicUrl : Maybe Id -> Id -> Topic -> Url
providerTopicUrl loggedIn providerId topic =
    case loggedIn of
        Just userId ->
            Url <| "/#/portal/" ++ getId userId ++ "/provider/" ++ getId providerId ++ "/" ++ getTopic topic

        Nothing ->
            Url <| "/#/provider/" ++ getId providerId ++ "/" ++ getTopic topic


providerUrl : Maybe Id -> Id -> Url
providerUrl loggedIn providerId =
    case loggedIn of
        Just userId ->
            Url <| "/#/portal/" ++ getId userId ++ "/provider/" ++ getId providerId

        Nothing ->
            Url <| "/#/provider/" ++ getId providerId


toContentType : String -> ContentType
toContentType contentType =
    case contentType of
        "Articles" ->
            Article

        "Article" ->
            Article

        "Videos" ->
            Video

        "Video" ->
            Video

        "Podcasts" ->
            Podcast

        "Podcast" ->
            Podcast

        "Answers" ->
            Answer

        "Answer" ->
            Answer

        "Unknown" ->
            Unknown

        _ ->
            Unknown


contentTypeToText : ContentType -> String
contentTypeToText contentType =
    case contentType of
        Article ->
            "Articles"

        Video ->
            "Videos"

        Podcast ->
            "Podcasts"

        Answer ->
            "Answers"

        Unknown ->
            "Unknown"

        All ->
            "Content"


allContentUrl : Linksfrom -> Id -> ContentType -> Url
allContentUrl linksFrom id contentType =
    case linksFrom of
        FromOther ->
            Url <| "/#/provider/" ++ getId id ++ "/all/" ++ (contentType |> contentTypeToText)

        FromPortal ->
            Url <| "/#/portal/" ++ getId id ++ "/all/" ++ (contentType |> contentTypeToText)


allTopicContentUrl : Linksfrom -> Id -> ContentType -> Topic -> Url
allTopicContentUrl linksFrom id contentType topic =
    case linksFrom of
        FromOther ->
            Url <| "/#/provider/" ++ getId id ++ "/" ++ getTopic topic ++ "/all/" ++ (contentType |> contentTypeToText)

        FromPortal ->
            Url <| "/#/portal/" ++ getId id ++ "/" ++ getTopic topic ++ "/all/" ++ (contentType |> contentTypeToText)
