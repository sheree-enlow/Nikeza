module Home exposing (..)

import Settings exposing (runtime)
import Domain.Core as Domain exposing (..)
import Domain.ContentProvider as ContentProvider exposing (..)
import Controls.Login as Login exposing (..)
import Controls.ProfileThumbnail as ProfileThumbnail exposing (..)
import Controls.AddSource as AddSource exposing (..)
import Controls.NewLinks as NewLinks exposing (..)
import Controls.ContentProviderLinks as ContentProviderLinks exposing (..)
import Controls.ContentProviderContentTypeLinks as ContentProviderContentTypeLinks exposing (..)
import Controls.Register as Registration exposing (..)
import Controls.EditProfile as EditProfile exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onCheck, onInput)
import Navigation exposing (..)
import String exposing (..)


-- elm-live Home.elm --open --output=home.js
-- elm-make Home.elm --output=home.html
-- elm-package install elm-lang/navigation


main =
    Navigation.program UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = (\_ -> Sub.none)
        }



-- MODEL


type alias Model =
    { currentRoute : Navigation.Location
    , login : Login.Model
    , registration : Registration.Model
    , portal : Portal
    , contentProviders : List ContentProvider
    , selectedContentProvider : ContentProvider
    }


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    let
        contentProvider =
            case tokenizeUrl location.hash of
                [ "contentProvider", id ] ->
                    case runtime.contentProvider <| Id id of
                        Just contentProvider ->
                            contentProvider

                        Nothing ->
                            initContentProvider

                _ ->
                    initContentProvider
    in
        ( { currentRoute = location
          , login = Login.init
          , registration = Registration.model
          , portal = initPortal
          , contentProviders = runtime.contentProviders
          , selectedContentProvider = contentProvider
          }
        , Cmd.none
        )



-- UPDATE


type Msg
    = UrlChange Navigation.Location
    | OnLogin Login.Msg
    | ProfileThumbnail ProfileThumbnail.Msg
    | SourceAdded AddSource.Msg
    | ViewSources
    | AddNewLink
    | ViewLinks
    | EditProfile
    | NewLink NewLinks.Msg
    | ContentProviderLinksAction ContentProviderLinks.Msg
    | PortalLinksAction ContentProviderLinks.Msg
    | EditProfileAction EditProfile.Msg
    | ContentProviderContentTypeLinksAction ContentProviderContentTypeLinks.Msg
    | Search String
    | Register
    | OnRegistration Registration.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange location ->
            location |> navigate msg model

        Register ->
            ( model, Navigation.load <| "/#/register" )

        OnRegistration subMsg ->
            onRegistration subMsg model

        OnLogin subMsg ->
            onLogin subMsg model

        Search "" ->
            ( { model | contentProviders = runtime.contentProviders }, Cmd.none )

        Search text ->
            text |> matchContentProviders model

        ProfileThumbnail subMsg ->
            ( model, Cmd.none )

        ViewSources ->
            let
                pendingPortal =
                    model.portal
            in
                ( { model | portal = { pendingPortal | requested = Domain.ViewSources } }, Cmd.none )

        AddNewLink ->
            let
                pendingPortal =
                    model.portal
            in
                ( { model | portal = { pendingPortal | requested = Domain.AddLink } }, Cmd.none )

        ViewLinks ->
            let
                pendingPortal =
                    model.portal
            in
                ( { model | portal = { pendingPortal | requested = Domain.ViewLinks } }, Cmd.none )

        EditProfile ->
            let
                pendingPortal =
                    model.portal
            in
                ( { model | portal = { pendingPortal | requested = Domain.EditProfile } }, Cmd.none )

        SourceAdded subMsg ->
            onAddedSource subMsg model

        NewLink subMsg ->
            onNewLink subMsg model

        EditProfileAction subMsg ->
            onEditProfile subMsg model

        ContentProviderLinksAction subMsg ->
            case subMsg of
                ContentProviderLinks.ToggleAll _ ->
                    let
                        ( contentProvider, _ ) =
                            ContentProviderLinks.update subMsg model.selectedContentProvider
                    in
                        ( { model | selectedContentProvider = contentProvider }, Cmd.none )

                ContentProviderLinks.Toggle _ ->
                    let
                        ( contentProvider, _ ) =
                            ContentProviderLinks.update subMsg model.selectedContentProvider
                    in
                        ( { model | selectedContentProvider = contentProvider }, Cmd.none )

        PortalLinksAction subMsg ->
            onPortalLinksAction subMsg model

        ContentProviderContentTypeLinksAction subMsg ->
            case subMsg of
                ContentProviderContentTypeLinks.ToggleAll _ ->
                    let
                        ( contentProvider, _ ) =
                            ContentProviderContentTypeLinks.update subMsg model.selectedContentProvider
                    in
                        ( { model | selectedContentProvider = contentProvider }, Cmd.none )

                ContentProviderContentTypeLinks.Toggle _ ->
                    let
                        ( contentProvider, _ ) =
                            ContentProviderContentTypeLinks.update subMsg model.selectedContentProvider
                    in
                        ( { model | selectedContentProvider = contentProvider }, Cmd.none )


