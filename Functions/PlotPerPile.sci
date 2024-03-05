
function PlotPerPile(SIMDATA,Var)
    pyro = SIMDATA.Pyro_Output; pyro_names = fieldnames(pyro)
    for i =1:1:max(size(pyro_names))
        disp(pyro_names(i))
        execstr("TempPyro =pyro."+pyro_names(i))
        Chambers = fieldnames(TempPyro)
        disp(Chambers)
        for j=1:1:size(Chambers,"r")
            figure_info = gcf()
            fig_number = figure_info.figure_id + 1
            output_fig = figure(fig_number)
            execstr("VarDat = TempPyro."+Chambers(j)+"."+Var)
            Piles = fieldnames(VarDat)
            rows = grep(Piles,"Pile")
            for k=1:1:max(size(rows))
                execstr("y = VarDat."+Piles(rows(k))+".Data")
                execstr("yUnit = VarDat."+Piles(rows(k))+".Units")
                plot(SIMDATA.Time.AIPP_3_0.Data,y); e(k,fig_number) = gce()
                leg_holder(k,fig_number) = Piles(rows(k))
                set(gca(),"auto_clear","off")
            end
            legend(e(:,fig_number),leg_holder(:,fig_number))
            xlabel("Time (ms)")
            ylabel(Var+" ("+yUnit+")")
            title(strsubst(pyro_names(i),"_",":")+" - "+Chambers(j))
            alvsfs(gcf())
        end
    end
    
    
   
endfunction


//PlotPerPile(SIMDATA,"DB")
