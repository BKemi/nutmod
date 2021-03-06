#' @author Gerald C. Nelson, \email{nelson.gerald.c@@gmail.com}
#' @keywords utilities, nutrient data, IMPACT food commodities nutrient lookup
# Intro ---------------------------------------------------------------
#Copyright (C) 2015 Gerald C. Nelson, except where noted

#   This program is free software: you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation, either version 3 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
#   or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
#   for more details at http://www.gnu.org/licenses/.

#' @description To be added

#' @include nutrientModFunctions.R
#' @include nutrientCalcFunctions.R
if (!exists("getNewestVersion", mode = "function"))
{source("R/nutrientModFunctions.R")
  source("R/workbookFunctions.R")
  source("R/nutrientCalcFunctions.R")}

reqList <- keyVariable("reqsList")
#reqsToDelete <- c( "req.EAR", "req.UL.vits", "req.UL.minrls", "req.AMDR_hi", "req.AMDR_lo")
reqsToDelete <- c( "req.EAR", "req.AMDR_hi", "req.AMDR_lo" ) #, "req.UL.vits", "req.UL.minrls")
reqList <- reqList[!reqList %in% reqsToDelete]
AMDRs <-  c("req.AMDR_hi", "req.AMDR_lo")

#do AMDRs as a special case
for (i in AMDRs) {
  print(paste0("------ working on ", i))
  reqShortName <- gsub("req.", "", i)
  temp <- paste("food_agg_", reqShortName, sep = "")
  DT <- getNewestVersion(temp, fileloc("resultsDir"))
  basicKey <- c("scenario", "region_code.IMPACT159", "year")

  DT.long <- data.table::melt(
  DT,
  id.vars = basicKey,
  measure.vars =  c("carbohydrate_g.reqRatio.all", "fat_g.reqRatio.all" , "protein_g.reqRatio.all"),
  variable.name = "nutrient",
  value.name = "value", variable.factor = FALSE)
  DT.long[, nutrient := gsub(".reqRatio.all", "",nutrient)]
  inDT <- unique(DT.long)
  outName <- paste(reqShortName, "sum_reqRatio", sep = "_")
  cleanup(inDT, outName, fileloc("resultsDir"), "csv")
}

