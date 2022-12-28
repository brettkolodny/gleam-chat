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


type alias IncomingMsg =
    { tag : String, value : List String }


port sendMessage : PortMsg -> Cmd msg


port messageReceiver : (D.Value -> msg) -> Sub msg



-- MODEL


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
                    , jumpToBottom "chat"
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
    div [ class "flex flex-row gap-4" ]
        [ input
            [ type_ "text"
            , placeholder "Username"
            , onInput UsernameDraftChanged
            , on "keydown" (ifIsEnter (Connect model.usernameDraft))
            , class "w-full h-12 border border-pink-200 px-4 rounded-md"
            ]
            []
        , button
            [ class "w-36 bg-[#ffaff3] text-lg text-[#2f2f2f] font-semibold rounded-md"
            , onClick (Connect model.usernameDraft)
            ]
            [ text "Connect" ]
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
