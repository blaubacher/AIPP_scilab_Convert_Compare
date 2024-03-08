function ParseAndPlot(InpStruc,X,Y,LegendLocation,input_fig)
    dat = InpStruc
    f1 = input_fig; drawlater();
    execstr(strcat(["xdat = dat.",X]))
    execstr(strcat(["ydat = dat.",Y]))    
    fields.X = fieldnames(xdat)
    fields.Y = fieldnames(ydat)
    fields.XChambers = grep(fields.X,"Chamber")
    fields.YChambers = grep(fields.Y,"Chamber")
    mismatch_check = fields.XChambers == fields.YChambers
    if mismatch_check == %f then
        if fields.XChambers == []
            for i = 1:1:max(size(fields.YChambers))
                execstr(strcat(["dat.",X,".Chamber",string(i),".AIPP_2_3_5.Data=dat."...
                ,X,".AIPP_2_3_5.Data"]))
                execstr(strcat(["dat.",X,".Chamber",string(i),".AIPP_2_3_5.Unit=dat."...
                ,X,".AIPP_2_3_5.Unit"]))
                execstr(strcat(["dat.",X,".Chamber",string(i),".AIPP_3_0.Data=dat."...
                ,X,".AIPP_3_0.Data"]))
            end
        elseif fields.YChambers == []
        for i = 1:1:max(size(fields.XChambers))
                execstr(strcat(["dat.",Y,".Chamber",string(i),".AIPP_2_3_5.Data=dat."...
                ,Y,".AIPP_2_3_5.Data"]))
                execstr(strcat(["dat.",Y,".Chamber",string(i),".AIPP_2_3_5.Unit=dat."...
                ,Y,".AIPP_2_3_5.Unit"]))
                execstr(strcat(["dat.",Y,".Chamber",string(i),".AIPP_3_0.Data=dat."...
                ,Y,".AIPP_3_0.Data"]))
            end
        end
    end  
    
if grep(fields.X, "Chamber") ~= [] | grep(fields.Y, "Chamber") ~= [] then
    EC = 1
    stop = max([max(size(fields.X)),max(size(fields.Y))])
    for i=1:1:stop
        execstr(strcat(["x235=dat.",X,".Chamber",string(i),".AIPP_2_3_5.Data"]))
        execstr(strcat(["xunit=dat.",X,".Chamber",string(i),".AIPP_2_3_5.Unit"]))
        execstr(strcat(["y235=dat.",Y,".Chamber",string(i),".AIPP_2_3_5.Data"]))
        execstr(strcat(["yunit=dat.",Y,".Chamber",string(i),".AIPP_2_3_5.Unit"]))
        execstr(strcat(["x3=dat.",X,".Chamber",string(i),".AIPP_3_0.Data"]))
        execstr(strcat(["y3=dat.",Y,".Chamber",string(i),".AIPP_3_0.Data"]))
        
        
        if Y == "Absolute_Pressure" & i==stop
            a=gca()
            axis_size = a.axes_bounds
            b=newaxes()   
            b.filled="off"
            b.y_location="right"       
            b.axes_visible="off"
            b.axes_bounds = axis_size
            EC = 1; AC = 2; 
            y235 = y235*1000; y3 = y3*1000;
        else
            AC = 1
        end
        plot(x235,y235)
        set(gca(),"auto_clear","off")
        entity(AC,EC) = gce()
        legend_holder(AC,EC) = strcat(["AIPP 2.3.5 Chamber ",string(i)])
        EC=EC+1
        plot(x3(1,:),y3(1,:))
        entity(AC,EC) = gce()
        legend_holder(AC,EC) = strcat(["AIPP 3.0 Chamber ",string(i)])
        EC=EC+1
    end
    
elseif grep(fields.X, "Chamber") == [] & grep(fields.Y, "Chamber") == [] 
    execstr(strcat(["x235=dat.",X,".AIPP_2_3_5.Data"]))
    execstr(strcat(["xunit=dat.",X,".AIPP_2_3_5.Unit"]))
    execstr(strcat(["y235=dat.",Y,".AIPP_2_3_5.Data"]))
    execstr(strcat(["yunit=dat.",Y,".AIPP_2_3_5.Unit"]))
    execstr(strcat(["x3=dat.",X,".AIPP_3_0.Data"]))
    execstr(strcat(["y3=dat.",Y,".AIPP_3_0.Data"]))
    plot(x235,y235)
    set(gca(),"auto_clear","off")
    entity(1,1) = gce()
    legend_holder(1,1) = "AIPP 2.3.5 "
    plot(x3(1,:),y3(1,:))
    entity(1,2) = gce()
    legend_holder(1,2) = "AIPP 3.0 "
    AC=1;
end   
    title("AIPP 3.0 Comparison")
    xlabel(strcat([strsubst(X,"_"," ")," (",xunit,")"]));
    fig_info = gcf(); axes_count = size(fig_info.children)
    
    if axes_count(1) == 2 then
        sca(a); 
        fig_info.children(2).y_label.text = strcat([strsubst(Y,"_"," ")," (",yunit,")"]);
        l1 = legend(entity(1,:),legend_holder(1,:),"legend_location","in_upper_left")
        sca(b)
        fig_info.children(1).y_label.text = strcat([strsubst(Y,"_"," ")," Tank (","KPa)"])
        l2 = legend(entity(2,:),legend_holder(2,:),"legend_location","in_upper_right")
        b.axes_bounds = a.axes_bounds
    else
        ylabel(strcat([strsubst(Y,"_"," ")," ",yunit]))
        legend(entity(AC,:),legend_holder(AC,:),"legend_location",LegendLocation)
    end
    alvsfs(f1)

    
drawnow()
endfunction

function output_fig =  MultiPlotFromInput(InpStruc,X,Y,LegendLocation)
    figure_info = gcf()
    fig_number = figure_info.figure_id  
    output_fig = figure(fig_number) 
    ParseAndPlot(InpStruc,X,Y,LegendLocation,output_fig)
endfunction

function output_fig =  PlotFromInput(InpStruc,X,Y,LegendLocation)
    figure_info = gcf()
    fig_number = figure_info.figure_id + 1  
    output_fig = figure(fig_number);
    ParseAndPlot(InpStruc,X,Y,LegendLocation,output_fig)
endfunction

function SavePlots(folder_info)
    start = pwd();
    check = dir().name;
    if grep(check,"SavedPlots") ~= [] then
        cd(".\SavedPlots"); 
    else
        createdir("SavedPlots")
        cd(".\SavedPlots"); 
    end
        
    createdir(folder_info); cd(folder_info)
    all = winsid();
    MP_Count = 1
    for i=1:1:max(size(all))
       temp = figure(all(i))
       if max(size(temp.children)) >1
        filename = "Multiplot"+string(MP_Count)
        MP_Count = MP_Count + 1
        filename = folder_info+filename
        xsave(filename+".scg", all(i))
        xs2png(all(i),filename+".png")        
       else
        x = temp.children(1).x_label.text; y = temp.children(1).y_label.text;        
        x = strsplit(strsubst(strsubst(x,"$\mathbf{",""),"}$",""),"\;")(1)
        y = strsplit(strsubst(strsubst(y,"$\mathbf{",""),"}$",""),"\;")(1)
        filename = folder_info+"_"+x+"_"+y;
        xsave(filename+".scg", all(i))
        xs2png(all(i),filename+".png")
       end
    end
    cd(start)
endfunction