# individual food function
req <- "req.RDA.vits" # - for testing purposes
f.ratios.all <- function(){
  keepListCol <- c(mainCols, cols.all)
  dt.food_agg <- dt.food_agg.master[, (keepListCol), with = FALSE]
  sumKey <- c(basicKey, "IMPACT_code")
  # the total daily consumption of each nutrient
  nutList.sum.all <-    paste(nutList, "sum.all", sep = ".")
  # the ratio of daily consumption of each nutrient to the total consumption
  nutList.ratio.all <-   paste(nutList, "ratio.all", sep = ".")
  # the ratio of daily consumption of each nutrient by the nutrient requirement
  nutList_reqRatio_all <- paste(nutList, "reqRatio.all", sep = ".")

  # the list of columns to keep for each group of data tables
  keepListCol.sum.all <-    c(basicKey, nutList.sum.all)
  keepListCol.ratio.all <-   c(sumKey, nutList.ratio.all)
  keepListCol_reqRatio_all <- c(sumKey, nutList_reqRatio_all)

  # create the data table and remove unneeded columns
  dt.all.sum <- dt.food_agg[,keepListCol.sum.all, with = FALSE]
  data.table::setkey(dt.all.sum)
  dt.all.sum <- unique(dt.all.sum)

  dt.all.ratio <- dt.food_agg[,   keepListCol.ratio.all, with = FALSE]
  data.table::setkey(dt.all.ratio)
  dt.all.ratio <- unique(dt.all.ratio)

  dt.all.reqRatio <- dt.food_agg[, keepListCol_reqRatio_all, with = FALSE]
  data.table::setkey(dt.all.reqRatio)
  dt.all.reqRatio <- unique(dt.all.reqRatio)

  # calculate the ratio of nutrient consumption for all commodities to the requirement
  # # dt.sum.copy <- data.table::copy(dt.all.sum)
  #  # scenarioComponents code needed because nutsReqPerCap are only available with scenario as SSPs
  #  scenarioComponents <- c("SSP", "climate_model", "experiment")
  #  dt.sum[, (scenarioComponents) := data.table::tstrsplit(scenario, "-", fixed = TRUE)]
  #  dt.nuts.temp <- dt.nutsReqPerCap[scenario %in% unique(dt.sum$SSP),]
  #  temp <- merge(dt.sum,dt.nuts.temp, by.x = c("SSP", "region_code.IMPACT159", "year"),
  #                by.y = c("scenario", "region_code.IMPACT159", "year"),
  #                all.x = TRUE)
  #  temp[,SSP := NULL]
  nutListSum <- as.vector(paste(nutList,".sum.all", sep = ""))
  nutListReqRatio <- as.vector(paste(nutList,".reqRatio", sep = ""))
  nutListReq <- as.vector(paste(nutList,".req", sep = ""))
  # note: an alternative to the Map code below is simply to sum (using ethanol as an example) ethanol_g.reqRatio.all by scenario year region
  # the R code is explained at http://stackoverflow.com/questions/37802687/r-data-table-divide-list-of-columns-by-a-second-list-of-columns
  dt.food_agg[, (nutListReqRatio) := Map(`/`, mget(nutListSum), mget(nutListReq))]
  keepListCol <- c(basicKey, nutListReqRatio)
  dt.sum.reqRatio <- unique(dt.food_agg[, keepListCol, with = FALSE])

  dt.all.sum.long <- data.table::melt(
    dt.all.sum,  id.vars = basicKey,
    measure.vars = nutList.sum.all,
    variable.name = "nutrient",
    value.name = "value", variable.factor = FALSE)
  dt.all.sum.long[, nutrient := gsub(".sum.all", "",nutrient)]

  dt.sum_reqRatio_long <- data.table::melt(
    dt.sum.reqRatio,
    id.vars = basicKey,
    measure.vars = nutListReqRatio,
    variable.name = "nutrient",
    value.name = "value", variable.factor = FALSE)
  dt.sum_reqRatio_long[, nutrient := gsub(".reqRatio", "",nutrient)]

  dt.all.ratio.long <- data.table::melt(
    dt.all.ratio, id.vars = sumKey,
    measure.vars = nutList.ratio.all,
    variable.name = "nutrient",
    #    value.name = "nut_share", variable.factor = FALSE)
    value.name = "value", variable.factor = FALSE)
  dt.all.ratio.long[, nutrient := gsub(".ratio.all", "",nutrient)]

  dt.all_reqRatio_long <- data.table::melt(
    dt.all.reqRatio,
    id.vars =  sumKey,
    measure.vars = nutList_reqRatio_all,
    variable.name = "nutrient",
    value.name = "value", variable.factor = FALSE)
  dt.all_reqRatio_long[, nutrient := gsub(".reqRatio_all", "",nutrient)]

  reqShortName <- gsub("req.", "", req)

  inDT <- unique(dt.all.sum.long)
  outName <- paste(reqShortName, "all_sum", sep = "_")
  cleanup(inDT, outName, fileloc("resultsDir"), "csv")

  inDT <- dt.sum_reqRatio_long
  inDT[, nutrient := gsub("_reqRatio", "", nutrient)]
  inDT <- unique(inDT)
  print(paste0("dt.sum_reqRatio_long"))
  #  print(unique(inDT$nutrient))
  outName <- paste(reqShortName, "sum_reqRatio", sep = "_")
  cleanup(inDT, outName, fileloc("resultsDir"), "csv")

  inDT <- unique(dt.all.ratio.long)
  # print(paste0("dt.all.ratio.long"))
  # print(unique(inDT$nutrient))
  outName <- paste(reqShortName, "all_ratio", sep = "_")
  cleanup(inDT, outName, fileloc("resultsDir"), "csv")

  inDT <- dt.all_reqRatio_long
  inDT[, nutrient := gsub("_reqRatio_all", "", nutrient)]
  inDT <- unique(inDT)
  # print(paste0("dt.all_reqRatio_long"))
  # print(unique(inDT$nutrient))
  outName <- paste(reqShortName, "all_reqRatio", sep = "_")
  cleanup(inDT, outName, fileloc("resultsDir"), "csv")
}

