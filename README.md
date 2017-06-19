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

Como se puede ver, tenemos un `DataFrame` con mediciones de algunas variables para 
un conjunto de muestras. Lo primero que vamos a hacer es convertirlo en un
[SpatialPointsDataFrame](https://www.rdocumentation.org/packages/sp/versions/1.2-4/topics/SpatialPointsDataFrame-class) para poder trabajar más adelante
con las coordenadas de los puntos

```` R
coordinates(meuse) <- c("x","y")
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

## Parte 2. Graficar

Una primera cosa que podemos hacer es graficar los datos. Para esto, 
aunque existen librerías especializadas en datos geográficos, vamos a usar
[ggplot](http://ggplot2.org/). El único problema es que ggplot no puede trabajar con 
objetos del tipo `SpatialPointsDataframe`, entonces primero vamos atenemos que
_desempaquetar_ las coordenadas:

```` R
mapdata <- data.frame(meuse)
ggplot(data=mapdata) + geom_point(aes(x,y), color="blue", alpha=3/4)  +
   coord_equal() + theme_bw()
````

La primera linea, simplemente cambia el tipo de datos a DataFrame y lo guarda
en una variable. La segunda línea crea la gráfica. 

### Un breve recordatorio de ggplot

El paquete ggplot (la gg quiere decir Graphics Grammar) nos da una manera concisa 
de _describir_ las gráficas. Crear una gráfica involucra los siguientes pasos:

1. Instanciar un objeto de ggplot: `ggplot(data = mis.datos)`
2. Definir un tipo de geometría `geom_point()`
3. Definir un _mapeo estético_ que es la forma en la que nuestros datos definen 
la forma en la que se ve la gráfica: `geom_point(aes(x,y))`
4. Agregar cosas como título, colores, etcétera

Ahora sí, después de este muy breve recordatorio de ggplot, podemos regresar a 
nuestro problema. La primera gráfica que hicimos sólo muestra la localización
de los puntos de muestreo, ahora vamos a usar un _mapeo estético_ para que 
el tamaño de los puntos corresponda al contenido de Zinc:

```` R
ggplot(data=mapdata, aes(x,y)) +
   geom_point(aes(size=4*zinc/max(zinc)), color="blue", alpha=3/4) +
   ggtitle("Zinc Concentration (ppm)") + coord_equal() + theme_bw()
````

### Ejercicio rápido

Grafica los mismos puntos pero usa otra variable para modificar el tamaño

**Súper extra** ¿Podrías cambiar el color, en función de una
variable, en lugar de el tamaño de los puntos

Ahora, vamos a incluir más cosas en nuestra gráfica. Dentro de los datos de `meuse`
también tenemos el contorno de un rio que pasa por la zona de muestreo:

```` R
data("meuse.riv")
class(meuse.riv)
View(meuse.riv)
````

Lo que tenemos ahora es una nueva estructura de datos: una matriz. 
Para poderla graficar la vamos a transformar en DataFrame:

```` R
meuse.riv.df <- data.frame(meuse.riv)
View(meuse.riv.df)
````

Como puedes ver es una lista de coordenadas que forman el contorno del rio. 
Para poder visualizarlas, vamos a utilizar un nuevo tipo de geometría
de ggplot: `geom_path`. Esta geometría une los puntos en la secuencia en la 
que están ordenados.

```` R
ggplot(data=mapdata,aes(x, y)) +
    geom_point(aes(size=4*zinc/max(zinc)), color="blue", alpha=3/4) +
    geom_path(data=meuse.riv.df, aes(x=X1,y=X2)) +
    ggtitle("Zinc Concentration (ppm)") + coord_equal() + theme_bw()
````


## Parte 3. Dependencia espacial

La parte central de usar Kriging para interpolar datos espaciales es usar 
la primera (¿única?) ley de la Geografía: Todo está relacionado con todo, 
pero las cosas cercanas están más relacionadas que las cosas lejanas (Waldo Tobler).
En este caso, de lo que se trata es de encontrar un _límite_ a la dependencia espacial,
es decir, ¿Qué tanto la medición en un lugar se parece a los de los lugares cercanos? 
y ¿Qué tan cerca es cerca? 

Para resolver estas preguntas vamos a usar los
[variogramas](https://en.wikipedia.org/wiki/Variogram), que representan 
una medida de cómo varia un campo como función de la distancia entre mediciones: 

````math #variogram
2\gamma(x,y)=\text{var}\left(Z(x) - Z(y)\right) = E\left[((Z(x)-\mu(x))-(Z(y) - \mu(y)))^2\right].
````

En otras palabras estamos midiendo la varianza de las mediciones en diferentes 
rangos de distancia. La librería gstat nos da métodos para calcular el variograma 
de una distribución, pero lo que hace por debajo es relativamente simple: 
calcular las distancias entre pares de muestras y agruparlas en rangos, 
después calcular la varianza en estos rangos. Vamos ahora a calcular (y graficar) el 
variograma experimental de nuestros datos:

```` R
exp.variogram <- variogram(logZn~1, meuse, cutoff=1300, width=90)
View(exp.variogram)
ggplot(data = exp.variogram, mapping = aes(x=dist,y=gamma)) +
    geom_point() +
    geom_text(aes(label=np),hjust=0, vjust=0)
````

Los valores de cutoff y width representan la máxima distancia a considerar y el
ancho de los intervalos en los que vamos a agrupar las mediciones, respectivamente.

**Nota:** Fíjense cómo estamos usando geom_text para poner las etiquetas a los puntos

Ahora, también podemos, en lugar de etiquetar los puntos con la cantidad de muestras,
variar el tamaño9 de los puntos:

```` R
ggplot(data = exp.variogram, mapping = aes(x=dist,y=gamma)) +
    geom_point(aes(size=np), color="blue", alpha=3/4)
````


## Parte 3 Semivariograma

El variograma expermental que calculamos en la sección anterior contiene información
sobre la dependencia espacial de nuestros datos, sin embargo, para poder interpolar, 
necesitamos calcular la variable de interés en lugares en donde no se muestreo. En 
términos del variograma, esto quiere decir que necesitamos calcular _gamma_ en 
distancias arbitrarias.

Para esto, lo que vamos a hacer es ajustar el variograma experimental a uno teórico. 
Es importante notar que, normalmente no hay ninguna razón fundamental para utilizar
algún modelo específico, normalmente son la experiencia del analista y los parámetros
de bondad de ajuste los que ayudan a determinar el mejor modelo.

El paquete gstat ofrece vario modelos de variogramas que podemos usar, el 
siguiente comando nos muestra los modelos disponibles:

```` R
show.vgms()

````

#### Ajuste de variogramas

Por lo pronto, para entender el procedimiento, seleccionemos un modelo de 
variograma _esférico_ para ajustar a nuestros datos. Los parámetros que nos permiten
ajustar los odelos teóricos a nuestros datos experimentales son escencialmente 2.

1. **Range** El valor de distancia a partir del cual ya no se observa dependencia 
espacial, es decir, _gamma_ es estable
2. **Nugget** El desplazamiento del cero al inicio del variograma.

Vamos a crear un variograma con estos valores estimados _a ojo_ a partir del 
variograma experimental que calculamos arriba:

```` R
vm <- vgm(psill = 0.13, model = "Sph", range = 850, nugget = 0.01)
max.dist <- max(exp.variogram$dist)
vm.line <- variogramLine(vm, max.dist, n = 200, min =  1.0e-6 * max.dist,
                         dir = c(1,0,0), covariance = FALSE) 
ggplot(data = vm.line, mapping = aes(x=dist,y=gamma)) +
    geom_line() +
    geom_point(data = exp.variogram, mapping = aes(x=dist, y=gamma, size = np))
````

Esta forma de ajustar _a ojo_ el variograma, además de ser ineficiente, tiene el 
problema de no ser _reproducible y trazable_, es decir, otros analistas segúramente 
obtendrían resultados diferentes y no habría seguridad sobre el método que se siguió.
Para resolver este problema, gstat ofrece una herramienta para ajustar un modelo
teórico a la distribución de nuestrs datos:

```` R
fitted.vm <- fit.variogram(exp.variogram, vm)

````

Ahora lo podemos graficar para ver el resultado del ajuste:

```` R
fitted.vm.line <- variogramLine(fitted.vm, max.dist, n = 200, min =  1.0e-6 * max.dist,
                         dir = c(1,0,0), covariance = FALSE) 
ggplot(data = fitted.vm.line, mapping = aes(x=dist,y=gamma)) +
    geom_line() +
    geom_point(data = exp.variogram, mapping = aes(x=dist, y=gamma, size = np))

````
