module Style.Elements exposing (html, element, elementAs, optional, optionalAs, build, buildAs, svgAs)

{-|

# Creating Elements

@docs element, elementAs, svgAs, optional, optionalAs, html

# Building the Stylesheet

@docs build, buildAs

-}

import Style.Model exposing (..)
import Style.Render exposing (render, renderVariation)
import Style exposing (Model, Variation, ColorPalette, Text, Element, Animation, BackgroundImage)
import Html exposing (Html)
import Html.Attributes
import Svg.Attributes
import Color exposing (Color)
import Murmur3
import Json.Encode as Json
import Set exposing (Set)
import String
import Char


{-| -}
html : Html.Html msg -> Element msg
html node =
    ( []
    , node
    )


{-| Turn a style into an element that can be used to build your view.  Renders as a div.

-}
element : Model -> List (Html.Attribute msg) -> List (Element msg) -> Element msg
element =
    elementAs "div"


{-| Specify an html element name to render.
-}
elementAs : String -> Model -> List (Html.Attribute msg) -> List (Element msg) -> Element msg
elementAs node styleModel attrs elements =
    let
        ( className, styleDef ) =
            render styleModel

        ( childrenStyles, children ) =
            List.unzip elements

        allStyles =
            styleDef :: List.concat childrenStyles
    in
        ( allStyles
        , Html.node node (Svg.Attributes.class className :: attrs) children
        )


{-| Specify an svg node to use
-}
svgAs : String -> Model -> List (Html.Attribute msg) -> List (Element msg) -> Element msg
svgAs node styleModel attrs elements =
    let
        ( className, styleDef ) =
            render styleModel

        ( childrenStyles, children ) =
            List.unzip elements

        allStyles =
            styleDef :: List.concat childrenStyles
    in
        ( allStyles
        , Html.node node (Svg.Attributes.class className :: Html.Attributes.property "namespace" (Json.string "http://www.w3.org/2000/svg") :: attrs) children
        )


{-| Create an element with style variations that can be turned on/off.  The variations will stack.

-}
optional : Model -> List ( Style.Variation, Bool ) -> List (Html.Attribute msg) -> List (Element msg) -> Element msg
optional =
    optionalAs "div"


{-|
-}
optionalAs : String -> Model -> List ( Style.Variation, Bool ) -> List (Html.Attribute msg) -> List (Element msg) -> Element msg
optionalAs node styleModel variations attrs elements =
    let
        ( parentClass, styleDef ) =
            render styleModel

        variationTransitions =
            List.map
                (\( variation, active ) ->
                    ( renderVariation variation
                    , active
                    )
                )
                variations

        activatedVariationNames =
            List.filter snd variationTransitions
                |> List.map (\x -> fst <| fst x)
                |> List.foldl (++) ""

        ( childrenStyles, children ) =
            List.unzip elements

        allStyles =
            styleDef :: List.concat childrenStyles ++ List.map (\x -> snd (fst x)) variationTransitions
    in
        ( allStyles
        , Html.node node (Svg.Attributes.class (parentClass ++ " " ++ activatedVariationNames) :: attrs) children
        )


{-| Same as `element` except it will render all collected styles into an embedded stylesheet.  This needs to be at the top of all your elements for them to render correctly.

If this seems unclear, check out the examples!

-}
build : Model -> List (Html.Attribute msg) -> List ( List Style.Model.StyleDefinition, Html.Html msg ) -> Html msg
build =
    buildAs "div"


{-| -}
buildAs : String -> Model -> List (Html.Attribute msg) -> List ( List Style.Model.StyleDefinition, Html.Html msg ) -> Html msg
buildAs node styleModel attrs elements =
    let
        ( className, style ) =
            render styleModel

        ( childStyles, children ) =
            List.unzip elements

        allStyles =
            style
                :: List.concat childStyles
                |> Style.Render.convertToCSS

        stylesheet =
            Html.node "style"
                []
                [ Html.text <| allStyles
                  --floatError
                  --    ++ inlineError
                ]
    in
        Html.node node
            (Svg.Attributes.class className :: attrs)
            (stylesheet :: children)