onPortalLinksAction : ContentProviderLinks.Msg -> Model -> ( Model, Cmd Msg )
onPortalLinksAction subMsg model =
    case subMsg of
        ContentProviderLinks.ToggleAll _ ->
            let
                ( contentProvider, _ ) =
                    ContentProviderLinks.update subMsg model.portal.contentProvider

                pendingPortal =
                    model.portal
            in
                ( { model | portal = { pendingPortal | contentProvider = contentProvider } }, Cmd.none )

        ContentProviderLinks.Toggle _ ->
            let
                ( contentProvider, _ ) =
                    ContentProviderLinks.update subMsg model.portal.contentProvider

                pendingPortal =
                    model.portal
            in
                ( { model | portal = { pendingPortal | contentProvider = contentProvider } }, Cmd.none )


onEditProfile : EditProfile.Msg -> Model -> ( Model, Cmd Msg )
onEditProfile subMsg model =
    let
        updatedProfile =
            EditProfile.update subMsg model.portal.contentProvider.profile

        portal =
            model.portal

        contentProvider =
            model.portal.contentProvider

        newState =
            { model | portal = { portal | contentProvider = { contentProvider | profile = updatedProfile } } }
    in
        case subMsg of
            EditProfile.FirstNameInput _ ->
                ( newState, Cmd.none )

            EditProfile.LastNameInput _ ->
                ( newState, Cmd.none )

            EditProfile.EmailInput _ ->
                ( newState, Cmd.none )

            EditProfile.BioInput _ ->
                ( newState, Cmd.none )

            EditProfile.Save v ->
                ( { model
                    | portal =
                        { portal
                            | contentProvider = { contentProvider | profile = v }
                            , sourcesNavigation = True
                            , linksNavigation = not <| contentProvider.links == initLinks
                            , requested = Domain.ViewSources
                        }
                  }
                , Cmd.none
                )


onRegistration : Registration.Msg -> Model -> ( Model, Cmd Msg )
onRegistration subMsg model =
    let
        form =
            Registration.update subMsg model.registration
    in
        case subMsg of
            Registration.FirstNameInput _ ->
                ( { model | registration = form }, Cmd.none )

            Registration.LastNameInput _ ->
                ( { model | registration = form }, Cmd.none )

            Registration.EmailInput _ ->
                ( { model | registration = form }, Cmd.none )

            Registration.PasswordInput _ ->
                ( { model | registration = form }, Cmd.none )

            Registration.ConfirmInput _ ->
                ( { model | registration = form }, Cmd.none )

            Registration.Submit _ ->
                case form |> runtime.tryRegister of
                    Ok user ->
                        let
                            newState =
                                { model
                                    | registration = form
                                    , portal =
                                        { initPortal
                                            | contentProvider = user
                                            , requested = Domain.EditProfile
                                            , linksNavigation = False
                                            , sourcesNavigation = False
                                        }
                                }
                        in
                            ( newState, Navigation.load <| "/#/" ++ getId user.profile.id ++ "/dashboard" )

                    Err v ->
                        ( model, Cmd.none )


onRemove : Model -> Source -> ( Model, Cmd Msg )
onRemove model sources =
    let
        contentProvider =
            model.portal.contentProvider

        profile =
            contentProvider.profile

        sourcesLeft =
            profile.sources |> List.filter (\c -> c /= sources)

        updatedProfile =
            { profile | sources = sourcesLeft }

        updatedContentProvider =
            { contentProvider | profile = updatedProfile }

        pendingPortal =
            model.portal

        portal =
            { pendingPortal
                | contentProvider = updatedContentProvider
                , newSource = initSource
            }

        newState =
            { model | portal = portal }
    in
        ( newState, Cmd.none )


