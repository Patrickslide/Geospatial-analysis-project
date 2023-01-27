---
title: "Geospatial analysis and representation - Final Project part 3: Spatial Analysis"
author: "Patrick Montanari"
date: '2023-01-19'
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

## Setup

```{r}
library(sf)
library(tmap)
library(spdep)
library(leaflet)
library(spatialreg)
library(ggplot2)
library(dplyr)
library(png)
```

In my project all files are tied together, basing the analysis on the desired destination of travel, calculating cost of both accomodation ( prices for inserted number of days and number of people) and car travel based on cost of fuel and highway tolls.

That wouldn't be adequate for a deep analysis on spatial factors and relationships, as you would only receive the results but not a proper commentary and visualization. For this reason, I decided to assign a given city as the setting of this demonstration, separating it from the rest of the project which still relies on the inputs provided.

## Upload Data

I start by loading our data on italian cities, downloaded from istat's website at this link:

<https://www.istat.it/storage/cartografia/confini_amministrativi/non_generalizzati/Limiti01012022.zip>

I am only interested in cities for this project, not provinces or regions. Note that data isn't automatically set as EPSG:4326 (corresponding to WGS84), so I convert it using st_transform.

```{r rimini, echo=FALSE}
setwd("C:/Users/patri/Desktop/PATRICK/Università/Didattica/Corsi/Data Science/Geospatial analysis and representation for data science/Final Report")          #Replace the working directory with the one you would store your data in.

cities <- st_read('Limiti01012022/Com01012022')
rimini_area <- cities[cities$COD_PROV == 99,]
rimini <- st_geometry(rimini_area[rimini_area$COMUNE =='Rimini',])
rimini <- st_transform(rimini, crs = 4326)
plot(rimini, border="brown") 
bbox <- st_bbox(rimini)

```

We now import data taken from booking regarding hotel prices in the city of Rimini. I downloaded data using an overpass OPI and a booking scraper with respect to data usage licenses, saving output as a csv on local storage (available on github).

As precise as it is, reverse geocoding may make mistakes, especially if there are similar locations or hotel names; for this reason, I exclude all elements outside the Bounding box of our city.Some points were assigned to the same location by geocoding, and for this reason I also remove all duplicates.

### Dataset recoding

```{r}
hotels <- read.csv('hotels.csv')
hotels <- hotels[hotels$lon > bbox[1] & hotels$lat > bbox[2] & hotels$lon < bbox[3] &
       hotels$lon < bbox[4],]
hotels <- distinct(hotels, lon, lat, .keep_all = TRUE)
hotels.xy <- hotels[c("lon", "lat")]

hotels.xy <- coordinates(hotels.xy)
class(hotels.xy)
```

```{r}
leaflet(hotels.xy) %>% addMarkers() %>% addTiles()
```

This was made in order to see if I can notice any relationships between price and local characteristics. Here, I am using the price corresponding to 2 nights for 2 people, as I believe it would represent the average weekend travel plan for a couple. I transform this dataset in a simple feature object as it will required for some analysis and displayment of results.

```{r}
hotels_sf <- st_as_sf(hotels, coords = c("lon", "lat"), crs = 4326)
```

<https://r-spatial.github.io/sf/reference/st_as_sf.html>

## Data Analysis

First, I examine our dependent variable, hotel price.

```{r}
summary(hotels$Price)
```

### 

### Spatial neighbours

Given that we are working with points corresponding to our hotels, we can only use the k-nn criterion and the critical cut-off criterion, as contiguity-based approaches can only be applied to polygons.

#### K-nearest Neighbours

I will perform a Spatial Autocorrelation, to see whether the location of hotels has any influence on the price; I expect hotels further from the centre to be less expensive. I try a k-nn test with 1, 3 and 5 neighbours.

```{r}
knn_1 <- knn2nb(knearneigh(hotels.xy, k = 1))
knn_3 <- knn2nb(knearneigh(hotels.xy, k = 3))
knn_5 <-  knn2nb(knearneigh(hotels.xy, k = 5))
```

```{r}
plot(rimini, border="grey") 
plot(knn_1, hotels.xy, add=TRUE, col = 'yellow')
```

```{r}
plot(rimini, border="grey") 
plot(knn_3, hotels.xy, add=TRUE, col ='orange')
```

```{r}
plot(rimini, border="grey") 
plot(knn_5, hotels.xy, add=TRUE, col ='red')
```

#### Critical cut-off neighbourhood

I want to see what are the distances between these items.

```{r}
crit <- knn2nb(knearneigh(hotels.xy,k=1))

summary(unlist(nbdists(crit, hotels.xy)))

cat(sprintf('\nMaximum distance: %f km', max(unlist(nbdists(crit, hotels.xy)))*1000)) 
cat(sprintf('\nMinimum distance: %f km', min(unlist(nbdists(crit, hotels.xy)))*1000))
cat(sprintf('\n Median distance: %f km', median(unlist(nbdists(crit, hotels.xy)))*1000)) 
```

The maximum distance is 15 km, while the minimum is 400 m. I choose 2 km as the threshold distance as its the median score and see the new relations. I decided to use the median and not the mean as it's less affected by outliers.

