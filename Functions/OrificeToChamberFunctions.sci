function chamber = ConvertOrificeToChamber(input,ChamberConfig)    
    orif = input'
for i=1:1:max(size(ChamberConfig))
    if ChamberConfig(i).Out ~= "None"
       chamber_all = orif(:,ChamberConfig(i).Out) 
       temp = sum(chamber_all,2)
       chamber.Out(i,1:max(size(temp))) = temp
    else 
       chamber.Out(i,:) = 0
    end
    if ChamberConfig(i).In ~= "None"
       chamber_all = orif(:,ChamberConfig(i).In) 
       temp = sum(chamber_all,2)
       chamber.In(i,1:max(size(temp))) = temp
    else 
       chamber.In(i,:) = 0
    end
    
    chamber.Diff(i,:) = chamber.In(i,:)-chamber.Out(i,:)

end

endfunction

function aipp3fixed = PreprocessAIPP3(aipp3,ChamberConfig)
    aipp3fixed = aipp3
    fields = fieldnames(aipp3)
    rows = grep(fields,"flows")
    for i=1:1:max(size(rows))
        execstr(strcat(["temp=ConvertOrificeToChamber("...
        ,"aipp3.",fields(rows(i)),")"]))
        execstr(strcat(["aipp3fixed.",fields(rows(i)),"=temp.Out"]))
        if fields(rows(i)) == "mass_flows"
            aipp3fixed.mass_flow_tank = temp.Diff($,:)
            aipp3fixed.mass_flow_tank_units = aipp3.mass_flow_units
        end
    end
endfunction

function ChamberConfig = ReadAIPP30InputDeck(deckfile)
    dat = mgetl(deckfile)
    dat_struc = fromJSON(dat);
    chamber_str = "."
    chambercount = max(size(dat_struc.aipp_calculation.assembly.chambers))
    for i=1:1:chambercount
        chamber(i).In = "None"
        chamber(i).Out = "None"
    end
    orificecount = max(size(dat_struc.aipp_calculation.assembly.orifices))
    for i =1:1:orificecount
        to = dat_struc.aipp_calculation.assembly.orifices(i).to
        from = dat_struc.aipp_calculation.assembly.orifices(i).from
        
        if chamber(to).In == "None"
            chamber(to).In = i
        else
            chamber(to).In = cat(1,chamber(to).In,i)
        end
        
        if chamber(from).Out == "None"
            chamber(from).Out = i
        else
            chamber(from).Out = cat(1,chamber(from).Out,i)
        end        
        
    end
    
    for i =1:1:chambercount
        pyro_check = grep(fieldnames(dat_struc.aipp_calculation.assembly.chambers(i)),"pyro")

        if pyro_check ~= []
            pyro_inp = dat_struc.aipp_calculation.assembly.chambers(i).pyro
            pyro_count = max(size(pyro_inp));
            for j=1:1:pyro_count
                chamber(i).pyro(j).Formulation = pyro_inp(j).formulation
                chamber(i).pyro(j).Piles = pyro_inp(j).piles
                chamber(i).pyro(j).Shape = pyro_inp(j).shape
            end
        end
        
    end
    
    ChamberConfig = chamber   

endfunction

//mass_flows = ConvertOrificeToChamber(aipp3.mass_flows)

//ChamberConfig = ReadAIPP30InputDeck(AIPP30Input)