onNewLink : NewLinks.Msg -> Model -> ( Model, Cmd Msg )
onNewLink subMsg model =
    let
        pendingPortal =
            model.portal

        contentProvider =
            model.portal.contentProvider

        newLinks =
            NewLinks.update subMsg pendingPortal.newLinks

        portal =
            { pendingPortal | newLinks = newLinks }
    in
        case subMsg of
            NewLinks.InputTitle _ ->
                ( { model | portal = portal }, Cmd.none )

            NewLinks.InputUrl _ ->
                ( { model | portal = portal }, Cmd.none )

            NewLinks.InputTopic _ ->
                ( { model | portal = portal }, Cmd.none )

            NewLinks.RemoveTopic _ ->
                ( { model | portal = portal }, Cmd.none )

            NewLinks.AssociateTopic _ ->
                ( { model | portal = portal }, Cmd.none )

            NewLinks.InputContentType _ ->
                ( { model | portal = portal }, Cmd.none )

            NewLinks.AddLink v ->
                let
                    updatedLinks =
                        { newLinks | canAdd = True, added = v.current.base :: v.added }

                    updatedPortal =
                        { portal | newLinks = updatedLinks, linksNavigation = True }
                in
                    ( { model | portal = updatedPortal }
                    , Cmd.none
                    )


onAddedSource : AddSource.Msg -> Model -> ( Model, Cmd Msg )
onAddedSource subMsg model =
    let
        pendingPortal =
            model.portal

        contentProvider =
            model.portal.contentProvider

        updatedProfile =
            contentProvider.profile

        addSourceModel =
            AddSource.update subMsg { source = pendingPortal.newSource, sources = contentProvider.profile.sources }

        updatedContentProvider =
            { contentProvider | profile = { updatedProfile | sources = addSourceModel.sources } }

        portal =
            { pendingPortal
                | newSource = addSourceModel.source
                , contentProvider = updatedContentProvider
            }
    in
        case subMsg of
            AddSource.InputUsername _ ->
                ( { model | portal = portal }, Cmd.none )

            AddSource.InputPlatform _ ->
                ( { model | portal = portal }, Cmd.none )

            AddSource.Add _ ->
                ( { model
                    | portal =
                        { portal
                            | linksNavigation = not <| updatedContentProvider.links == initLinks
                            , addLinkNavigation = True
                            , sourcesNavigation = True
                        }
                  }
                , Cmd.none
                )

            AddSource.Remove _ ->
                if portal.contentProvider.links == initLinks then
                    ( { model
                        | portal =
                            { portal
                                | linksNavigation = False
                                , addLinkNavigation = True
                                , sourcesNavigation = True
                            }
                      }
                    , Cmd.none
                    )
                else
                    ( { model | portal = { portal | linksNavigation = True, sourcesNavigation = True } }, Cmd.none )


matchContentProviders : Model -> String -> ( Model, Cmd Msg )
matchContentProviders model matchValue =
    let
        isMatch name =
            name |> toLower |> contains (matchValue |> toLower)

        onFirstName contentProvider =
            contentProvider.profile.firstName |> getName |> isMatch

        onLastName contentProvider =
            contentProvider.profile.lastName |> getName |> isMatch

        onName contentProvider =
            onFirstName contentProvider || onLastName contentProvider

        filtered =
            runtime.contentProviders |> List.filter onName
    in
        ( { model | contentProviders = filtered }, Cmd.none )


