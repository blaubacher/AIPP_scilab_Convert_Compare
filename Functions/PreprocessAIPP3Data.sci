function VarSum = SumListComponents(inp_struc)
    pyro_count = size(inp_struc,"r");
    for i=1:1:pyro_count
        if inp_struc(i).Data ~= []
            if isdef("temp") == %f
                temp = inp_struc(i).Data
            else 
                temp = cat(1,temp,inp_struc(i))
            end                        
        end
    end
    
    VarSum = sum(temp,"r")
end

function SIMDATA_OUT = ConvertPyroPilesToChambers(SIMDATA,ChamberConfig)
        Pyros = SIMDATA.Pyro_Output
        PyroNames = fieldnames(Pyros);
        TotalChambers = size(ChamberConfig,"r")
        for i =1:1:max(size(PyroNames))
            mprintf("Converting %s to a per chamber basis\n",PyroNames(i))
            execstr(("Chambers = Pyros."+PyroNames(i)));
            ChamberNo = strsubst(fieldnames(Chambers),"Chamber","");
            for j=1:1:TotalChambers
                if grep(ChamberNo,string(j)) == []
                    mprintf("---> %s is not present in Chamber %i\n"...
                    ,PyroNames(i),j)
                else
                    mprintf("---> %s found in Chamber %i\n",PyroNames(i),j)
                    execstr("vars = Chambers.Chamber"+string(j))
                    VarNames = fieldnames(vars)
                    execstr("stop = max(size(vars."+VarNames(1)+".Data))");
                    for k=1:1:size(VarNames,"r")
                        execstr("PilesCheck = grep(fieldnames(vars."...
                        +VarNames(k)+"),''Pile'')")
                        
                        if PilesCheck == []
//                            mprintf("------> %s has no piles\n",VarNames(k))
                            execstr("Contribution."+VarNames(k)+".Chamber"...
                            +string(j)+"("+string(i)+").Data = "...
                            +"SIMDATA.Pyro_Output."+PyroNames(i)+".Chamber"...
                            +string(j)+"."+VarNames(k)+".Data")
                            execstr("Contribution."+VarNames(k)+".Unit ="...
                            +"SIMDATA.Pyro_Output."+PyroNames(i)+".Chamber"...
                            +string(ChamberNo(1))+"."+VarNames(k)+".Unit")
                        else
                            mprintf("------> %s has %i piles\n",VarNames(k)...
                            ,max(size(PilesCheck)))
                            execstr("Contribution."+VarNames(k)+".Chamber"+string(j)...
                            +"("+string(i)+").Data = "+"SIMDATA.Pyro_Output."...
                            +PyroNames(i)+".Chamber"+string(j)+"."+VarNames(k)...
                            +".Total.Data")
                            execstr("Contribution."+VarNames(k)+".Unit ="...
                            +"SIMDATA.Pyro_Output."+PyroNames(i)+".Chamber"...
                            +string(ChamberNo(1))+"."+VarNames(k)+".Pile1.Units")
                        end
                    end
                end
            end
        end
        
        ConvertedVars = fieldnames(Contribution);
        for i=1:1:size(ConvertedVars,"r")
            for j=1:1:TotalChambers
                try
                    execstr("inp = Contribution."+ConvertedVars(i)+".Chamber"...
                    +string(j))
                    VarSum = SumListComponents(inp)
                    execstr("SIMDATA."+ConvertedVars(i)+".Chamber"+string(j)...
                    +".AIPP_3_0.Data=VarSum")
                    execstr("SIMDATA."+ConvertedVars(i)+".Chamber"+string(j)...
                    +".AIPP_3_0.Unit = Contribution."+ConvertedVars(i)...
                    +".Unit")..
                catch
                    execstr("SIMDATA."+ConvertedVars(i)+".Chamber"+string(j)...
                    +".AIPP_3_0.Data = zeros(1,stop)")
                    execstr("SIMDATA."+ConvertedVars(i)+".Chamber"+string(j)...
                    +".AIPP_3_0.Unit = Contribution."+ConvertedVars(i)...
                    +".Unit")...
                    
                end                
            end
        end
        
        SIMDATA_OUT = SIMDATA       
end



//fixed = PreprocessAIPP3(aipp3)

//TestStruc = ConvertPyroPilesToChambers(SIMDATA,ChamberConfig)
