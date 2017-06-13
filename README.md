# Tutorial de Kriging usando R

En este taller vamos a usar el paquete [gstats](https://cran.r-project.org/web/packages/gstat/index.html) para interpolar
datos espaciales (georreferenciados) usando el método [Kriging](https://en.wikipedia.org/wiki/Kriging).

Antes de comenzar, necesitamos cargar (o instalar primero, en caso de que no estén
ya instaladas) las librerías que vamos a usar:

```` R
library(sp)
library(gstat)
library(ggplot2)
````

## Parte 1 Leer datos

Lo primero que vamos a hacer es leer los datos que vamos a interpolar, 
para eso vamos a usar el _dataset_ `meuse`
que forma parte del paquete gstats. Entonces, en la consola de R, 
lo único que tenemos que hacer es llamar a los datos:

```` R
?meuse
data("meuse")
class(meuse)
str(meuse)
````
Antes de continuar, vamos a calcular una columna con el Logaritmo 
de la cantidad de Zinc. Esto es una práctica común, para ampliar el rango de 
variación de los datos:

```` R
meuse$logZn <- log10(meuse$zinc)
View(meuse)
````


Como se puede ver, tenemos un `DataFrame` con mediciones de algunas variables para 
un conjunto de muestras. Lo primero que vamos a hacer es convertirlo en un
[SpatialPointsDataFrame](https://www.rdocumentation.org/packages/sp/versions/1.2-4/topics/SpatialPointsDataFrame-class) para poder trabajar con las coordenadas de los puntos

```` R
coordinates(meuse)<-c("x","y")
class(meuse)
str(meuse)
````


## Parte 2 Graficar

## Parte 3 Semivariograma
