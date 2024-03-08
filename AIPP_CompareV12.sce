clear; clc; close(winsid())
FunctionDir = get_absolute_file_path() + "Functions"; getd(FunctionDir);
last_start = mgetl(FunctionDir+"\StartingPlace.txt",1);
StartingDir = uigetdir(last_start,"Please select the directory with Scilab functions and AIPP info")
cd(StartingDir); csvWrite(StartingDir,FunctionDir+"\StartingPlace.txt")

folderinfo =dir()
rows.excel = grep(folderinfo.name, ".xlsx")
rows.aippall = grep(folderinfo.name,"aippall.out")
rows.json = grep(folderinfo.name,".json")

inp_count = 1; out_count = 1
for i=1:1:max(size(rows.json))
    content = mgetl(folderinfo.name(rows.json(i)));
    if grep(content(2),"time_units") ~= [] then
        out_json(out_count) = folderinfo.name(rows.json(i))
        out_count = out_count +1
    elseif grep(content(2),"aipp_calculation") ~= [] then
        inp_json(inp_count) = folderinfo.name(rows.json(i))
        inp_count = inp_count +1
    end
end

l1  = list("Map Table",1,[folderinfo.name(rows.excel)']);
l2  = list("AIPP 2.3.5 Output",2,[folderinfo.name(rows.aippall)']);
l3  = list("AIPP 3.0 Input",3,[inp_json']);
l4  = list("AIPP 3.0 Output",4,[out_json']);
rep = x_choices('Select AIPP Comparison Files',list(l1,l2,l3,l4));

MapTableDoc = strcat([StartingDir,"\",folderinfo.name(rows.excel)(rep(1))])
AIPP235Doc = folderinfo.name(rows.aippall)(rep(2))
AIPP30Input = inp_json(rep(3))
AIPP30Doc = out_json(rep(4))

today = string(getdate()); if length(today(6)) ==1 then today(6) = "0"+today(6) end
if length(today(7)) ==1 then today(7) = "0"+today(7) end
if length(today(8)) ==1 then today(8) = "0"+today(8) end
if length(today(9)) ==1 then today(9) = "0"+today(9) end
Folder_Out = strcat([today(1:2),today(6),"_",today(7:9),"_",strsplit(AIPP30Input,".")(1)])

xls_NewExcel(); xls_Open(MapTableDoc); xls_SetWorksheet("MappingTable")
MapTable.All  = xls_GetData("A1:E50"); xls_SetWorksheet("GasSpeciesTable")
MapTable.GasSpecies = xls_GetData("A2:E50"); xls_Close(); xls_Quit();

ChamberConfig = ReadAIPP30InputDeck(AIPP30Input);
fnaipp3=AIPP30Doc;
aipp3=readaipp3(fnaipp3);
aipp3=PreprocessAIPP3(aipp3,ChamberConfig);

[data, header] = fscanfMat(AIPP235Doc);

splits = tokens(header(1,:))
ChamberCount.AIPP235 =  strtod(strsubst(splits(grep(splits,"Pabs")($)),"Pabs",""))
ChamberCount.AIPP30 = max(size(ChamberConfig))

if ChamberCount.AIPP235 ~= ChamberCount.AIPP30 then
    mprintf("%s \n", "Chamber Count Mismatch")
    break
end

SIMDATA = ParseMapTable(data,header,MapTable.All,aipp3,MapTable.GasSpecies,ChamberConfig)
SIMDATA = ConvertPyroPilesToChambers(SIMDATA,ChamberConfig)
SIMDATA = CorrectUnits(SIMDATA)





subplot(121)
MultiPlotFromInput(SIMDATA,"Time","Absolute_Pressure","in_upper_right")
subplot(122)
MultiPlotFromInput(SIMDATA,"Time","Temperature","in_upper_right")

//Function input: PlotFromInput(Input Structure, X Quantity, Y Quantity, Legend Location)
PlotFromInput(SIMDATA,"Time","EDOTOUT","in_upper_right")
PlotFromInput(SIMDATA,"Time","Mass_Flow_To_Tank","in_upper_right")
PlotFromInput(SIMDATA,"Time","MDOTOUT","in_upper_right")
//PlotFromInput(SIMDATA,"Time","MDOTGEN","in_upper_right")
PlotFromInput(SIMDATA,"Time","EDOTGEN","in_upper_right")
//PlotFromInput(SIMDATA,"Time","SURF","in_upper_right")
//PlotFromInput(SIMDATA,"Time","DB","in_upper_right")
//PlotFromInput(SIMDATA,"Time","BURNRATE","in_upper_right")
PlotFromInput(SIMDATA,"Time","QWALL","in_lower_right")
PlotFromInput(SIMDATA,"Time","EWALL","in_lower_right")
PlotFromInput(SIMDATA,"Time","TWALL","in_lower_right")

SavePlots(Folder_Out)
clear("l1","l2","l3","l4","last_start","out_count","out_json","rep","rows"...
,"today","inp_json","i","header","folderinfo","fnaipp3","data","Folder_Out"...
,"AIPP235Doc","AIPP30Doc","AIPP30Input","FunctionDir","MapTableDoc"...
,"StartingDir", "ans","inp_count","content")
