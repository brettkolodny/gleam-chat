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


port sendMessage : PortMsg -> Cmd msg


port messageReceiver : (String -> msg) -> Sub msg



-- MODEL


type alias Model =
    { draft : String
    , messages : List String
    }


init : () -> ( Model, Cmd Msg )
init flags =
    ( { draft = "", messages = [] }
    , Cmd.none
    )



-- UPDATE


type Msg
    = DraftChanged String
    | Whisper
    | Yell
    | Recv String



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

        Whisper ->
            ( { model | draft = "" }
            , sendMessage { tag = "whisper", value = model.draft }
            )

        Yell ->
            ( { model | draft = "" }
            , sendMessage { tag = "yell", value = model.draft }
            )

        Recv message ->
            ( { model | messages = model.messages ++ [ message ] }
            , Cmd.none
            )



-- SUBSCRIPTIONS
-- Subscribe to the `messageReceiver` port to hear about messages coming in
-- from JS. Check out the index.html file to see how this is hooked up to a
-- WebSocket.
--


subscriptions : Model -> Sub Msg
subscriptions _ =
    messageReceiver Recv



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Echo Chat" ]
        , ul []
            (List.map (\msg -> li [] [ text msg ]) model.messages)
        , input
            [ type_ "text"
            , placeholder "Draft"
            , onInput DraftChanged
            , on "keydown" (ifIsEnter Yell)
            , value model.draft
            ]
            []
        , button [ onClick Yell ] [ text "Yell" ]
        , button [ onClick Whisper ] [ text "Whisper" ]
        ]



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
