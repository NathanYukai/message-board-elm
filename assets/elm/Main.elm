module Main exposing (..)

import Html exposing (Html, button, input, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode as JD exposing (Decoder)
import Json.Encode as JE
import Phoenix
import Phoenix.Channel as Channel exposing (Channel)
import Phoenix.Presence as Presence exposing (Presence)
import Phoenix.Push as Push
import Phoenix.Socket as Socket exposing (AbnormalClose, Socket)


lobbySocket : String
lobbySocket =
    "ws://localhost:4000/socket/websocket"


socket : Socket Msg
socket =
    Socket.init lobbySocket


channel : Channel Msg
channel =
    Channel.init "room:lobby"
        -- register an handler for messages with a "new_msg" event
        |> Channel.on "shout" (\msg -> NewMsg msg)


type Msg
    = UpdateUserName String
    | Submit
    | NewMsg JD.Value


type alias Model =
    { history : List Message
    , userName : String
    , message : String
    }


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.ul [] [renderHistory model]
        , Html.div []
            [ input [ placeholder "Your Name" ] []
            , input [ placeholder "Message" ] []
            , button [ onClick Submit ] [ text "Send" ]
            ]
        ]


renderHistory : Model -> Html Msg
renderHistory model =
    List.map (\m -> Html.li [] [ text m.userName, text m.message ]) model.history
        |> Html.ul []

update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        UpdateUserName name ->
            { model | userName = name } ! []

        Submit ->
            let
                push =
                    Push.init "room:lobby" "shout"
                        |> Push.withPayload
                            (JE.object
                                [ ( "name", JE.string "what" )
                                , ( "message", JE.string "ever" )
                                ]
                            )
            in
            { model | message = "" } ! [ Phoenix.push lobbySocket push ]

        NewMsg payload ->
            case JD.decodeValue decodeNewMsg payload of
                Ok msg ->
                    { model | history = List.append model.history [ msg ] } ! []

                Err err ->
                    model ! []


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


init : ( Model, Cmd Msg )
init =
    ( { userName = ""
      , history = []
      , message = ""
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.connect socket [ channel ]


type alias Message
    = { userName : String, message : String }


decodeNewMsg : Decoder Message
decodeNewMsg =
    JD.map2 (\userName msg -> { userName = userName, message = msg })
        (JD.field "name" JD.string)
        (JD.field "message" JD.string)
