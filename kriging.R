
library(sp)
library(gstat)
library(ggplot2)

## Carga y exploraci�n de datos
?meuse
data("meuse")
class(meuse)
str(meuse)
meuse$logZn <- log10(meuse$zinc)
View(meuse)
## Conversi�n a datos espaciales
coordinates(meuse)<-c("x","y")
class(meuse)
str(meuse)

# mapeo de datos, primero s�lo los puntos
# Para graficar con ggplot, necesitamos regresar los datos a un data.frame
mapdata <- data.frame(meuse)
ggplot(data=mapdata) + geom_point(aes(x,y), color="blue", alpha=3/4)  +
   coord_equal() + theme_bw()

# Luego los puntos pero variando el tama�o de acuerdo a la proporci�n de Zinc
# con respecto al m�ximo
ggplot(data=mapdata, aes(x,y)) +
   geom_point(aes(size=4*zinc/max(zinc)), color="blue", alpha=3/4) +
   ggtitle("Zinc Concentration (ppm)") + coord_equal() + theme_bw()

# Ahora vamos a incluir los r�os en la gr�fica, primero leemos los datos
data("meuse.riv")
# �De qu� clase son?
class(meuse.riv)

# Como ggplot s�lo sabe trabajar sobre DataFrames, los convertimos: 
meuse.riv.df <- data.frame(meuse.riv)

# Ahora s� podemos graficarlo usando geom_path
# (para unir los puntos en el orden en el que est�n)
ggplot(data=mapdata,aes(x, y)) +
    geom_point(aes(size=4*zinc/max(zinc)), color="blue", alpha=3/4) +
    geom_path(data=meuse.riv.df, aes(x=X1,y=X2)) +
    ggtitle("Zinc Concentration (ppm)") + coord_equal() + theme_bw()


# dependencia espacial, distancia entre puntos
n <- length(meuse$logZn)
n*(n-1)/2
dim(coordinates(meuse))
coordinates(meuse)[1,]
coordinates(meuse)[2,]
# calcula distancia entre los primeros 2 elementos de meuse
sep <- dist(coordinates(meuse)[1:2,]) 
sep
gamma

#c�lculo y gr�fica de variograma experimental
exp.variogram <- variogram(logZn~1, meuse, cutoff=1300, width=90)
View(exp.variogram)
ggplot(data = exp.variogram, mapping = aes(x=dist,y=gamma)) +
    geom_point() +
    geom_text(aes(label=np),hjust=0, vjust=0)

# Ahora, en lugar de usar la cantidad de puntos como etiquetas, 
# usemos el tama�o de los puntos para representar la cantidad
ggplot(data = exp.variogram, mapping = aes(x=dist,y=gamma)) +
    geom_point(aes(size=np), color="blue", alpha=3/4)

# Variograma emp�rico. �Qu� modelos podemos ajustar?
show.vgms()


# Primero creamos un variograma arbitrario y obtenemos
# sus valores para poder graficarlo
vm <- vgm(psill = 0.13, model = "Sph", range = 850, nugget = 0.01)
max.dist <- max(exp.variogram$dist)
vm.line <- variogramLine(vm, max.dist, n = 200, min =  1.0e-6 * max.dist,
                         dir = c(1,0,0), covariance = FALSE) 
ggplot(data = vm.line, mapping = aes(x=dist,y=gamma)) +
    geom_line() +
    geom_point(data = exp.variogram, mapping = aes(x=dist, y=gamma, size = np))

# Ahora vamos a ajustar un variograma esf�rico
fitted.vm <- fit.variogram(exp.variogram, vm) #ajuste asistido

#print(plot(exp.variogram, pl=T, model=fitted.vm))
fitted.vm.line <- variogramLine(fitted.vm, max.dist, n = 200, min =  1.0e-6 * max.dist,
                         dir = c(1,0,0), covariance = FALSE) 
ggplot(data = fitted.vm.line, mapping = aes(x=dist,y=gamma)) +
    geom_line() +
    geom_point(data = exp.variogram, mapping = aes(x=dist, y=gamma, size = np))



# Ya con el modelo ajustado, podemos hacer predicciones.
# El m�todo krige sirve para calcular los valores en lugares
# donde no se muestreo, usando el modelo que ajustamos.
# Lo primero que vamos a hacer es usar una malla regular que representa
# los lugares en donde queremos calcular las concentraciones de Zinc:

data("meuse.grid")
coordinates(meuse.grid)<- c("x","y")
str(meuse.grid)
gridded(meuse.grid) <- T #especif�ca que es una malla regular


predicted <- krige(logZn~1, locations = meuse, newdata = meuse.grid, model = fitted.vm)
str(predicted)

# Graficamos los valores que acabamos de predecir ()
# (noten que, como usamos una malla regular, la predicci�n se parece a una imagen)
# Para graficar datos en mallas regulares con atributos, usamos spplot
spplot(predicted, "var1.pred", asp=1, col.regions = bpy.colors(64),
       main = "KO predicci�n,log-ppm Zn")

# Una de las ventajas de usar Kriging es que nos da una estimaci�n de
# la varianza de las predicciones. Grafiqu�mosla

spplot(predicted, "var1.var",col.regions = cm.colors(64),
       asp = 1,main = "KO varianza de la predicci�n, log-ppm Zn^2")

# Ahora, para comparar la distribuci�n que obtuvimos con los datos originales,
# podemos graficar tambi�n los puntos originales en cualquiera de las 
# dos gr�ficas anteriores, primero con los valores:
pts.s <- list("sp.points", meuse, col="blue", pch=1,
              cex=4*meuse$zinc/max(meuse$zinc))
spplot(predicted, "var1.pred", asp=1, col.regions=bpy.colors(64),
       main = "KO predicci�n", sp.layout=list(pts.s))

# Y ahora con las varianzas:
pts.s <- list("sp.points", meuse, col="blue", pch=1,
              cex=4*meuse$zinc/max(meuse$zinc))
print(spplot(predicted, "var1.var", col.regions=cm.colors(64),
             asp=1,main="KO varianza de la predicci�n, log-ppm Zn^2",
             sp.layout=list(pts))) 

#validaci�n cruzada LOCCV
kcv.ok<- krige.cv(logZn~1, locations = meuse, model=fitted.vm)
summary (kcv.ok)
summary(kcv.ok$residual)
#medida dek RMSE
sqrt(sum(kcv.ok$residual^2)/length(kcv.ok$residual))
