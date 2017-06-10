
library(sp)
library(gstat)

##Carga y exploración de datos
?meuse
data("meuse")
class(meuse)
str(meuse)
meuse$logZn <- log10(meuse$zinc)
View(meuse)
##Conversión a datos espaciales
coordinates(meuse)<-c("x","y")
class(meuse)
str(meuse)

#mapeo de datos
plot(meuse,asp=1,pch=1)
data("meuse.riv")
lines(meuse.riv)
plot(meuse,asp=1,cex=4*meuse$zinc / max(meuse$zinc), pch=1)
lines(meuse.riv)

#dependencia espacial, distancia entre puntos
n <- length(meuse$logZn)
n*(n-1)/2
dim(coordinates(meuse))
coordinates(meuse)[1,]
coordinates(meuse)[2,]
sep<-dist(coordinates(meuse)[1:2,]) #calcula distancia entre los primeros 2 elementos de meuse
sep
gamma

#cálculo y gráfica de variograma experimental
v<-variogram(logZn~1, meuse, cutoff=1300, width=90)
v
print(plot(v,plot.numbers=T))
#variograma empírico
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
gridded(meuse.grid) <- T #especifíca que es una malla regular

#cálculo de KO sobre la malla regular
k40<- krige(logZn~1, locations = meuse, newdata =meuse.grid, model =vmf)
str(k40)
#despliegue del mapa de los valores predichos
print(spplot(k40,"var1.pred",asp=1,col.regions=bpy.colors(64),main="KO predicción,log-ppm Zn"))
#mapa de las varianza de las predicciones
print(spplot(k40, "var1.var",col.regions=cm.colors(64), asp=1,main="KO varianza de la predicción, log-ppm Zn^2")) 
#mapa con el tamaño de los círculos
pts.s <- list("sp.points", meuse, col="white", pch=1, cex=4*meuse$zinc/max(meuse$zinc))
print(spplot(k40,"var1.pred",asp=1, col.regions=bpy.colors(64), main= "KO predicción", sp.layout=list(pts.s)))              
pts<-list("sp.points", meuse, col="black", pch=20)
print(spplot(k40, "var1.var",col.regions=cm.colors(64), asp=1,main="KO varianza de la predicción, log-ppm Zn^2",sp.layout=list(pts))) 

#validación cruzada LOCCV
kcv.ok<- krige.cv(logZn~1, locations = meuse, model=vmf)
summary (kcv.ok)
summary(kcv.ok$residual)
#medida dek RMSE
sqrt(sum(kcv.ok$residual^2)/length(kcv.ok$residual))
