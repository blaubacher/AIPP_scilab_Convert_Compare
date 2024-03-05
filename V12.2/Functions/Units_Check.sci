function struc_corrected = CorrectUnits(struc_inp)
    dat = struc_inp
    allfields = fieldnames(struc_inp)
    for i =1:1:max(size(allfields))
        execstr(strcat(["temp=fieldnames(dat.",allfields(i),")"]))
        if grep(temp, "Chamber") ~= []
            for j=1:1:max(size(temp))
                execstr(strcat(["temp2=fieldnames(dat.",allfields(i)...
                ,".",temp(j),")"]))
                if max(size(temp2))==2
                    execstr(strcat(["aipp235unit=dat."...
                    ,allfields(i),".",temp(j),".",temp2(1),".Unit"]))
                    execstr(strcat(["aipp30unit=dat."...
                    ,allfields(i),".",temp(j),".",temp2(2),".Unit"]))
                    if aipp235unit ~= aipp30unit
                        execstr(strcat(["mismatch_units_list(i,1)=allfields(i)"]))
                        execstr(strcat(["mismatch_units_list(i,2)= aipp235unit"]))
                        execstr(strcat(["mismatch_units_list(i,3)= aipp30unit"]))
                        factor = correct_units(aipp235unit,aipp30unit)
                        execstr(strcat(["dat.",allfields(i),".",temp(j)...
                        ,".",temp2(2),".Unit=aipp235unit"]))
                        execstr(strcat(["corrected = dat.",allfields(i),"."...
                        ,temp(j),".",temp2(2),".Data"]))
                        corrected = corrected*strtod(factor)
                        execstr(strcat(["dat.",allfields(i),"."...
                        ,temp(j),".",temp2(2),".Data=corrected"]))
                                                   
                    end
                end
            end
        else
            if max(size(temp)) == 2 & grep(temp,"AIPP_2_3_5") ~= []
                execstr(strcat(["aipp235unit =dat.",allfields(i),"."temp(1),".Unit"]))

                execstr(strcat(["aipp30unit =dat.",allfields(i),"."temp(2),".Unit"]))
                if aipp235unit ~= aipp30unit
                        execstr(strcat(["mismatch_units_list(i,1)=allfields(i)"]))
                        execstr(strcat(["mismatch_units_list(i,2)= aipp235unit"]))
                        execstr(strcat(["mismatch_units_list(i,3)= aipp30unit"]))  
                        factor = correct_units(aipp235unit,aipp30unit)
                        execstr(strcat(["dat.",allfields(i),".",temp(2)...
                        ,".Unit=aipp235unit"]))
                        execstr(strcat(["corrected = dat.",allfields(i),"."...
                        ,temp(2),".Data"]))
                        corrected = corrected*strtod(factor)
                        execstr(strcat(["dat.",allfields(i),"."...
                        ,temp(2),".Data=corrected"]))                     
                end
            end                      
        end                
    end
    csvWrite(mismatch_units_list,"MismatchedUnitsSummary.txt")
    struc_corrected = dat
endfunction

function corr_factor = correct_units(AIPP235unit,AIPP30unit)
    corr_table = [  "kg/s",   "g/s",    "0.001";...
                       "W",    "MW", "1000000";...
                  "kg/sec",   "g/s",    "0.001";...
                     "mm2",  "cm^2",      "100";]
    row = find(corr_table(:,1) == AIPP235unit & corr_table(:,2) == AIPP30unit)
    if row == [] then
        messagebox("ERROR: Unit correction information is not available.",...
        "Please update the corr_table found in Units_Check.sci")
        break
    end
    corr_factor = corr_table(row,3)             
endfunction

