
scf(6)

f = gcf()

graph_contents = f.children(1).children

legend_entries = graph_contents(1).text
legend_links = graph_contents(1).links

for i =1:1:max(size(legend_entries))
    legend_entries(i) = strsubst(legend_entries(i),"$\mathbf{","")
    legend_entries(i) = strsubst(legend_entries(i),"}$","")
    legend_entries(i) = strsubst(legend_entries(i),"\;"," ")
    mprintf("%s \n", legend_entries(i))
end

TotalChambers = strsplit(legend_entries($)," ")($)

tank_curves = grep(legend_entries,"Chamber " + TotalChambers)

curves = legend_links(tank_curves)
curve_names =  graph_contents(1).text(tank_curves)

figure
for i =1:1:size(curves,'c')
    dat =curves(i).data
    x = dat(:,1); y = dat(:,2)
    e(i) = plot(x,y)
//    e(i) = gce()
end
legend(e,curve_names)
xlabel(f.children(1).x_label.text)
ylabel(f.children(1).y_label.text)
alvsfs(gcf())

