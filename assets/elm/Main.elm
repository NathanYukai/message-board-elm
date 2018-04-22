module Main exposing (..)

import Html exposing (Html, input, text)
import Html.Attributes exposing (..)


type Msg
    = UpdateUserName String


type alias Model =
    { history : List String
    , userName : String
    , message : String
    }


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.ul [] []
        , Html.div []
            [ input [ placeholder "Your Name" ] []
            , input [] []
            ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        UpdateUserName name ->
            { model | userName = name } ! []


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
    Sub.batch []