# foodGroup function
f.ratios.FG <- function(){
  dt.food_agg <- data.table::copy(dt.food_agg.master)
  keepListCol <- c(mainCols, cols.foodGroup)
  dt.food_agg <- dt.food_agg[, (keepListCol), with = FALSE]
  foodGroupKey <- c(basicKey, "food_group_code")
  nutList_ratio_foodGroup <-   paste(nutList, "ratio.foodGroup", sep = ".")
  nutList_reqRatio_foodGroup <- paste(nutList, "reqRatio.foodGroup", sep = ".")
  keepListCol_ratio_foodGroup <-   c(foodGroupKey, nutList_ratio_foodGroup)
  keepListCol_reqRatio_foodGroup <- c(foodGroupKey, nutList_reqRatio_foodGroup)
  dt.foodGroup_ratio <- dt.food_agg[,   keepListCol_ratio_foodGroup, with = FALSE]
  data.table::setkey(dt.foodGroup_ratio)
  dt.foodGroup.ratio <- unique(dt.foodGroup_ratio)
  dt.foodGroup.reqRatio <- dt.food_agg[, keepListCol_reqRatio_foodGroup, with = FALSE]
  data.table::setkey(dt.foodGroup.reqRatio)
  dt.foodGroup_reqRatio <- unique(dt.foodGroup.reqRatio)

  dt.foodGroup.ratio.long <- data.table::melt(
    dt.foodGroup.ratio,
    id.vars = foodGroupKey,
    measure.vars = nutList_ratio_foodGroup,
    variable.name = "nutrient",
    value.name = "value",
    variable.factor = FALSE
  )
  dt.foodGroup_reqRatio_long <- data.table::melt(
    dt.foodGroup.reqRatio,
    id.vars = foodGroupKey,
    measure.vars = nutList_reqRatio_foodGroup,
    variable.name = "nutrient",
    value.name = "value",
    variable.factor = FALSE
  )

  reqShortName <- gsub("req.", "", req)

  inDT <- unique(dt.foodGroup.ratio.long)
  outName <- paste(reqShortName, "FGratio", sep = "_")
  cleanup(inDT, outName, fileloc("resultsDir"), "csv")

  inDT <- unique(dt.foodGroup_reqRatio_long)
  outName <- paste(reqShortName, "FG_reqRatio", sep = "_")
  cleanup(inDT, outName, fileloc("resultsDir"), "csv")
}

# staples function
f.ratios.staples <- function(){
  dt.food_agg <- data.table::copy(dt.food_agg.master)
  keepListCol <- c(mainCols, cols.staple)
  dt.food_agg <- dt.food_agg[, (keepListCol), with = FALSE]
  stapleKey <- c(basicKey, "staple_code")

  # the total daily consumption of each staple
  nutList_sum_staple <-    paste(nutList, "sum.staple", sep = ".")

  # the ratio of daily consumption of each nutrient for each staple to the total consumption
  nutList_ratio_staple <-   paste(nutList, "ratio.staple", sep = ".")
  nutList_reqRatio_staple <- paste(nutList, "reqRatio.staple", sep = ".")
  keepListCol_sum_staple <-    c(stapleKey, nutList_sum_staple)
  keepListCol_ratio_staple <-   c(stapleKey, nutList_ratio_staple)
  keepListCol_reqRatio_staple <- c(stapleKey, nutList_reqRatio_staple)

  dt.staples.sum <- dt.food_agg[,    keepListCol_sum_staple, with = FALSE]
  data.table::setkey(dt.staples.sum, NULL)
  dt.staples.sum <- unique(dt.staples.sum)
  dt.staples.ratio <- dt.food_agg[,   keepListCol_ratio_staple, with = FALSE]
  data.table::setkey(dt.staples.ratio, NULL)
  dt.staples.ratio <- unique(dt.staples.ratio)
  dt.staples.reqRatio <- dt.food_agg[, keepListCol_reqRatio_staple, with = FALSE]
  data.table::setkey(dt.staples.reqRatio, NULL)
  dt.staples.reqRatio <- unique(dt.staples.reqRatio)

  #reshape the results to get years in columns
  dt.staples.sum.long <- data.table::melt(
    dt.staples.sum,
    id.vars = stapleKey,
    measure.vars = nutList_sum_staple,
    variable.name = "nutrient",
    value.name = "value",
    variable.factor = FALSE
  )
  dt.staples.ratio.long <- data.table::melt(
    dt.staples.ratio,
    id.vars = stapleKey,
    measure.vars = nutList_ratio_staple,
    variable.name = "nutrient",
    value.name = "value",
    variable.factor = FALSE
  )
  dt.staples_reqRatio_long <- data.table::melt(
    dt.staples.reqRatio,
    id.vars = stapleKey,
    measure.vars = nutList_reqRatio_staple,
    variable.name = "nutrient",
    value.name = "value",
    variable.factor = FALSE
  )

  reqShortName <- gsub("req.", "", req)
  inDT <- unique(dt.staples.sum.long)
  outName <- paste(reqShortName, "staples_sum", sep = "_")
  cleanup(inDT, outName, fileloc("resultsDir"), "csv")

  inDT <- unique(dt.staples.ratio.long)
  outName <- paste(reqShortName, "staples_ratio", sep = "_")
  cleanup(inDT, outName, fileloc("resultsDir"), "csv")

  #  inDT <- dt.staples_reqRatio_wide
  inDT <- unique(dt.staples_reqRatio_long)
  outName <- paste(reqShortName, "staples_reqRatio", sep = "_")
  cleanup(inDT, outName, fileloc("resultsDir"), "csv")
}