onLogin : Login.Msg -> Model -> ( Model, Cmd Msg )
onLogin subMsg model =
    let
        pendingPortal =
            model.portal
    in
        case subMsg of
            Login.Attempt _ ->
                let
                    login =
                        Login.update subMsg model.login

                    latest =
                        runtime.tryLogin login

                    contentProviderResult =
                        runtime.contentProvider <| runtime.usernameToId latest.username

                    newState =
                        case contentProviderResult of
                            Just contentProvider ->
                                { model
                                    | login = latest
                                    , portal =
                                        { pendingPortal
                                            | contentProvider = contentProvider
                                            , requested = Domain.ViewLinks
                                            , sourcesNavigation = not <| List.isEmpty contentProvider.profile.sources
                                        }
                                }

                            Nothing ->
                                { model | login = latest }
                in
                    if newState.login.loggedIn then
                        ( newState, Navigation.load <| "/#/" ++ getId newState.portal.contentProvider.profile.id ++ "/dashboard" )
                    else
                        ( newState, Cmd.none )

            Login.UserInput _ ->
                ( { model | login = Login.update subMsg model.login }, Cmd.none )

            Login.PasswordInput _ ->
                ( { model | login = Login.update subMsg model.login }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    case model.currentRoute.hash |> tokenizeUrl of
        [] ->
            homePage model

        [ "home" ] ->
            homePage model

        [ "register" ] ->
            registerPage model

        [ "contentProvider", id ] ->
            case runtime.contentProvider <| Id id of
                Just _ ->
                    table []
                        [ tr []
                            [ table []
                                [ tr [] [ td [] [ img [ src <| getUrl <| model.selectedContentProvider.profile.imageUrl, width 100, height 100 ] [] ] ]
                                , tr [] [ td [] [ text <| getName model.selectedContentProvider.profile.firstName ++ " " ++ getName model.selectedContentProvider.profile.lastName ] ]
                                , tr [] [ td [] [ p [] [ text model.selectedContentProvider.profile.bio ] ] ]
                                ]
                            , td [] [ Html.map ContentProviderLinksAction <| ContentProviderLinks.view model.selectedContentProvider ]
                            ]
                        ]

                Nothing ->
                    notFoundPage

        [ "contentProvider", id, topic ] ->
            case runtime.contentProvider <| Id id of
                Just _ ->
                    contentProviderTopicPage model.selectedContentProvider

                Nothing ->
                    notFoundPage

        [ "contentProvider", id, "all", contentType ] ->
            case runtime.contentProvider <| Id id of
                Just _ ->
                    table []
                        [ tr []
                            [ table []
                                [ tr [] [ td [] [ img [ src <| getUrl <| model.selectedContentProvider.profile.imageUrl, width 100, height 100 ] [] ] ]
                                , tr [] [ td [] [ text <| getName model.selectedContentProvider.profile.firstName ++ " " ++ getName model.selectedContentProvider.profile.lastName ] ]
                                , tr [] [ td [] [ p [] [ text model.selectedContentProvider.profile.bio ] ] ]
                                ]
                            , td [] [ Html.map ContentProviderContentTypeLinksAction <| ContentProviderContentTypeLinks.view model.selectedContentProvider <| toContentType contentType ]
                            ]
                        ]

                Nothing ->
                    notFoundPage

        [ "contentProvider", id, topic, "all", contentType ] ->
            case runtime.contentProvider <| Id id of
                Just contentProvider ->
                    contentProviderTopicContentTypePage (Topic topic False) (toContentType contentType) contentProvider

                Nothing ->
                    notFoundPage

        [ id, "dashboard" ] ->
            dashboardPage model

        _ ->
            notFoundPage


homePage : Model -> Html Msg
homePage model =
    let
        loginUI : Model -> Html Msg
        loginUI model =
            let
                ( loggedIn, welcome, signout ) =
                    ( model.login.loggedIn
                    , p [] [ text <| "Welcome " ++ model.login.username ++ "!" ]
                    , a [ href "" ] [ label [] [ text "Signout" ] ]
                    )
            in
                if (not loggedIn) then
                    Html.map OnLogin <| Login.view model.login
                else
                    div [ class "signin" ] [ welcome, signout ]

        contentProvidersUI : Html Msg
        contentProvidersUI =
            Html.map ProfileThumbnail <|
                div [] (model.contentProviders |> List.map thumbnail)
    in
        div []
            [ header []
                [ label [] [ text "Nikeza" ]
                , br [] []
                , label [] [ i [] [ text "Linking Your Expertise" ] ]
                , model |> loginUI
                ]
            , input [ class "search", type_ "text", placeholder "name", onInput Search ] []
            , table []
                [ tr []
                    [ td [] [ div [] [ contentProvidersUI ] ]
                    , td [] [ button [ class "join", onClick Register ] [ text "Join!" ] ]
                    ]
                ]
            , footer [ class "copyright" ]
                [ label [] [ text "(c)2017" ]
                , a [ href "" ] [ text "GitHub" ]
                ]
            ]


registerPage : Model -> Html Msg
registerPage model =
    div []
        [ h3 [] [ text "Join" ]
        , Html.map OnRegistration <| Registration.view model.registration
        ]


contentProviderTopicContentTypePage : Topic -> ContentType -> ContentProvider.Model -> Html Msg
contentProviderTopicContentTypePage topic contentType model =
    let
        profileId =
            model.profile.id

        links =
            runtime.topicLinks topic Video profileId
    in
        div []
            [ h2 [] [ text <| "All " ++ contentTypeToText contentType ]
            , table []
                [ tr []
                    [ td [] [ img [ src <| getUrl <| model.profile.imageUrl, width 100, height 100 ] [] ]
                    , td [] [ h2 [] [ text <| getTopic topic ] ]
                    , td [] [ div [] <| List.map (\link -> a [ href <| getUrl link.url ] [ text <| getTitle link.title, br [] [] ]) links ]
                    ]
                ]
            ]


contentProviderTopicPage : ContentProvider.Model -> Html Msg
contentProviderTopicPage model =
    let
        profileId =
            model.profile.id

        contentTable topic =
            table []
                [ tr [] [ h2 [] [ text <| getTopic topic ] ]
                , tr []
                    [ td [] [ b [] [ text "Answers" ] ]
                    , td [] [ b [] [ text "Articles" ] ]
                    ]
                , tr []
                    [ td [] [ div [] <| contentWithTopicUI profileId Answer topic (runtime.topicLinks topic Answer profileId) ]
                    , td [] [ div [] <| contentWithTopicUI profileId Article topic (runtime.topicLinks topic Article profileId) ]
                    ]
                , tr []
                    [ td [] [ b [] [ text "Podcasts" ] ]
                    , td [] [ b [] [ text "Videos" ] ]
                    ]
                , tr []
                    [ td [] [ div [] <| contentWithTopicUI profileId Podcast topic (runtime.topicLinks topic Podcast profileId) ]
                    , td [] [ div [] <| contentWithTopicUI profileId Video topic (runtime.topicLinks topic Video profileId) ]
                    ]
                ]
    in
        case List.head model.topics of
            Just topic ->
                table []
                    [ tr []
                        [ td []
                            [ table []
                                [ tr [] [ td [] [ img [ src <| getUrl <| model.profile.imageUrl, width 100, height 100 ] [] ] ]
                                , tr [] [ td [] [ text <| getName model.profile.firstName ++ " " ++ getName model.profile.lastName ] ]
                                , tr [] [ td [] [ p [] [ text model.profile.bio ] ] ]
                                ]
                            ]
                        , td [] [ contentTable topic ]
                        ]
                    ]

            Nothing ->
                notFoundPage


content : Model -> Html Msg
content model =
    let
        contentProvider =
            model.portal.contentProvider
    in
        case model.portal.requested of
            Domain.ViewSources ->
                div []
                    [ Html.map SourceAdded <|
                        AddSource.view
                            { source = model.portal.newSource
                            , sources = model.portal.contentProvider.profile.sources
                            }
                    ]

            Domain.ViewLinks ->
                div [] [ Html.map PortalLinksAction <| ContentProviderLinks.view model.portal.contentProvider ]

            Domain.EditProfile ->
                div [] [ Html.map EditProfileAction <| EditProfile.view model.portal.contentProvider.profile ]

            Domain.AddLink ->
                let
                    linkSummary =
                        model.portal |> getLinkSummary

                    newLinkEditor =
                        Html.map NewLink (NewLinks.view (linkSummary))

                    addLink l =
                        div []
                            [ label [] [ text <| (l.contentType |> contentTypeToText |> dropRight 1) ++ ": " ]
                            , a [ href <| getUrl l.url ] [ text <| getTitle l.title ]
                            ]

                    update =
                        if linkSummary.canAdd then
                            div [] (linkSummary.added |> List.map addLink)
                        else
                            div [] []
                in
                    table []
                        [ tr []
                            [ td [] [ newLinkEditor ] ]
                        , tr []
                            [ td [] [ update ] ]
                        ]


getLinkSummary : Portal -> NewLinks
getLinkSummary portal =
    portal.newLinks


dashboardPage : Model -> Html Msg
dashboardPage model =
    let
        linkSummary =
            portal |> getLinkSummary

        header =
            h2 [] [ text <| "Welcome " ++ getName model.portal.contentProvider.profile.firstName ]

        portal =
            model.portal

        links =
            portal.contentProvider.links

        totalLinks =
            (List.length links.answers)
                + (List.length links.articles)
                + (List.length links.videos)
                + (List.length links.podcasts)

        profile =
            portal.contentProvider.profile

        sourcesText =
            "Sources " ++ "(" ++ (toString <| List.length profile.sources) ++ ")"

        linksText =
            "Links " ++ "(" ++ (toString totalLinks) ++ ")"

        renderNavigation =
            if not portal.sourcesNavigation && not portal.linksNavigation then
                [ div [ class "navigationpane" ]
                    [ button [ class "navigation", onClick EditProfile ] [ text "Profile" ]
                    , br [] []
                    , button [ class "navigation", onClick ViewSources, disabled True ] [ text sourcesText ]
                    , br [] []
                    , button [ class "navigation", onClick AddNewLink, disabled True ] [ text "Link" ]
                    ]
                ]
            else if portal.sourcesNavigation && not portal.linksNavigation then
                [ div [ class "navigationpane" ]
                    [ button [ class "navigation", onClick ViewSources ] [ text sourcesText ]
                    , br [] []
                    , button [ class "navigation", onClick AddNewLink ] [ text "Link" ]
                    , br [] []
                    , button [ class "navigation", onClick EditProfile ] [ text "Profile" ]
                    ]
                ]
            else
                [ div [ class "navigationpane" ]
                    [ button [ class "navigation", onClick ViewLinks ] [ text linksText ]
                    , br [] []
                    , button [ class "navigation", onClick AddNewLink ] [ text "Link" ]
                    , br [] []
                    , button [ class "navigation", onClick ViewSources ] [ text sourcesText ]
                    , br [] []
                    , button [ class "navigation", onClick EditProfile ] [ text "Profile" ]
                    ]
                ]
    in
        div []
            [ header
            , table []
                [ tr []
                    [ td []
                        [ table []
                            [ tr []
                                [ td [] [ img [ src <| getUrl <| model.portal.contentProvider.profile.imageUrl, width 100, height 100 ] [] ]
                                , td [] renderNavigation
                                ]
                            , tr [] [ td [] [ p [] [ text model.portal.contentProvider.profile.bio ] ] ]
                            ]
                        ]
                    , td [] [ content model ]
                    ]
                ]
            ]


notFoundPage : Html Msg
notFoundPage =
    div [] [ text "Page not found" ]


linksUI : List Link -> List (Html Msg)
linksUI links =
    links
        |> List.take 5
        |> List.map (\link -> a [ href <| getUrl link.url ] [ text <| getTitle link.title, br [] [] ])


contentWithTopicUI : Id -> ContentType -> Topic -> List Link -> List (Html Msg)
contentWithTopicUI profileId contentType topic links =
    List.append (linksUI links) [ a [ href <| getUrl <| moreContentProviderContentOnTopicUrl profileId contentType topic ] [ text <| "all", br [] [] ] ]



-- NAVIGATION


type alias RoutePath =
    List String


tokenizeUrl : String -> RoutePath
tokenizeUrl urlHash =
    urlHash |> String.split "/" |> List.drop 1


navigate : Msg -> Model -> Location -> ( Model, Cmd Msg )
navigate msg model location =
    case tokenizeUrl location.hash of
        [ "contentProvider", id ] ->
            case runtime.contentProvider <| Id id of
                Just c ->
                    ( { model | selectedContentProvider = c, currentRoute = location }, Cmd.none )

                Nothing ->
                    ( { model | currentRoute = location }, Cmd.none )

        [ "contentProvider", id, topic ] ->
            case runtime.contentProvider <| Id id of
                Just contentProvider ->
                    let
                        topicContentProvider =
                            { contentProvider | topics = [ Topic topic False ] }
                    in
                        ( { model | selectedContentProvider = topicContentProvider, currentRoute = location }, Cmd.none )

                Nothing ->
                    ( { model | currentRoute = location }, Cmd.none )

        _ ->
            ( { model | currentRoute = location }, Cmd.none )
