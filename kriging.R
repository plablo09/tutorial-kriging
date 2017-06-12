
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


#dependencia espacial, distancia entre puntos
n <- length(meuse$logZn)
n*(n-1)/2
dim(coordinates(meuse))
coordinates(meuse)[1,]
coordinates(meuse)[2,]
sep<-dist(coordinates(meuse)[1:2,]) #calcula distancia entre los primeros 2 elementos de meuse
sep
gamma

#c�lculo y gr�fica de variograma experimental
v<-variogram(logZn~1, meuse, cutoff=1300, width=90)
v
print(plot(v,plot.numbers=T))
#variograma emp�rico
print(show.vgms())
#ajuste de variograma
vm <- vgm(psill = 0.13, model = "Sph", range = 850, nugget = 0.01)
print(plot(v, pl=T, model=vm)) #ajuste a ojo
vmf<- fit.variogram(v,vm) #ajuste asistido
vm
vmf
print(plot(v,pl=T,model=vmf))

#carga de malla regular de 40x40 m.
data("meuse.grid")
coordinates(meuse.grid)<- c("x","y")
str(meuse.grid)
gridded(meuse.grid) <- T #especif�ca que es una malla regular

#c�lculo de KO sobre la malla regular
k40<- krige(logZn~1, locations = meuse, newdata =meuse.grid, model =vmf)
str(k40)
#despliegue del mapa de los valores predichos
print(spplot(k40,"var1.pred",asp=1,col.regions=bpy.colors(64),main="KO predicci�n,log-ppm Zn"))
#mapa de las varianza de las predicciones
print(spplot(k40, "var1.var",col.regions=cm.colors(64), asp=1,main="KO varianza de la predicci�n, log-ppm Zn^2")) 
#mapa con el tama�o de los c�rculos
pts.s <- list("sp.points", meuse, col="white", pch=1, cex=4*meuse$zinc/max(meuse$zinc))
print(spplot(k40,"var1.pred",asp=1, col.regions=bpy.colors(64), main= "KO predicci�n", sp.layout=list(pts.s)))              
pts<-list("sp.points", meuse, col="black", pch=20)
print(spplot(k40, "var1.var",col.regions=cm.colors(64), asp=1,main="KO varianza de la predicci�n, log-ppm Zn^2",sp.layout=list(pts))) 

#validaci�n cruzada LOCCV
kcv.ok<- krige.cv(logZn~1, locations = meuse, model=vmf)
summary (kcv.ok)
summary(kcv.ok$residual)
#medida dek RMSE
sqrt(sum(kcv.ok$residual^2)/length(kcv.ok$residual))