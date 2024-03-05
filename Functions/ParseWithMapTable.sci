function [struc] = ParseMapTable(data,header,MpTable,aipp3, GasSpecies,aipp3inp)
titles = matrix(tokens(header(1)),1,-1)
units = strsubst(strsubst(header(2),"(",""),")","")
units = matrix(tokens(units),1,-1)

fileslist = dir()
extrarows = grep(fileslist.name,"/^aippextra[0-9]/",'r')
if extrarows ~= [] then
    for i =1:1:max(size(extrarows))
        ChamberNo = strtod(strsubst(strsplit(fileslist.name(extrarows(i)),".")(1),"aippextra",""))
        [extra_data, extra_header] = fscanfMat(fileslist.name(extrarows(i)))
        
        extra_titles = matrix(tokens(extra_header(1)),1,-1)
        extra_units = matrix(tokens(extra_header(2)),1,-1)
        TWALLrow = find(extra_titles == "Twall")
        extra_titles = cat(2,extra_titles(1:TWALLrow-1),extra_titles(TWALLrow+1:$))
        extra_units = cat(2,extra_units(1:TWALLrow-1),extra_units(TWALLrow+1:$))
        extra_data = cat(2,extra_data(:,1:TWALLrow-1),extra_data(:,TWALLrow+1:$))
        for j =1:1:max(size(extra_titles))
            extra_titles(1,j) = strcat([extra_titles(1,j),string(ChamberNo)])
        end
        data = cat(2,data,extra_data)
        disp(titles); disp(extra_titles);
        titles = cat(2,titles,extra_titles)
        units = cat(2, units,extra_units)
    end
end

MapTable.All = MpTable
stop = min(find(length(MapTable.All(:,1))==0))-1;
MapTable.All = MapTable.All(1:stop,:);
headers = strsubst(strsubst(MapTable.All(1,:),".","_")," ","_");
col_MV = grep(headers,"MappedVariable"); col_3_0 = find(headers == "AIPP_3_0")
col_Basis = grep(headers,"Basis"); col_3_0_units = find(headers == "AIPP_3_0_Units")
chamber_count.AIPP_2_3_5 = max(strtod(strsubst(titles(grep(titles,"Pabs")),"Pabs","")));
chamber_count.AIPP_3_0 = max(size(aipp3inp));

if chamber_count.AIPP_2_3_5 ~= chamber_count.AIPP_3_0 then
    messagebox(["The number of changes between AIPP 2.3.5 and AIPP 3.0 is not consistent" "Please verify your inputs"]...
    , "ERROR: Chamber Mismatch")
end