for (req in reqList) {
  print(paste0("------ working on ", req))
  reqShortName <- gsub("req.", "", req)
  temp <- paste("food_agg_", reqShortName, sep = "")
  dt.food_agg.master <- getNewestVersion(temp, fileloc("resultsDir"))
  dt.food_agg.master[, scenario := gsub("IRREXP-WUE2", "IRREXP_WUE2", scenario)]
  dt.food_agg.master[, scenario := gsub("PHL-DEV2", "PHL_DEV2", scenario)]
  # get list of nutrients from dt.nutsReqPerCap for the req set of requirements
  dt.nutsReqPerCap <- getNewestVersion(paste(req,"percap",sep = "_"))
  nutList <- names(dt.nutsReqPerCap)[4:length(names(dt.nutsReqPerCap))]
  basicKey <- c("scenario", "region_code.IMPACT159", "year")
  cols.all <- names(dt.food_agg.master)[grep(".all", names(dt.food_agg.master))]
  cols.staple <- names(dt.food_agg.master)[grep(".staple", names(dt.food_agg.master))]
  cols.foodGroup <- names(dt.food_agg.master)[grep(".foodGroup", names(dt.food_agg.master))]
  mainCols <- names(dt.food_agg.master)[!names(dt.food_agg.master) %in% c(cols.all,cols.staple,cols.foodGroup)]

  # dt.nutsReqPerCap <- getNewestVersion(paste(req,"percap",sep = "."))
  # # scenarioComponents code needed because nutsReqPerCap are only available with scenario as SSPs
  # scenarioComponents <- c("SSP", "climate_model", "experiment")
  # dt.food_agg.master[, (scenarioComponents) := data.table::tstrsplit(scenario, "-", fixed = TRUE)]
  # dt.nuts.temp <- dt.nutsReqPerCap[scenario %in% unique(dt.food_agg.master$SSP),]
  # dt.foodNnuts <- merge(dt.food_agg.master,dt.nuts.temp, by.x = c("SSP", "region_code.IMPACT159", "year"),
  #               by.y = c("scenario", "region_code.IMPACT159", "year"),
  #               all.x = TRUE)
  # dt.foodNnuts[,(scenarioComponents) := NULL]

# run the ratios functions -----
  f.ratios.all()
  f.ratios.staples()
  f.ratios.FG()
}
# kcals calculations -----
print("------ working on kcals")
# # fats, etc share of total kcals ------
# # source of conversion http://www.convertunits.com/from/joules/to/calorie+[thermochemical]
# # fat 37kJ/g - 8.8432122371 kCal
# fatKcals <- 8.8432122371
# # # protein 17kJ/g - 4.0630975143 kCal
# proteinKcals <- 4.0630975143
# # # carbs 16kJ/g) - 3.8240917782
# carbsKcals <- 3.8240917782
# # 1 kJ = 0.23900573614 thermochemical /food calorie (kCal)
# # 1 Kcal = 4.184 kJ
# # alcoholic beverages need to have ethanol energy content included
# # see below for assumptions

