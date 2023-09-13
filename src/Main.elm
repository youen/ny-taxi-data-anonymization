module Main exposing (..)

import Array
import Browser
import Date exposing (format, fromPosix, month)
import Element exposing (Color, Element, alignBottom, alignLeft, alignRight, alignTop, centerX, centerY, clip, clipX, clipY, column, el, explain, fill, fillPortion, height, html, htmlAttribute, image, link, maximum, minimum, padding, paddingEach, paddingXY, paragraph, px, rgb, rgb255, row, scrollbarX, scrollbarY, spaceEvenly, spacing, spacingXY, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input exposing (button)
import Html
import Html.Attributes exposing (attribute, class, src)
import Http exposing (Error(..))
import Json.Decode as Decode exposing (..)
import Platform.Cmd as Cmd
import Time exposing (Posix, millisToPosix, toHour, toMinute, toSecond, utc)
import Markdown exposing (toHtml)



-- Model


type alias TripData =
    { pickupDatetime : Posix
    , dropoffDatetime : Posix
    , passengerCount : Maybe Int
    , tripDistance : Float
    , puLocationID : Int
    , doLocationID : Int
    }


type alias Model =
    { currentStep : Int
    , status : Status
    }


type Step
    = TweetPresentation
    | PassengerHint
    | DateHint
    | LocationHint
    | Conclusion


type Status
    = LoadingData
    | Ready
    | LoadingError String


initModel : Model
initModel =
    { currentStep = 0
    , status = LoadingData
    }



-- Msg


type Msg
    = NextStep
    | GoTo Int



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NextStep ->
            let
                newstep =
                    model.currentStep + 1
            in
            if newstep < Array.length allSteps then
                ( { model | currentStep = newstep }, Cmd.none )

            else
                ( model, Cmd.none )

        GoTo step ->
            ( { model | currentStep = step }, Cmd.none )



-- Decoder


blue : Element.Color
blue =
    Element.rgb255 238 238 238


gray : Element.Color
gray =
    Element.rgb255 20 20 20


nextStepButton : Element Msg
nextStepButton =
    border <|
        button
            [ Background.color black
            , Element.focused
                [ Background.color gray ]
            , spaceEvenly
            , padding 10
            ]
            { onPress = Just NextStep, label = text "Continuer" }


type alias ImageDiffConfig =
    { label_before : String
    , img_before : String
    , label_after : String
    , img_after : String
    }


type Image
    = ImageSimple String
    | ImageDiff ImageDiffConfig


type alias StepContent =
    { image : Image
    , title : String
    , description : String
    , explication : List (Element Msg)
    }


fromMarkdown : String -> List (Element msg)
fromMarkdown source =
        List.map html  (Markdown.toHtml Nothing source)


allSteps : Array.Array StepContent
allSteps =
    Array.fromList
        [ { image = ImageSimple "images/photo-star.png"
          , title = "Les Secrets des Taxis de la Ville"
          , description =
                """Dans l'ombre de la métropole, une étoile déchue de l'écran partage un taxi avec ses deux filles. Mais où se dirigent-elles ? Les rumeurs bruissent, et la ville retient son souffle. Un mystère en devenir..."""
          , explication =
                fromMarkdown
                    """Les données des taxis de la ville de New York (NYC) sont publiées en open data, ce qui signifie qu'elles sont accessibles au public.
                   Ces données comprennent des informations spécifiques pour chaque trajet, notamment l'heure et la zone d'arrivée, l'heure et la zone de départ, ainsi que le nombre de passagers. 
                   Cependant, cette transparence a soulevé des préoccupations quant à la confidentialité des individus, car il existe des [cas documentés](https://www.gawker.com/the-public-nyc-taxicab-database-that-accidentally-track-1646724546) où l'analyse de ces données a permis de déterminer la destination d'une personne photographiée en train de monter dans un taxi.
                   """
          }
        , { image = ImageSimple "images/nombre_de_voyages_par_zone_d_arrivee-original-all.png"
          , title = "Le Tableau des Rendez-vous Secrets"
          , description =
                """Les données de taxi, l'heure de prise en charge, la destination, le nombre de passagers... Un jeu de données juteux exposé au grand jour. La carte se dévoile, détaillant chaque zone de départ et d'arrivée, telle une carte au trésor."""
          , explication = fromMarkdown """Dans cette étape, nous avons utilisé les données brutes des trajets de taxi pour créer une carte géographique détaillée des zones d'arrivée de taxi. Pour ce faire, nous avons associé chaque identifiant de zone d'arrivée (DOLocationID) aux coordonnées géographiques correspondantes à l'aide de la carte géographique des zones de taxi. Cela nous a permis de représenter chaque zone d'arrivée sur la carte, créant ainsi une visualisation initiale de la distribution des destinations de taxi."""
          }
        , { image =
                ImageDiff
                    { label_before = "non filtré"
                    , img_before = "images/nombre_de_voyages_par_zone_d_arrivee-original-all.png"
                    , label_after = "passagers = 3"
                    , img_after = "images/nombre_de_voyages_par_zone_d_arrivee-original-passenger.png"
                    }
          , title = "Le Filtrage du Silence"
          , description =
                """Avec une loupe virtuelle, nous réduisons les destinations possibles, filtrant les trajets à trois passagers. La carte se transforme, éclaircissant l'obscurité, mais le mystère demeure."""
          , explication = fromMarkdown """Lors de cette étape, nous avons appliqué un filtre sur le nombre de passagers pour ne conserver que les trajets avec trois passagers. Cela a réduit le nombre de destinations possibles, simplifiant ainsi la carte géographique. Nous avons effectué cette opération en filtrant les données brutes pour ne conserver que les trajets répondant à ce critère spécifique."""
          }
        , { image =
                ImageDiff
                    { label_before = "passagers = 3"
                    , img_before = "images/nombre_de_voyages_par_zone_d_arrivee-original-passenger.png"
                    , label_after = "+ filtre date"
                    , img_after = "images/nombre_de_voyages_par_zone_d_arrivee-original-date.png"
                    }
          , title = "Le Temps Cache ses Secrets"
          , description =
                """Les métadonnées révèlent l'heure de la photo. Le filtre temporel se resserre. La carte s'anime sous la lumière tamisée du crépuscule, mais le voile persiste."""
          , explication = fromMarkdown """Dans cette étape, nous avons utilisé les métadonnées de l'image de la star pour déterminer l'heure à laquelle la photo a été prise. En analysant ces métadonnées, nous avons filtré les données brutes des trajets pour ne conserver que les trajets qui correspondaient à l'heure de prise de la photo. Cela nous a permis de restreindre davantage la liste des destinations possibles, en fonction de l'heure exacte de la publication de la photo."""
          }
        , { image =
                ImageDiff
                    { label_before = "passagers + date"
                    , img_before = "images/nombre_de_voyages_par_zone_d_arrivee-original-date.png"
                    , label_after = "+ filtre zone"
                    , img_after = "images/nombre_de_voyages_par_zone_d_arrivee-original-localisation.png"
                    }
          , title = "L'Énigme du Quartier Soho"
          , description =
                """On reconait le quartier Soho sur le cliché, le voile qui entoure la destination se lève. La carte se simplifie, ne laissant qu'une seule destination : Midtown Center. Le mystère qui a enlacé la star et ses filles commence à se dissiper."""
          , explication = fromMarkdown """À ce stade, nous n'avons pas exploité la zones de départ, nous avons utilisé des informations visuelles de la photo de la star, en particulier l'angle de W. Broadway et Spring Street, pour déterminer que la zone de départ était le quartier Soho (zone 211). En conséquence, nous avons filtré les données brutes des trajets pour ne conserver que ceux dont la zone de départ correspondait au quartier Soho. Cela a réduit la liste des destinations possibles à une seule option, nous permettant de déduire la destination de la star."""
          }
        , { image = ImageSimple "images/photo-protection.png"
          , title = "L'Art de l'Anonymat"
          , description =
                """Le k-anonymat et la l-diversité deviennent nos alliés pour protéger l'identité des voyageurs. Une nouvelle carte, insaisissable, cache les véritables itinéraires."""
          , explication = fromMarkdown 
          """À ce point de l'enquête, nous abordons l'anonymisation des données, une étape cruciale pour préserver la confidentialité des trajets tout en maintenant la pertinence des données. Deux concepts clés entrent en jeu : le k-anonymat et la l-diversité.

Le k-anonymat garantit que chaque combinaison de quasi-identifiants, comprenant le nombre de passagers, l'heure de départ et la zone de départ, apparaît au moins k fois dans le jeu de données. Cette approche vise à restreindre la possibilité d'identifier un trajet spécifique, renforçant ainsi la protection de la vie privée des passagers.

La l-diversité s'assure que les groupes de trajets partageant les mêmes quasi-identifiants présentent une diversité suffisante dans leurs zones d'arrivée, évitant ainsi toute révélation involontaire de destinations particulières. Cette mesure contribue à maintenir un équilibre entre la confidentialité des trajets et la nécessité de conserver des données utiles pour l'analyse. 

L'outil `SIGO` facilite la mise en œuvre de ces techniques d'anonymisation de manière efficace et sécurisée."""
          }
        , { image = ImageSimple "images/identifiants_des_zones.png"
          , title = "La Distribution des Identifiants"
          , description = """La carte révèle des identifiants de zones, mais leur distribution est trop visible, mettant en péril l'anonymat des trajets. Leur agencement dévoile déjà des secrets."""
          , explication =
                fromMarkdown
                    """
Sigo construit un arbre de généralisation en séparant récursivement en deux parties le jeu de données selon chaque axes de l'espace des quasi-identifiants. Pour que la généralisation regroupe des données proches il est important d'avoir une relation d'ordre sur chaque axe.
                    
Par exemple, les dates sont bien ordonnées chronologiquement donc la généralisation va regrouper les trajets qui ont une heure de départ proches. Par contre les identifiants de zones ne sont pas ordonnée par proximité. Comme on peut le voir sur la carte des identifiants élevés (blanc) peuvent êtres entourés de zone avec des identifiants faible (sombre). par conséquence la généralisation va regrouper des zones tres éloignées géographiquements."""
          }
        , { image = ImageSimple "images/ordonnancement_des_zones.png"
          , title = "Le Voyageur de Commerce"
          , description = """Un étrange itinéraire se dessine, mais le voyageur reste invisible. Le calcul du plus court chemin révèle de nouvelles perspectives."""
          , explication =
                fromMarkdown
                    """Pour éviter le problème d'absence de relation d'ordre sémantique, il faut modifier l'indexation des zones pour redonner un sens de proxymité à la relation d'ordre. Nous avons choisi de calculer une aproximation du plus court chemin qui passe par toutes les zones. Nous avons determiné les centroïdes de chaque zone et établie une matrice de distance entre chaque zone. Chaque étape du chemin sera le nouvel indice de la zone correspondant. On peut constater sur la carte que les zones avec des indices proches sont géographiquement proches."""
          }
        , { image =
                ImageDiff
                    { label_before = "original"
                    , img_before = "images/nombre_de_voyages_par_zone_d_arrivee-original-all.png"
                    , label_after = "anonymisé"
                    , img_after = "images/nombre_de_voyages_par_zone_d_arrivee-sigo-all.png"
                    }
          , title = "Le Masque de l'Anonymat"
          , description =
                """Les données anonymisées ne révèlent aucune différence visible sur la distribution des trajets. La ville demeure insensible aux secrets enfouis."""
          , explication = fromMarkdown """Une fois les techniques de k-anonymat et de l-diversité appliquées, les données anonymisées sont révélées. À première vue, elles ne révèlent aucune différence visible sur la distribution des trajets par rapport à l'étape précédente. Cette étape démontre l'efficacité de l'anonymisation pour maintenir l'apparence générale des données intacte."""
          }
        , { image =
                ImageDiff
                    { label_before = "original"
                    , img_before = "images/nombre_de_voyages_par_zone_d_arrivee-original-passenger.png"
                    , label_after = "anonymisé"
                    , img_after = "images/nombre_de_voyages_par_zone_d_arrivee-sigo-passenger.png"
                    }
          , title = "Le Silence Anonyme"
          , description =
                """Le filtre du nombre de passagers ne dévoile rien de plus. Les ombres restent impénétrables."""
          , explication = fromMarkdown """Le filtrage du nombre de passagers se poursuit dans cette étape, mais il ne dévoile rien de plus. L'anonymisation protége les informations sensibles tout en préservant l'utilité des données. Cette étape met en évidence la robustesse de l'anonymisation face à différents types de requêtes."""
          }
        , { image =
                ImageDiff
                    { label_before = "original"
                    , img_before = "images/nombre_de_voyages_par_zone_d_arrivee-original-date.png"
                    , label_after = "anonymisé"
                    , img_after = "images/nombre_de_voyages_par_zone_d_arrivee-sigo-date.png"
                    }
          , title = "L'Heure de l'Oubli"
          , description =
                """Le temps ne trahit pas. Les mystères demeurent cachés dans les plis de la nuit."""
          , explication = fromMarkdown """L'anonymisation basée sur l'heure de départ continue de préserver la confidentialité des données, empêchant toute divulgation non autorisée des informations sensibles. Cette étape souligne l'importance de l'anonymisation temporelle pour garantir la protection des données des voyageurs."""
          }
        , { image =
                ImageDiff
                    { label_before = "original"
                    , img_before = "images/nombre_de_voyages_par_zone_d_arrivee-original-localisation.png"
                    , label_after = "anonymisé"
                    , img_after = "images/nombre_de_voyages_par_zone_d_arrivee-sigo-localisation.png"
                    }
          , title = "Le Quartier Oublié"
          , description =
                """Aucune destination ne transparaît. Les données ont été altérées pour garantir le 3-anonymat. Le secret de la star reste à jamais préservé."""
          , explication = fromMarkdown """Dans cette dernière étape, aucune destination respecte les trois critères. Les données ont été altérées de manière à garantir le 3-anonymat, empêchant ainsi toute déduction de la destination de la star."""
          }
        , { image = ImageSimple "images/mirror.png"
          , title = "Il Descendait des Taxis"
          , description =
                """Les reflets révèlent deux facettes du mystère. Le miroir dévoile un autre secret, une nouvelle quête commence"""
          , explication = fromMarkdown """Pour la recherche de la données sensible, la zone de destination, nous avons utilisé trois informations quasi-identifiantes : le nombre de passager, l'heure de départ et la la zone de départ. Mais à partir d'une photo d'un homme sortant d'un taxi nous pouvons avons un problème mirroir. la donnée sensible sera la zone de départ et les quasi-identifiants seront le nombre de passagers, l'heure d'arrivée, et la zone d'arrivée. Il faut donc protéger également le jeu de données contre ce type d'attaque. On peut soit modifier la configuration de SIGO pour ajouter les données sensibles et les quasi identiants. Soit faire une nouvelle passe d'anonymisation avec une configuration dédiée."""
          }
        , { image = ImageSimple "images/cgi_logo.jpg"
          , title = "Crédits"
          , description =
                """Au cœur des ruelles sombres de la métropole, se cache un mystère profondément enfoui dans les méandres du Salon de la data et de l'IA 2023. Cette page a été créée pour mettre en lumière les dangers qui guettent lorsque des données sensibles sont divulguées sans protection. Alors que les ombres du passé se dissipent lentement, une nouvelle quête commence, une quête pour la protection de la vie privée et la préservation des secrets.
                """
          , explication =
                fromMarkdown """
[SIGO](https://github.com/CGI-FR/SIGO), l'outil qui a rendu possible cette quête, est un projet open source développé et maintenu par CGI.

Pour en savoir plus sur notre suite d'outils ([LINO](https://github.com/CGI-FR/LINO), [PIMO](https://github.com/CGI-FR/PIMO), [SIGO](https://github.com/CGI-FR/SIGO)) et découvrir leur utilisation, consultez nos [tutorials](https://cgi-fr.github.io/lino-doc/).

Vous pouvez explorer les scripts utilisés pour cette investigation sur notre page [projet GitHub](https://github.com/youen/ny-taxi-data-anonymization).

N'hésitez pas à nous faire part de vos retours, commentaires ou suggestions en nous envoyant un e-mail à [LINO.fr@cgi.com](mailto:LINO.fr@cgi.com) ou en ouvrant des tickets sur notre projet GitHub. Vos contributions sont précieuses pour continuer à améliorer notre quête pour la protection des données et la résolution des mystères de l'open data.


> L'équipe CGI - LINO
"""
                    
          }
        ]


beforeAfterSlider : ImageDiffConfig -> Element Msg
beforeAfterSlider image_diff =
    html <|
        Html.node "img-comparison-slider"
            [ attribute "style" "white-space: normal" ]
            [ Html.figure
                [ attribute "slot" "first"
                , class "before"
                ]
                [ Html.img
                    [ src image_diff.img_before
                    ]
                    []
                , Html.figcaption []
                    [ Html.text image_diff.label_before ]
                ]
            , Html.figure
                [ attribute "slot" "second"
                , class "after"
                ]
                [ Html.img
                    [ src image_diff.img_after
                    ]
                    []
                , Html.figcaption []
                    [ Html.text image_diff.label_after ]
                ]
            ]


lien : String -> String -> Element Msg
lien url label =
    link [] { url = url, label = text label }


arianeView : Array.Array StepContent -> Int -> Element Msg
arianeView steps currentStep =
    row [ width fill, spaceEvenly ] <| List.map (arianeItemView <| currentStep) <| List.range 0 <| Array.length steps - 1


arianeItemView : Int -> Int -> Element Msg
arianeItemView currentStep index =
    button
        [ width <| px 10
        , height <| px 10
        , Border.solid
        , Border.width 2
        , if index < currentStep then
            Background.color white

          else
            Background.color black
        ]
        { onPress = Just <| GoTo index, label = text "" }


black : Color
black =
    rgb255 0 0 0


white : Color
white =
    rgb255 255 255 255


border : Element Msg -> Element Msg
border element =
    el
        [ Border.solid
        , Border.width 1
        , Border.color black
        , padding 2
        , Background.color <| rgb 1 1 1
        ]
        (el
            [ Border.solid
            , Border.width 1
            , Border.color black
            , padding 0
            , Background.color <| rgb 1 1 1
            ]
            element
        )


explicationView : Element Msg -> Element Msg
explicationView element =
    el
        [ Border.solid
        , Border.width 1
        , Border.color black
        , padding 2
        , Background.color <| rgb 1 1 1
        , centerX
        ]
        (el
            [ Border.solid
            , Border.width 1
            , Border.color black
            , padding 0
            , Background.color <| rgb 1 1 1
            , padding 10
            , Font.color black
            ]
            element
        )


showStep : StepContent -> List (Element Msg)
showStep step =
    [ -- arianeView allSteps currentStep
      paragraph [ centerX, Font.center, Font.bold, Font.size 32, width fill  , paddingEach { top = 20, bottom = 0, left = 0 , right = 0 } ] [ text step.title ]
    , el
        [ centerX
        , centerY
        , Border.rounded 10
        --, paddingEach { top = 10, bottom = 20, left = 10 , right = 10 }
        ]
      <|
        border
            (case step.image of
                ImageSimple imageSrc ->
                    image [ width fill ] { src = imageSrc, description = step.description }

                ImageDiff conf ->
                    beforeAfterSlider conf
            )
    , paragraph [ height fill, width <| maximum 500 fill, centerX, centerY, Font.justify, Font.size 20 ]
        [ el
            [ alignLeft
            , padding 2
            , Font.size 40
            ]
            (text <| String.left 1 step.description)
        , text <| String.dropLeft 1 step.description
        ]
    , explicationView <|
        paragraph
            [ height fill
            , width <| maximum 500 fill
            , centerX
            , centerY
            , Font.size 20
            , Border.dashed
            ]
            step.explication
    , el
        [ centerX
        , alignBottom
        , Border.solid
        , Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
        , Border.rounded 3
        , width (fill |> maximum 200)
        , height <| px 10
        , spacingXY 0 10
        ]
        Element.none
    ]


centerView : Model -> List (Element Msg)
centerView model =
    List.concat (List.map showStep <| Array.toList allSteps)


view model =
    [ Element.layout
        [ Background.color <| rgb 0.02 0.02 0.02 ]
        (Element.column
            [ width fill
            , height fill
            , centerX
            , centerY
            , padding 20
            , spacing 20
            , Font.color <| rgb 0.8 0.8 0.8
            , Font.family [ Font.typeface "Playfair Display" ]
            ]
            (centerView model)
        )
    ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- Main


init : () -> ( Model, Cmd Msg )
init _ =
    ( initModel, Cmd.none )


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view =
            \m ->
                { title = "Les Secrets des Taxis de la Ville"
                , body =
                    view m
                }
        }
