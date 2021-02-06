module Main exposing (main)

import Api.Generated
    exposing
        ( Book
        , Widget(..)
        , bookDecoder
        , widgetDecoder
        )
import Browser
import Html exposing (..)
import Json.Decode as D
import Widget.Book
import Widget.BookSearch

type Model
    = BookModel Widget.Book.Model
    | BookSearchModel Widget.BookSearch.Model
    | ErrorModel String


type Msg
    = GotBookMsg Widget.Book.Msg
    | GotBookSearchMsg Widget.BookSearch.Msg
    | WidgetErrorMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( GotBookMsg subMsg, BookModel book ) ->
            Widget.Book.update subMsg book
                |> updateWith BookModel GotBookMsg model

        ( GotBookSearchMsg subMsg, BookSearchModel subModel) ->
            Widget.BookSearch.update subMsg subModel
                |> updateWith BookSearchModel GotBookSearchMsg model


        ( WidgetErrorMsg, ErrorModel _ ) ->
            ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


updateWith :
    (subModel -> Model)
    -> (subMsg -> Msg)
    -> Model
    -> ( subModel, Cmd subMsg )
    -> ( Model, Cmd Msg )
updateWith toModel toMsg model ( subModel, subCmd ) =
    ( toModel subModel, Cmd.map toMsg subCmd )


subscriptions : Model -> Sub Msg
subscriptions parentModel =
    case parentModel of
        BookModel book ->
            Sub.map GotBookMsg 
                (Widget.Book.subscriptions book)

        BookSearchModel subModel ->
            Sub.map GotBookSearchMsg 
                (Widget.BookSearch.subscriptions subModel)

        ErrorModel err ->
            Sub.none


view : Model -> Html Msg
view model =
    case model of
        ErrorModel errorMsg ->
            errorView errorMsg

        BookSearchModel subModel ->
            Html.map GotBookSearchMsg (Widget.BookSearch.view subModel)

        BookModel book ->
            Html.map GotBookMsg (Widget.Book.view book)


errorView : String -> Html msg
errorView errorMsg =
    pre [] [ text "Widget Error: ", text errorMsg ]


main : Program D.Value Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


init : D.Value -> ( Model, Cmd Msg )
init flags =
    initiate flags


initiate : D.Value -> (Model, Cmd Msg)
initiate flags =
    case D.decodeValue widgetDecoder flags of
        Ok widget ->
            (widgetFlagToModel widget, widgetFlagToCmd widget)

        Err error ->
            (ErrorModel (D.errorToString error), Cmd.none)

widgetFlagToCmd : Widget -> Cmd Msg
widgetFlagToCmd widget =
    case widget of
        BookWidget _ ->
            Cmd.map GotBookMsg Widget.Book.initialCmd

        BookSearchWidget ->
            Cmd.map GotBookSearchMsg Widget.BookSearch.initialCmd


widgetFlagToModel : Widget -> Model
widgetFlagToModel widget =
    case widget of
        BookWidget book ->
            BookModel book

        BookSearchWidget ->
            BookSearchModel Widget.BookSearch.initialModel