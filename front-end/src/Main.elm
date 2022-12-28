port module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as D



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


type alias IncomingMsg =
    { tag : String, value : List String }


port sendMessage : PortMsg -> Cmd msg


port messageReceiver : (D.Value -> msg) -> Sub msg



-- MODEL
-- type ChatItem =


type alias Message =
    { author : String, content : String }


type ChatItem
    = UserMessage Message
    | UserDisconnect String
    | UserConnect String


type alias Model =
    { draft : String
    , usernameDraft : String
    , username : Maybe String
    , chatItems : List ChatItem
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { draft = "", chatItems = [], username = Nothing, usernameDraft = "" }
    , Cmd.none
    )



-- UPDATE


type Msg
    = DraftChanged String
    | UsernameDraftChanged String
    | Send
    | Recv IncomingMsg
    | Connect String
    | NoOp



-- Use the `sendMessage` port when someone presses ENTER or clicks
-- the "Send" button. Check out index.html to see the corresponding
-- JS where this is piped into a WebS'ocket.
--


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

        Send ->
            ( { model | draft = "" }
            , sendMessage { tag = "message", value = model.draft }
            )

        Connect username ->
            ( { model | username = Just username }, sendMessage { tag = "connect", value = username } )

        Recv message ->
            case message.tag of
                "new-message" ->
                    let
                        ( author, content ) =
                            case message.value of
                                [ a, c ] ->
                                    ( a, c )

                                _ ->
                                    ( "", "" )

                        item =
                            UserMessage { author = author, content = content }
                    in
                    ( { model | chatItems = model.chatItems ++ [ item ] }
                    , Cmd.none
                    )

                "user-disconnect" ->
                    let
                        user =
                            case message.value of
                                [ u ] ->
                                    u

                                _ ->
                                    ""

                        item =
                            UserDisconnect user
                    in
                    ( { model | chatItems = model.chatItems ++ [ item ] }, Cmd.none )

                "user-connect" ->
                    let
                        user =
                            case message.value of
                                [ u ] ->
                                    u

                                _ ->
                                    ""

                        item =
                            UserConnect user
                    in
                    ( { model | chatItems = model.chatItems ++ [ item ] }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS
-- Subscribe to the `messageReceiver` port to hear about messages coming in
-- from JS. Check out the index.html file to see how this is hooked up to a
-- WebSocket.
--


subscriptions : Model -> Sub Msg
subscriptions _ =
    messageReceiver mapDecode


decode : D.Decoder IncomingMsg
decode =
    D.map2 IncomingMsg
        (D.field "tag" D.string)
        (D.field "value" (D.list D.string))


mapDecode : D.Value -> Msg
mapDecode portmsgJson =
    case D.decodeValue decode portmsgJson of
        Ok msg ->
            Recv msg

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
    div []
        [ h1 [] [ text "Gleam Chat" ]
        , ul []
            (List.map (\msg -> chatItemElement msg) model.chatItems)
        , inputElement model
        ]


messageInput : Model -> Html Msg
messageInput model =
    div []
        [ input
            [ type_ "text"
            , placeholder "Draft"
            , onInput DraftChanged
            , on "keydown" (ifIsEnter Send)
            , value model.draft
            ]
            []
        , button [ onClick Send ] [ text "Yell" ]
        ]


connectInput : Model -> Html Msg
connectInput model =
    div []
        [ input
            [ type_ "text"
            , placeholder "Username"
            , onInput UsernameDraftChanged
            , on "keydown" (ifIsEnter (Connect model.usernameDraft))
            ]
            []
        , button [ onClick (Connect model.usernameDraft) ] [ text "Connect" ]
        ]


chatItemElement : ChatItem -> Html Msg
chatItemElement chatItem =
    case chatItem of
        UserMessage msg ->
            div [] [ text (msg.author ++ ": " ++ msg.content) ]

        UserDisconnect user ->
            div [] [ em [] [ text (user ++ " disconnected.") ] ]

        UserConnect user ->
            div [] [ em [] [ text (user ++ " connected.") ] ]



-- DETECT ENTER


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
