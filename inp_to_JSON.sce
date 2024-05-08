// Copyright (C) 2023 - Corporation - B. Laubacher, J. Newkirk
//
// Date of creation: Aug 15, 2023
// Modified 5/8/24 for use directly with AIPP.inp file
//
clear
FunctionDir = get_absolute_file_path() + "Functions"
getd(FunctionDir);

StartingDir = uigetdir(); cd(StartingDir)
pi=3.1415926;
folderinfo =dir()
rows.aipp235 = grep(folderinfo.name, "aipp.inp")
l1  = list("AIPP 2.3.5 Input Decks:",1,[folderinfo.name(rows.aipp235)']);
rep = x_choices('Select AIPP 2.3.5 Input Deck To Convert',list(l1));
AIPP235Doc = folderinfo.name(rows.aipp235)(rep(1))
//disp(AIPP235Doc)
DeckTitle = strsplit(AIPP235Doc,".")(1)

// now read in the deck file you want to convert
text=mgetl(AIPP235Doc);

// gather some preliminary information
ncham=strtod(tokens(text(5))(1))

// start constructing the final "aipp_calculation" Structure
// converted to 'ac' for simplicity, and will be renamed prior to writing the final JSON file

//  create the time_specs values for the object
// have to use grep to find the correct line since the deck file can have a variable number of lines.  :*()
ac=GetTimes1(text)

ac=GetChamberDetails1(ac, text, ncham)

ac=GetFilterDetails1(ac, text, ncham)

ac=GetPyroDetails1(ac,text,ncham)


ac=GetOrificeDetails1(ac,text,ncham)

ac=GetHeatTransferDetails1(ac, text, ncham)  

//ac.tank_id=ncham
res.aipp_calculation=ac;
toJSON(res,3,'testinput.json')


//  Deck changes are complete. Below is deck manipulation and correction for 
//  integers that should be decimals, and also a / that toJSON turns into \/


//The Scilab JSON converter is not formatting the pyro information correctly. 
//To fix this, the JSON is read in as a text file and square brackets are added
dat = mgetl('testinput.json'); mdelete('testinput.json')
dat = FixSquareBracesforPyro(dat)


//Scilab 2024 has introduced a bug where every "/" character is expressed as "\/"
//This function corrects this behavior
dat = FixJSON(dat)

// add items in the JSON file that require a double instead of an int to the doubleVars 
// array. This will likely need to be expanded as the JSON file
//progresses
doubleVars = ["burn_rate_factor","opens_at","temperature","flame_spread_time"...
,"diameter","discharge_coefficient","mass","dome_height","reference_burn_rate"...
,"volume","burn_rate_exponent", "thickness", "heat_flux",...
"heat_transfer_coefficient", "viscous_flow_factor","scale_factor", "coefficient"]
fixedInts = ConvertIntsToDoublesJSON(dat, doubleVars)


Title = x_dialog(["Please enter a name for the output file"],DeckTitle)
Title = strcat([Title,".json"])
csvWrite(fixedInts,Title)