```{r}
d_2 <- dnearneigh(hotels.xy, 0, 0.02)

plot(rimini, border="grey") 
title(main="d nearest neighbours, d =  2 km") 
plot(d_2, hotels.xy, add=TRUE, col="green")
```

#### Spatial Weight Matrix

I compute the spatial weight matrix and then standardize for each row, in order to consider average values considering each point's neighbours as well. This is done by setting the style as "w".

```{r}
d_2.weights <- nb2listw(d_2,style="W")
```

### Global Spatial Autocorrelation

```{r}
moran.test(hotels$Price, d_2.weights, randomisation=TRUE)
```

```{r}
moran.test(hotels$Price, d_2.weights, randomisation=FALSE)
```

Both values have very high p-values, leading us to reject the hypothesis of presence of spatial relationships. The small difference between randomisation and normality models suggest that the spatial distribution of feature values is most likely the result of random spatial processes.

The negative value of Moran's I index suggest that high price and low price hotels are close to each other (with no clear spatial clustering). Perhaps, closer hotels tends to have a lower price due to a higher number of competitors, with the few positive outliers being distant from each other.

Since we only have data for 25 out of the hundreds present in the city, the sample might be too small for a proper spatial clustering.

### Local Spatial Autocorrelation

```{r}
mplot <- moran.plot(hotels$Price, listw=d_2.weights, main="Moran scatterplot", return_df=F)
hotspot <- as.numeric(row.names(as.data.frame(summary(mplot))))
```

The 4 influential nodes lie in three different quadrants; by examining the plot we can see that the High-High one (#21) is very close to the x-axis, leading to a prevalence of negative correlation.

```{r}
hotels$wx <- lag.listw(d_2.weights, hotels$Price)

hotels$quadrant <- rep("None", length(hotels$Price))
for(i in 1:length(hotspot))  {
  if (hotels$Price[hotspot[i]]>mean(hotels$Price) & hotels$wx[hotspot[i]]> mean(hotels$wx)) 
        hotels$quadrant[hotspot[i]] <- "HH" 
  if (hotels$Price[hotspot[i]]>mean(hotels$Price) & hotels$wx[hotspot[i]]< mean(hotels$wx)) 
        hotels$quadrant[hotspot[i]] <- "HL" 
  if (hotels$Price[hotspot[i]]<mean(hotels$Price) & hotels$wx[hotspot[i]]<mean(hotels$wx)) 
        hotels$quadrant[hotspot[i]] <- "LL" 
  if (hotels$Price[hotspot[i]]<mean(hotels$Price) & hotels$wx[hotspot[i]]>mean(hotels$wx)) 
        hotels$quadrant[hotspot[i]] <- "LH" 
  }
table(hotels$quadrant)
```

Two of the influential factors are in the Low-High quadrant and one in High-Low, both quadrants referring to a negative autocorrelation and high spatial lag; there are, however, 19 unclassified cases, meaning that even the local spatial factor seem to be very weak as most local statistics are insignificant.

Therefore, space isn't the main factor when trying to predict each hotel's price; service provided by each hotel could be a strong factor instead.

Now I plot the results of the spatial autocorrelation, with icons I have preferred for and which are available on the github.

```{r}
for (i in 1:length(hotels$Price)) {
  if (hotels$quadrant[i] == 'LL') {
  hotels$URL[i] <- 'https://raw.githubusercontent.com/Patrickslide/Geospatial-analysis-project/main/resources/hotel-red'
  }
  else if (hotels$quadrant[i]=='LH') {
    hotels$URL[i] = 'https://raw.githubusercontent.com/Patrickslide/Geospatial-analysis-project/main/resources/hotel-orange.png'
  }
  else if (hotels$quadrant[i]=='HL') {
    hotels$URL[i] = 'https://raw.githubusercontent.com/Patrickslide/Geospatial-analysis-project/main/resources/hotel-yellow.png'
  }
  else if (hotels$quadrant[i]=='HH') {
    hotels$URL[i] = 'https://raw.githubusercontent.com//Patrickslide/Geospatial-analysis-project/main/resources/hotel-green.png'
  }
  else if (hotels$quadrant[i]=='None') {
    hotels$URL[i] = 'https://raw.githubusercontent.com//Patrickslide/Geospatial-analysis-project/main/resources/hotel.png'
  }
}
```

```{r}
hotelicons <- icons(iconUrl = hotels$URL,
  iconWidth = 50, iconHeight = 60,
  iconAnchorX = 22, iconAnchorY = 60)

leaflet(data = hotels) %>% addTiles() %>%
  addMarkers(~lon, ~lat, icon = hotelicons)
```

### Local Moran's I

```{r}
local_moran <- localmoran(hotels$Price, d_2.weights)
head(local_moran)
```

```{r}
hotels$lmI <- local_moran[,1]
```

### Conclusion

All our analysis prove that there isn't a strong a spatial correlation between hotels' location and price in the selected area (the city of Rimini); the few significant nodes mostly belong to quadrants corresponding to a negative local autocorrelation, which would result in closer nodes having a higher variance; my hypothesis is that the most expensive hotels are spread out around the city area, avoiding proximity with one another and instead being surrounded by cheaper alternatives which probably do not offer the same services (for example, higher quality of food, presence of spa or pools or a subscription to a nearby beach with reserved sunbeds).
