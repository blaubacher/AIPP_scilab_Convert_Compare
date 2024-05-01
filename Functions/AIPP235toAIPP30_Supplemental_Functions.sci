function doubled_ints = ConvertIntsToDoublesJSON(json_txt, vars)
    for i=1:1:max(size(vars))
        mprintf("%s %s \n", "Converting ints to doubles for:", vars(i))
        rows = grep(json_txt, """" + vars(i))

        if rows ~= []
            for j=1:1:max(size(rows))
//                mprintf("\n%s \n %s\n", "Original string: ", json_txt(rows(j)))
                colsindex = strindex(json_txt(rows(j)),":")
                temp = strsplit(json_txt(rows(j)),":")(2)
//                mprintf("%s %s\n", "Data found after the colon:", temp)
                temp = strsplit(temp, " ")(2)                
//                mprintf("%s %s \n", "Data before the space: ", temp)
                numsindex = strindex(temp,"/[0-9]/",'r')
//                disp(numsindex)
                decindex = strindex(temp, ".")

                if decindex < max(numsindex)
                    numsindex = cat(2,numsindex,decindex)
                    numsindex = gsort(numsindex,'g', 'i')                    
                end
//                mprintf("%s %s\n", "Identified the following numerical input: ", part(temp, numsindex))
                new = strtod(part(temp,numsindex))
//                mprintf("%s %f \n", "Strtod output: ", new)
                replace = msprintf("%.6f", new)
//                mprintf("%s %s \n", "New string value: ", replace)
                exponentindex = strindex(json_txt(rows(j)), "^")
                if exponentindex ~= []
                    first = part(json_txt(rows(j)), 1:exponentindex)
                    second = part(json_txt(rows(j)), exponentindex + 1:$)
                    first = strsubst(first,part(temp, numsindex), replace)
                    first =  first + second
                    json_txt(rows(j)) = first
                else
                    json_txt(rows(j)) = strsubst(json_txt(rows(j)), ...
                    part(temp, numsindex),...
                    replace)
                end
            end
        end
    end
    doubled_ints = json_txt
endfunction

function FixedJSON = FixJSON(InputJSON)
    for i =1:1:max(size(InputJSON))
        FixedJSON(i) = strsubst(InputJSON(i),"\/","/")
    end    
endfunction

function FixedBraces = FixSquareBracesforPyro(JSONfromStructure)

    dat = JSONfromStructure
    pyrolocs = grep(dat,"pyro")
    for i=1:1:max(size(pyrolocs))
        dat(pyrolocs(i),1) = strsubst(dat(pyrolocs(i),1),"{","[{")
        bracelocs.start = grep(dat(pyrolocs(i):pyrolocs(i)+20,1),"{")
    bracelocs.end = grep(dat(pyrolocs(i):pyrolocs(i)+20,1),"}")
    if bracelocs.start(2) > bracelocs.end(1) then
row = pyrolocs(i)+bracelocs.end(1)-1
dat(row,1) = strsubst(dat(row,1),"}","}]")
else
row = pyrolocs(i)+bracelocs.end(2)-1
dat(row,1) = strsubst(dat(row,1),"}","}]")
end

end
FixedBraces = dat
endfunction

// script to plunge into any file to pull a subset of the data based on fieldnames
// and return a structure containing the fields
function [res]=GetNumFromDeck(fn, FieldString, TokenNumber)
    //a=mgetl(fn);
    a=fn;
    [x,y]=grep(a,FieldString)
    RowTokens=(a(x))
    res=strtod(tokens(RowTokens)(TokenNumber))
endfunction

// script to plunge into any file to pull a subset of the data based on fieldnames
// and return a structure containing the fields
function [res]=snagdata(dir,fn,fieldsin)
    [data,header]=fscanfMat(dir+fn)
    [col,row]=grep(tokens(header(1)),fieldsin);
    Fields=tokens(header(1))(col);
    res.time=data(:,1);
    [nf,kk]=size(Fields);
    for i=1:nf
        str=('res.'+Fields(i)+'=data(:,'+string(col(i))+');')   
        execstr(str);
    end
endfunction

// simple script to read in AIPP 3 output JSON file and pull it into a structure within SCILAB
function [res]=readaipp3(fn)
    a=mgetl(fn);
    a = strsubst(a, '[]', '[""""]')
    res=fromJSON(a)
endfunction

function [str]=nab(text,fieldname,tokennumber,unit)
    // function that identifies values in the DECK files and then
    // creates the proper translated entries for the JSON files
    [nrows,junk]=size(text)

    for i=1:nrows
        fields(i)=(tokens(text(i))($))
    end

    therow=find(fields==fieldname)

    str=tokens(text(therow))(tokennumber) +' ' +unit 

endfunction

// script to read in an entire ASCII file with headers and convert the table to a Structure
function [res]=filetostruct(dir,fn)
    [data,header]=fscanfMat(dir+fn)
    toks=tokens(header(1))
    [nc,x]=size(toks)
    for i=1:nc
        tag = strsubst(toks(i),'-','')
        str=('res.'+tag+'=data(:,'+string(i)+');')
        execstr(str);
    end

    // can easily output the new structure to a file using "toJSON" command
endfunction

// script to read in AIPP data and create a structure
// similar to how the JSON files from AIPP-3 are read in with 
// the filetostruct script (inside snagdata.sce)
//
function [res]=filetojsonstruct(dir,fn)
    [data,header]=fscanfMat(dir+fn)
    toks=tokens(header(1))
    [x,ncham]=size(grep(toks,'Pabs'));

    grab=['time','Pabs','Prel','Temp','Texit','Twall','Tpack','Mdot','IF','CPSIF'];
    [this,that]=size(grab);

    for i=1:that
        cols=grep(toks,grab(i))
        str=['res.'+grab(i)+'=data(:,cols)'];
        execstr(str);
    end

    // can easily output the new structure to a file using "toJSON" command
endfunction

function [structure] = pyrotojson4(fn)


    res=mgetl(fn)
    fields=tokens(res(1))
    units=tokens(res(2))
    values=tokens(res(3))
    [nfields,junk]=size(fields)

    // strip the parenthesis off of the strings


    filename=strsplit(fn,'\')
    [x,y]=size(filename)
    filename=filename(x)
    filename=strsplit(filename,'.') // strip off just the filename
    filename=filename(1)  // strip off the file extension

    for i=1:nfields
        units(i)=part(units(i),2:$-1)
    end
    species=['H2O','CO2','N2','O2','Ar','He','H2','CO','N2O']
    [junk,nspecies]=size(species)

    //    str=(filename'='+'""'+filename(1)+'""')
    //   execstr(str);

    for i=1:nspecies        
        sname=(fields(i+1))        
        index=find(fields==sname) // gets the index for the species
        value=strtod(tokens(values(index)))*10.0
        if value ~= 0 
            str="this.gas_yields."+sname+'=""'+string(value)+' mol/kg""'
            //            disp('str is ',str)
            execstr(str)
        end
    end
    str="this.Temperature="""+string(values(12))+" K"""
    execstr(str)    
    str="this.Density="""    +string(values(15))+" g/cm^3"""
    execstr(str)    
    str="this.reference_burn_rate="""+string(values(16))+" mm/s"""
    execstr(str)    
    str="this.burn_rate_exponent="+string(values(17))
    execstr(str)    
    str="this.burn_rate_temperature_sensitivity="""+string(values(18))+' 1/K""'
    execstr(str)    


    // now clean up the WC info
    //    disp("values 14 =",values(14),"values 13 = ", values(13))
    if strtod(values(14)) == 0
        values(14) = "5"
        //        disp("values 14 triggered")
    end
    if strtod(values(13)) == 0 then
        values(13) = "50"
        //        disp("values 13 triggered")
    end
    str="this.wild_card = struct(''Cp/R''" +',' +string(values(14)) +')'
    execstr(str) 
    str="this.wild_card.molar_mass="""+string(values(13))+' g/mol""'
    execstr(str)        
    str="this.wild_card.wc_gas_yield="""+string(strtod(values(11))*10.0)+' mol/kg""'
    execstr(str)               

    structure=this;
endfunction


function [this]=makepyrofiles()
    // for each file, run 'pyrotojson', create an array
    // of structures, then write to the all2.json output file
    S=dir('c:\aipp23\pyrofiles\*.pyro')
    [nfiles,junk]=size(S.name);
    for i=1:nfiles
        filename=strsplit(S.name(i),'\')
        mprintf("%s \n","*****"+filename) 
        [x,y]=size(filename)
        filename=filename(x)
        mprintf("%s \n","*****"+filename) 
        filename=strsplit(filename,'.') // strip off just the filename
        str='this.'+strsubst(filename(1),"-","_")+'=pyrotojson4(S.name(i))'
        //        disp(str)
        execstr(str)
    end   
    toJSON(this,4,'c:\aipp23\pyrofiles\pyrolist.json')
    PyroStrings = mgetl("c:\aipp23\pyrofiles\pyrolist.json")
    FixedJSON = FixJSON(PyroStrings)
    vars = ["burn_rate_exponent","Cp/R","molar_mass","wc_gas_yield"]
    doubled_ints = ConvertIntsToDoublesJSON(FixedJSON, vars)    
    csvWrite(doubled_ints,"c:\aipp23\pyrofiles\pyrolist.json")
endfunction
