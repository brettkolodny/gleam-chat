port module Main exposing (..)

import Browser
import Browser.Dom as Dom
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as D
import Task



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- PORTS


type alias PortMsg =
    { tag : String
    , value : String
    }


type alias UserDetails =
    { name : String
    , colour : String
    }


type alias IncomingMsg =
    { author : String, content : String, colour : String }


type alias IncomingConnection =
    { name : String }


type alias IncomingDisconnection =
    { name : String }


port sendMessage : PortMsg -> Cmd msg


port connectUser : UserDetails -> Cmd msg


port messageReceiver : (D.Value -> msg) -> Sub msg


port connectionReceiver : (D.Value -> msg) -> Sub msg


port disconnectionReceiver : (D.Value -> msg) -> Sub msg



-- MODEL


type alias Message =
    { author : String, content : String, colour : UserColour }


type ChatItem
    = UserMessage Message
    | UserDisconnect String
    | UserConnect String


type UserColour
    = Pink
    | Blue
    | Aubergine
    | Charcoal


type alias Model =
    { draft : String
    , usernameDraft : String
    , username : Maybe String
    , chatItems : List ChatItem
    , showColourSelector : Bool
    , userColour : UserColour
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { draft = ""
      , chatItems = []
      , username = Nothing
      , usernameDraft = ""
      , showColourSelector = False
      , userColour = Charcoal
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = DraftChanged String
    | UsernameDraftChanged String
    | Send
    | NewMessage IncomingMsg
    | NewConnection IncomingConnection
    | NewDisconnection IncomingDisconnection
    | Connect
    | ToggleShowColourSelector
    | SetUserColour UserColour
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DraftChanged draft ->
            ( { model | draft = draft }
            , Cmd.none
            )

        UsernameDraftChanged draft ->
            ( { model | usernameDraft = draft }
            , Cmd.none
            )

        SetUserColour colour ->
            ( { model | userColour = colour }, Cmd.none )

        Send ->
            ( { model | draft = "" }
            , sendMessage { tag = "message", value = model.draft }
            )

        Connect ->
            let
                colourString =
                    case model.userColour of
                        Pink ->
                            "pink"

                        Charcoal ->
                            "charcoal"

                        Blue ->
                            "blue"

                        Aubergine ->
                            "aubergine"
            in
            ( { model | username = Just model.usernameDraft }
            , connectUser { colour = colourString, name = model.usernameDraft }
            )

        ToggleShowColourSelector ->
            ( { model | showColourSelector = not model.showColourSelector }, Cmd.none )

        NewMessage message ->
            let
                userColour =
                    case message.colour of
                        "charcoal" ->
                            Charcoal

                        "pink" ->
                            Pink

                        "blue" ->
                            Blue

                        "aubergine" ->
                            Aubergine

                        _ ->
                            Charcoal

                item =
                    UserMessage { author = message.author, content = message.content, colour = userColour }
            in
            ( { model | chatItems = model.chatItems ++ [ item ] }, Cmd.none )

        NewConnection connection ->
            let
                item =
                    UserConnect connection.name
            in
            ( { model | chatItems = model.chatItems ++ [ item ] }, Cmd.none )

        NewDisconnection disconnection ->
            let
                item =
                    UserDisconnect disconnection.name
            in
            ( { model | chatItems = model.chatItems ++ [ item ] }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ messageReceiver mapDecodeMessage
        , connectionReceiver mapDecodeConnection
        , disconnectionReceiver mapDecodeDisconnection
        ]


decodeMessage : D.Decoder IncomingMsg
decodeMessage =
    D.map3 IncomingMsg
        (D.field "author" D.string)
        (D.field "content" D.string)
        (D.field "colour" D.string)


mapDecodeMessage : D.Value -> Msg
mapDecodeMessage portmsgJson =
    case D.decodeValue decodeMessage portmsgJson of
        Ok msg ->
            NewMessage msg

        Err errorMessage ->
            let
                _ =
                    Debug.log "Error in mapWorkerUpdated:" errorMessage
            in
            NoOp


decodeConnection : D.Decoder IncomingConnection
decodeConnection =
    D.map IncomingConnection (D.field "name" D.string)


mapDecodeConnection : D.Value -> Msg
mapDecodeConnection incomingConnection =
    case D.decodeValue decodeConnection incomingConnection of
        Ok conn ->
            NewConnection conn

        Err errorMessage ->
            let
                _ =
                    Debug.log "Error in mapWorkerUpdated:" errorMessage
            in
            NoOp


decodeDisconnection : D.Decoder IncomingDisconnection
decodeDisconnection =
    D.map IncomingDisconnection (D.field "name" D.string)


mapDecodeDisconnection : D.Value -> Msg
mapDecodeDisconnection incomingDisconnection =
    case D.decodeValue decodeDisconnection incomingDisconnection of
        Ok conn ->
            NewDisconnection conn

        Err errorMessage ->
            let
                _ =
                    Debug.log "Error in mapWorkerUpdated:" errorMessage
            in
            NoOp



-- VIEW


view : Model -> Html Msg
view model =
    let
        inputElement =
            case model.username of
                Just _ ->
                    messageInput

                _ ->
                    connectInput
    in
    div [ class "flex flex-col justify-center items-center w-full h-screen bg-gray-100" ]
        [ div [ class "flex flex-col justify-center gap-4" ]
            [ h1 [ class "text-4xl font-bold" ] [ text "Gleam Chat" ]
            , div [ id "chat", class "p-4 w-[724px] border border-pink-200 h-[512px] rounded-md bg-white overflow-y-scroll" ]
                (List.map (\msg -> chatItemElement msg) model.chatItems)
            , inputElement model
            ]
        ]


messageInput : Model -> Html Msg
messageInput model =
    div [ class "flex flex-row gap-4" ]
        [ input
            [ type_ "text"
            , placeholder "Draft"
            , onInput DraftChanged
            , on "keydown" (ifIsEnter Send)
            , value model.draft
            , class "w-full h-12 border border-pink-200 px-4 rounded-md"
            ]
            []
        , button
            [ class "w-36 bg-[#ffaff3] text-lg text-[#2f2f2f] font-semibold rounded-md"
            , onClick Send
            ]
            [ text "Send" ]
        ]


connectInput : Model -> Html Msg
connectInput model =
    div [ class "flex flex-row space-between gap-4" ]
        [ input
            [ type_ "text"
            , placeholder "Username"
            , onInput UsernameDraftChanged
            , on "keydown" (ifIsEnter Connect)
            , class "w-full h-12 border border-pink-200 px-4 rounded-md"
            ]
            []
        , div [ class "flex flex-row gap-4" ]
            [ colourPicker model
            , button
                [ class "w-36 bg-[#ffaff3] text-lg text-[#2f2f2f] font-semibold rounded-md"
                , onClick Connect
                ]
                [ text "Connect" ]
            ]
        ]


chatItemElement : ChatItem -> Html Msg
chatItemElement chatItem =
    case chatItem of
        UserMessage msg ->
            let
                colourClass =
                    case msg.colour of
                        Pink ->
                            "text-[#d47dc7]"

                        Charcoal ->
                            "text-[#2f2f2f]"

                        Blue ->
                            "text-[#06aeca]"

                        Aubergine ->
                            "text-[#584355]"
            in
            div [ class colourClass ] [ text (msg.author ++ ": " ++ msg.content) ]

        UserDisconnect user ->
            div [] [ em [] [ text (user ++ " disconnected.") ] ]

        UserConnect user ->
            div [] [ em [] [ text (user ++ " connected.") ] ]


colourPicker : Model -> Html Msg
colourPicker model =
    let
        backgroundColour =
            case model.userColour of
                Pink ->
                    "bg-[#d47dc7]"

                Charcoal ->
                    "bg-[#2f2f2f]"

                Blue ->
                    "bg-[#06aeca]"

                Aubergine ->
                    "bg-[#584355]"
    in
    div [ class ("w-12 h-12 rounded-md " ++ backgroundColour ++ " cursor-pointer"), onClick ToggleShowColourSelector ]
        [ if model.showColourSelector then
            div [ class "absolute flex flex-row justify-evenly items-center gap-2 p-2 bg-white rounded-md transform translate-y-16" ]
                [ div [ class "w-8 h-8 bg-[#d47dc7] rounded-md", onClick (SetUserColour Pink) ] []
                , div [ class "w-8 h-8 bg-[#06aeca] rounded-md", onClick (SetUserColour Blue) ] []
                , div [ class "w-8 h-8 bg-[#2f2f2f] rounded-md", onClick (SetUserColour Charcoal) ] []
                , div [ class "w-8 h-8 bg-[#584355] rounded-md", onClick (SetUserColour Aubergine) ] []
                ]

          else
            div [] []
        ]



-- UTILITY


ifIsEnter : msg -> D.Decoder msg
ifIsEnter msg =
    D.field "key" D.string
        |> D.andThen
            (\key ->
                if key == "Enter" then
                    D.succeed msg

                else
                    D.fail "some other key"
            )


jumpToBottom : String -> Cmd Msg
jumpToBottom id =
    Dom.getViewportOf id
        |> Task.andThen (\info -> Dom.setViewportOf id 0 info.scene.height)
        |> Task.attempt (\_ -> NoOp)
