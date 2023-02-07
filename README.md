# Geospatial analysis and representation for Data Science - Final Project
*Disclaimer:* All data was treated according to the license of use present on external sources (mainly Booking), and for this reason I ask to anyone who would be interested in this project to not publish the results as they are intended to be for personal use; 

For this project my goal was to create a script meant to compute travel and accomodation time for holiday purposes, from any given city to any other within the same region. 

The script works, but due to computation constraints (mainly the amount of RAM available to me), I was only able to make it run on a province base, meaning computing travel and accomodations for cities within the same province.
Since this work is supposed to be interactive and provide different outputs based on the settings you specify, for the R part I chose a specific city and conditions (a trip to Rimini, with prices for 2 people staying for 2 nights) and performed statistical analysis with these specific terms.ùù


Here is a rundown of the content in this Github Folder:
- **code** this repository contains the main code, divided in 3 parts. The reason I did this was to better describe each step and provide some context.
It also includes a working version of the script, named *trip_calculator_demo.ipynb*, where I tested the code on a travel from Sassuolo to the city of Modena.
- **resources** here are the files you should download locally in the same environment you want to run the code, specifically the 3<sup>rd</sup> part which uses R to perform a statistical analysis.
- *Trip_calculator.ipynb* is the version you want to use if you only want to test the code without bothering to examine the script or have intermediate outputs.


*Important Notes:* this work mainly uses data obtained by matching Booking results with Openstreetmap data gathered using overpass API and, for this reason, some results may not appear and, as such, the prices estimated will not necessarily take into account other alternatives in the same area.
Furthermore, prices are always computed at the present day, while they tend to change over the year based on tourist seasons; I included in the code a brief explanation on how to change the starting date, but I still believe it to be worth mentioning.
The distance is based on car travel as this is the main focus and the reason I computed highway and freeway costs, using other means of transportation would of course result in different prices and travelling times from those presented here which aren't necessarily optimized.