# reminder dt.IMPACTfood has the annual consumption of a commodity. So long as used for ratios this is ok.
# dt.IMPACTfood <- getNewestVersion("dt.IMPACTfood", fileloc("iData"))
# deleteListCol <- c("pcGDPX0", "PCX0", "PWX0", "CSE")
# dt.IMPACTfood[,(deleteListCol) := NULL]
# dt.alc <- dt.IMPACTfood[IMPACT_code %in% keyVariable("IMPACTalcohol_code"),]
# keepListCol <- c("scenario", "region_code.IMPACT159", "year", "IMPACT_code", "FoodAvailability")
# dt.alc <- dt.alc[,keepListCol, with = FALSE]

# note: kcals calculations done in dataPrep.nutrientData.R so no need to do here
# dt.nutrients calculates kcals.fat, kcals.protein, kcals.carbohydrate, kcals.sugar, kcals.ethanol
# ethanolKcals <- 6.9
# ethanol content from FAO FBS Handbook. Orginal numbers in kcals; divide by kcals.ethanol_per_g
# beer - 29 kcals per 100 gm
# wine - 68 kcals per 100 gm
# distilled alcohol 295 kcals per 100 gm.

# formula.wide <- paste("scenario + region_code.IMPACT159 + year ~ IMPACT_code")
# dt.alc.wide <- data.table::dcast(data = dt.alc,
#                                  formula = formula.wide,
#                                  value.var = "FoodAvailability")
# dt.alc.wide[, kcal := c_beer * ethanolKcals * ethanol.beer +
#               c_wine * ethanolKcals * ethanol.wine +
#               c_spirits * ethanolKcals * ethanol.spirits]
# deleteListCol <- c("c_beer","c_spirits","c_wine")
# dt.alc.wide[, (deleteListCol) := NULL]

# now get the nutrient values
# dt.nutrients <- getNewestVersion("dt.nutrients")
# dt.nutSum <- getNewestVersion("dt.nutrients.sum.all", fileloc("resultsDir"))
#
# formula.nut <- paste("scenario + region_code.IMPACT159 + year ~ nutrient")
# dt.nutSum.wide <- data.table::dcast(
#   data = dt.nutSum,
#   formula = formula.nut,
#   value.var = "value",
#   variable.factor = FALSE)
#
# # Note. sum.kcals differs from energy_kcal because alcohol is not included in carbohydrates. Maybe other reasons too
# dt.nutSum.wide[, sum_kcals := kcals.protein_g + kcals.fat_g + kcals.carbohydrate_g + kcals.ethanol_g]
# dt.nutSum.wide[, diff_kcals := energy_kcal - sum_kcals]
# nutList.kcals <- c("energy_kcal", "kcals.protein_g", "kcals.carbohydrate_g", "kcals.sugar_g", "kcals.fat_g", "kcals.ethanol_g")
# # #nutList.kcals <- paste(macroKcals,".sum.all", sep = "")
# nutList.ratio <- paste(nutList.kcals,"_share", sep = "")
# basicKey <- c("scenario",  "region_code.IMPACT159", "year")
# dt.nutSum.wide[, (nutList.ratio) := lapply(.SD, "/", energy_kcal), .SDcols = (nutList.kcals)]
# keepListCol <- c(basicKey, nutList.ratio)
# dt.nutSum.wide <- dt.nutSum.wide[, keepListCol, with = FALSE]
#
# dt.nutSum.long <- data.table::melt(
#   dt.nutSum.wide, id.vars = basicKey,
#   measure.vars = nutList.ratio,
#   variable.name = "nutrient",
#   value.name = "value",
#   variable.factor = FALSE)
#
# inDT <- dt.nutSum.long
# inDT[, nutrient := gsub("_share", "", nutrient)]
# outName <- "dt.energy_ratios"
# cleanup(inDT, outName, fileloc("resultsDir"), "csv")
