# tutorial-kriging
Tutorial de Kriging

* una cosa
* otra
* otra más

Puedes poner *cursivas* o **negritas**

Pero sobre todo puedes poner código:

## Parte 1 Leer datos

```` R
print("Reading data")
tuits <- read.csv(data_file, stringsAsFactors = FALSE)
print("Parsing dates")
tuits$Fecha_tweet <- parLapply(cl,tuits$Fecha_tweet, ftime)
tuits$Fecha_tweet <- as.POSIXct(strptime(tuits$Fecha_tweet,
                                         "%Y-%m-%d %H.%M.%OS"),
                                format="%Y-%m-%d %H.%M.%OS")
names(tuits)[names(tuits) == 'Fecha_tweet'] <- 'tstamp'
tuits$fecha <- as.Date(tuits$tstamp)
print("Classifying languages")
tuits$lang <- parLapply(cl,tuits$Texto,parseDetectLanguage)
tuits$lang <- as.character(tuits$lang)

````

## Parte 2 Graficar

## Parte 3 Semivariograma
