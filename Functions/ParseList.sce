
vars = fieldnames(aipp3)

for i =1:1:max(size(vars))
    execstr(strcat(["type_test(i) = typeof(aipp3.",vars(i),")"]))
//    mprintf("%s is of type: %s\n", vars(i),type_test(i))
    if type_test(i) == "list"
        mprintf("\n \n %s is a list\n", vars(i))
        execstr(strcat(["stop=size(aipp3."vars(i),")"]))
        for j=1:1:stop
            execstr(strcat(["aipp3.",vars(i),"(j)"]))
        end
    end
end