table_info = MapTable.All(2:$,:);
for i =1:1:max(size(table_info))
    mprintf("Processing %s AIPP 2.3.5 Data\n",table_info(i,col_MV))
    check_WC = strindex(table_info(i,1),"*")

    if check_WC == []
        row = find(titles == table_info(i,1))
        execstr(strcat(["SIMDATA.",table_info(i,col_MV),".AIPP_2_3_5.Data=data(:,row)"]))
        execstr(strcat(["SIMDATA.",table_info(i,col_MV),".AIPP_2_3_5.Unit=units(:,row)"]))        
    else
        for j =1:1:chamber_count.AIPP_2_3_5
            var = strsplit(table_info(i,1),"*")(1);
            row = find(titles == strcat([var,string(j)]))
            execstr(strcat(["SIMDATA.",table_info(i,col_MV),".Chamber",string(j),".AIPP_2_3_5.Data=data(:,row)"]))
            execstr(strcat(["SIMDATA.",table_info(i,col_MV),".Chamber",string(j),".AIPP_2_3_5.Unit=units(:,row)"]))        
        end     
    end

    if table_info(i,col_3_0) ~= ""
        mprintf("Processing %s AIPP 3.0 Data on a per %s basis \n",table_info(i,col_MV), table_info(i,col_Basis))

        select table_info(i,col_Basis)

        case("orifice") then 
            for j =1:1:chamber_count.AIPP_3_0
                mprintf("---> Chamber %i converted from per orifice basis to per chamber basis\n",j)
                execstr(strcat(["SIMDATA.",table_info(i,col_MV),".Chamber",string(j)...
                ,".AIPP_3_0.Data=aipp3.",table_info(i,col_3_0),"(",string(j)",:)"]))
                execstr(strcat(["SIMDATA.",table_info(i,col_MV),".Chamber",string(j)...
                ,".AIPP_3_0.Unit=aipp3.",table_info(i,col_3_0_units)]))
            end
            
        case("chamber")
            for j =1:1:chamber_count.AIPP_3_0
                execstr(strcat(["SIMDATA.",table_info(i,col_MV),".Chamber",string(j)...
                ,".AIPP_3_0.Data=aipp3.",table_info(i,col_3_0),"(",string(j)",:)"]))
                execstr(strcat(["SIMDATA.",table_info(i,col_MV),".Chamber",string(j)...
                ,".AIPP_3_0.Unit=aipp3.",table_info(i,col_3_0_units)]))
            end
            
        case("individual")
            execstr(strcat(["SIMDATA.",table_info(i,col_MV)...
            ,".AIPP_3_0.Data=aipp3.",table_info(i,col_3_0),"(1,:)"]))
            execstr(strcat(["SIMDATA.",table_info(i,col_MV)...
            ,".AIPP_3_0.Unit=aipp3.",table_info(i,col_3_0_units)]))
            
        case("pyro")
            for j=1:1:size(aipp3.pyro_names)(1)
                if aipp3.pyro_names(j) ~= []
                    for k=1:1:size(aipp3.pyro_names(j),"c")
                        execstr(strcat(["SIMDATA.Pyro_Output."...
                        ,aipp3.pyro_names(j)(k),".Chamber",string(j),"."...
                        ,table_info(i,col_MV),".Data=aipp3."...
                        ,table_info(i,col_3_0),"(j)(1,:)"]))
                        execstr(strcat(["SIMDATA.Pyro_Output."...
                        ,aipp3.pyro_names(j)(k),".Chamber",string(j)...
                        ,".",table_info(i,col_MV),".Unit=aipp3."...
                        ,table_info(i,col_3_0_units)]))
                    end
                end
            end
            
        case("pile")
            for j=1:1:size(aipp3.pyro_names)(1)
                if aipp3.pyro_names(j) ~= []
                    PyroCountPerChamber = size(aipp3.pyro_names(j),"c")
                    execstr(strcat(["temp=aipp3.",table_info(i,col_3_0),"(j)"]))
                    TypeCheck = typeof(temp)
                    mprintf("var is of type %s\n",TypeCheck)

                    if TypeCheck =="list"
                        
                        for k=1:1:PyroCountPerChamber
                            execstr(strcat(["temp=aipp3."...
                            ,table_info(i,col_3_0),"(j)(k)"]))
                            for m=1:1:size(temp,"r")
                                execstr(strcat(["SIMDATA.Pyro_Output."...
                                ,aipp3.pyro_names(j)(k),".Chamber",string(j),"."...
                                ,table_info(i,col_MV),".Pile",string(m)...
                                ,".Data=aipp3.",table_info(i,col_3_0)...
                                ,"(j)(k)(m,:)"]))
                                execstr(strcat(["SIMDATA.Pyro_Output.",...
                                aipp3.pyro_names(j)(k),".Chamber",string(j)...
                                ,".",table_info(i,col_MV),".Pile",string(m)...
                                ,".Units=aipp3.",table_info(i,col_3_0_units)]))
                            end             
                            execstr(strcat(["SIMDATA.Pyro_Output."...
                            ,aipp3.pyro_names(j)(k),".Chamber",string(j),"."...
                            ,table_info(i,col_MV),".Total.Data = sum(aipp3."...
                            ,table_info(i,col_3_0),"(j)(k),''r'')"]))                
                        end


                    elseif TypeCheck == "constant"
                        execstr("Check = aipp3.pyro_names(j)")
                        if Check ~= [] 
                            for k=1:1:max(size(temp,"r"))
                                execstr(strcat(["SIMDATA.Pyro_Output."...
                                ,aipp3.pyro_names(j)(1),".Chamber",string(j),"."...
                                ,table_info(i,col_MV),".Pile",string(k)...
                                ,".Data=aipp3.",table_info(i,col_3_0)...
                                ,"(j)(k,:)"]))
                                execstr(strcat(["SIMDATA.Pyro_Output.",...
                                aipp3.pyro_names(j)(1),".Chamber",string(j)...
                                ,".",table_info(i,col_MV),".Pile",string(k)...
                                ,".Units=aipp3.",table_info(i,col_3_0_units)]))
                            end
                            execstr(strcat(["SIMDATA.Pyro_Output."...
                            ,aipp3.pyro_names(j),".Chamber",string(j),"."...
                            ,table_info(i,col_MV),".Total.Data = sum(aipp3."...
                            ,table_info(i,col_3_0),"(j),''r'')"]))       
                        end               
                    end
                end
            end            
        end
    end

end
struc = SIMDATA
endfunction


//[SIMDATA] = ParseMapTable(data,header,MapTable.All,aipp3,MapTable.GasSpecies,ChamberConfig)

