// Copyright (C) 2024 - Autoliv - B. Laubacher
//
// Date of creation: May 8, 2024
//

function [ac]=GetTimes1(text)   
    outputdt_row=3
    time_step_row=4
    end_time_row=5
    ac.time_specs.output_time_step=nabstr(text,outputdt_row,1,'s')
    ac.time_specs.simulation_time_step=nabstr(text,time_step_row,1,'s')
    ac.time_specs.end_time=nabstr(text,end_time_row,1,'s')
endfunction
    
function [ac]=GetChamberDetails1(ac, text)
    specnames=['h2o','co2','n2','o2','h2','co','he','ar','n2o']
    propername=["H2O","CO2",'N2','O2','H2','CO','He','Ar','N2O']
    [junk,nspecies]=size(specnames)
    ncham=nabval(text,2,1);
    disp('ncham',ncham)
    // start assembly.chambers
    // enter locations in aipp.inp to find the values of :
    gas_volume_row=16
    conditioning_temperature_row=13
    gas_mass_row=17
    for i=1:ncham
        if(i<ncham)
            ac.assembly.chambers(i).volume=nabstr(text,gas_volume_row,i,'mm^3')
        else
            ac.assembly.chambers(i).volume=nabstr(text,gas_volume_row,i,'L')
        end
        ac.assembly.chambers(i).temperature=nabstr(text,conditioning_temperature_row,i,'K') // it's always the first token for all chambers
        ac.assembly.chambers(i).mass=nabstr(text,gas_mass_row,i,'g')
        for j=18:26 // aipp.inp rows for species mole fractions
            maybe_value=nabval(text,j,i)
            if(maybe_value > 0) then
                strtoex='ac.assembly.chambers('+string(i)+').mol_fractions.'+propername(j-17)+'='+string(maybe_value)
                execstr(strtoex)
            end
        end
    end  
endfunction


function [ac]=GetPyroDetails1(ac, text)
    pi=3.14159265
    pyro_file_row=42
    pyro_mass_row=43
    pyro_density_row=50
    flame_spread_row=55
    ignition_delay_row=54
    burn_rate_row=51
    n_row=52
    sigmap_row=53
    shape_row=44

    ncham=nabval(text,2,1)

    for i=1:ncham
        temp=nabstr(text,pyro_file_row,i,"")
        disp('temp is ',temp)
        name=(strsplit(temp,'.'))(1) // omit the .pyro file extension
        pyromass=nabval(text,pyro_mass_row,i);
        rho=nabval(text,pyro_density_row,i)
//        disp('first pyromass is ',pyromass)

        if pyromass ~= 0 then
            ac.assembly.chambers(i).pyro.formulation=strsubst(name,"-","_")
            // get the actual number of the density 
            ac.assembly.chambers(i).pyro.density=nabstr(text,pyro_density_row,i,'g/cm^3')           
            ac.assembly.chambers(i).pyro.amount=msprintf("%.6f",pyromass)+' g'
            ac.assembly.chambers(i).pyro.piles=1
            ac.assembly.chambers(i).pyro.flame_spread_time=nabstr(text,flame_spread_row,i,'s')  
            ac.assembly.chambers(i).pyro.ignition_time=nabstr(text,ignition_delay_row,i,'s')      
            ac.assembly.chambers(i).pyro.reference_burn_rate=nabstr(text,burn_rate_row,i,'mm/s')
            ac.assembly.chambers(i).pyro.burn_rate_exponent=nabval(text,n_row,i)
            ac.assembly.chambers(i).pyro.burn_rate_temperature_sensitivity=nabstr(text,sigmap_row,i,'1/K')                
            ac.assembly.chambers(i).pyro.amount=nabstr(text,pyro_mass_row,i,'g')        
            // now a somewehat complex process is involved to identify the proper tags for the different shapes, so this will  be a 'case' statement
            shape_code=nabval(text,shape_row,i)

            select shape_code
            case(1) then // tablet (don't need to worry about the number of tablets, aipp will calc that)
                ac.assembly.chambers(i).pyro.shape.geometry="tablet"
                ac.assembly.chambers(i).pyro.shape.total_height=nabstr(text,47,i,'mm') 
                ac.assembly.chambers(i).pyro.shape.diameter=nabstr(text,46,i,'mm')         
                ac.assembly.chambers(i).pyro.shape.dome_height=nabstr(text,48,i,'mm') 
                ac.assembly.chambers(i).pyro.amount=msprintf("%.6f",pyromass)+' g'                  
            case(2) then //sphere (don't need to worry about the number of spheres, aipp will calc that)
                ac.assembly.chambers(i).pyro.shape.geometry="sphere"           
                temp=nabval(text,49,i); // just get the value
                temp=strcat([string(temp/2), " mm"]) // convert diameter to radius
                ac.assembly.chambers(i).pyro.shape.radius=temp;
                ac.assembly.chambers(i).pyro.amount=msprintf("%.6f",pyromass)+' g'       
            case(3) then  // wafer
                // now calculate the nearest integer value of wafers
                id=nabval(text,45,i)
                od=nabval(text,46,i)
                h=nabval(text,47,i)
                disp('id od h ',[id, od, h])
                vol=pi*(od^2-id^2)*h/4;
                disp('values are',[pyromass, vol, rho])
                nwafers=round(1000*(pyromass/(vol*rho))) // 1000 is units correction                           
                nwafersi=round(nwafers)               
                disp(' current density is in gm/cm^3              ',rho)
                perfect_density=rho*nwafersi/nwafers
                disp(' for perfect Wafer density, alter it to ',perfect_density)                   
                ac.assembly.chambers(i).pyro.shape.geometry="wafer"       
                ac.assembly.chambers(i).pyro.shape.outer_radius=strcat([string(od/2),' mm'])
                ac.assembly.chambers(i).pyro.shape.inner_radius=strcat([string(id/2),' mm'])        
                ac.assembly.chambers(i).pyro.shape.height=nabstr(text,47,i,'mm')     
                ac.assembly.chambers(i).pyro.amount=nwafersi;
                ac.assembly.chambers(i).pyro.density=(msprintf("%.6f",perfect_density)+' g/cm^3')
            case(7) then // grain               
                id=nabval(text,45,i)     
                od=nabval(text,47,i)     
                fd=nabval(text,46,i)     
                finthick=nabval(text,48,i)
                height=10.0  // just a place holder since the current deck files don't contain this information
                nfins=nabval(text,49,i)    
                theta=pi/nfins
                A1=.5*theta*((od/2)^2-(id/2)^2)                
                //            beta=asin((finthick/2)/(fd/2))
                yc=sqrt((od/2)^2 - (finthick/2)^2)
                A2=(fd/2-yc)*finthick/2
                gamma=asin((finthick/2)/(od/2))
                A3=(1/4)*(od/2)^2*(2*gamma-sin(2*gamma))
                area=2*nfins*(A1+A2-A3)/100.  // convert to sq cm.
                vol=pyromass/rho;
                height=10*vol/area; // compute a new length leaving density/mass alone
                disp('the grain length was computed as ',height*1000)

                /*            ngrains=pyromass/(vol*rho) // scaled
                mprintf('ngrains as real is %.6f \n',ngrains)
                ngrainsi=round(ngrains)
                mprintf('rounded, it is     %.0f \n',ngrainsi)  */

                ngrainsi=1 ; // force to 1 grain temporarily

                ac.assembly.chambers(i).pyro.shape.geometry="grain"
                ac.assembly.chambers(i).pyro.shape.inner_diameter=nabstr(text,45,i,'mm')     
                ac.assembly.chambers(i).pyro.shape.outer_diameter=nabstr(text,47,i,'mm')     
                ac.assembly.chambers(i).pyro.shape.fin_diameter=nabstr(text,46,i,'mm')     
                ac.assembly.chambers(i).pyro.shape.fin_thickness=nabstr(text,48,i,'mm')        
                
                lenstr=msprintf('%.5f mm',height)
                ac.assembly.chambers(i).pyro.shape.cylinder_height=lenstr;
                ac.assembly.chambers(i).pyro.shape.num_fins=nabval(text,49,i)
                ac.assembly.chambers(i).pyro.amount=ngrainsi;
                // ac.assembly.chambers(i).pyro.density=(msprintf("%.6f",perfect_density)+' g/cm^3')
            end
        end
    end
    //If there is no pyro in a chamber the structure defaults to pyro = []
    //This loop removes and empty pyro children for each chamber so no 
    //erroneous output is written to the JSON file
    for i = 1:1:max(size(ac.assembly.chambers))
        try
            if ac.assembly.chambers(i).pyro == []
               ac.assembly.chambers(i).pyro=null()  
            end            
            if ac.assembly.chambers(i).filter == []
               ac.assembly.chambers(i).filter = null()
            end            
        catch
            mprintf(' %s\n',' no pyros' )
        end
    end
endfunction


function [ac]=GetOrificeDetails1(ac, text)
    ncham=nabval(text,2,1);
    orificecount=0;
    num_orifice_row=30
    diameter_row=27
    cd_row=33
    connection_row=12
    vf_row=6
    burst_row=36
    
    for i=1: ncham
        norificegroups=3
        for j=1:norificegroups
            norifices=nabval(text,num_orifice_row+(j-1),i);
            ord=nabval(text,diameter_row+(j-1),i);
            deq=sqrt(norifices)*ord

            if(deq <> 0) then // there is an orifice here...
                orificecount=orificecount+1                
                ac.assembly.orifices(1,orificecount).diameter=strcat([string(deq),' mm']) ; // equivalent diameter assuming 1 orifice for the group
                ac.assembly.orifices(1,orificecount).open=%f
                ac.assembly.orifices(1,orificecount).discharge_coefficient=nabval(text,cd_row+(j-1),i);
                ac.assembly.orifices(1,orificecount).from=i
                ac.assembly.orifices(1,orificecount).to=nabval(text,connection_row,i);
                ac.assembly.orifices(1,orificecount).viscous_flow_factor=nabval(text,vf_row,1);

                open_pressure=nabval(text,burst_row+(j-1),i)
                if(open_pressure  <> 1000) then
                    ac.assembly.orifices(1,orificecount).opens_at=string(open_pressure)+'MPa'
                else
                    ac.assembly.orifices(1,orificecount).opens_at=nabstr(text,burst_row+(j-1)+3,i,'s')
                end
            end            
        end
    end
    // things that can be done outside of the loop through chambers
    //The JSON file from archaeologic reads in the chambers as a list object. Manually
    //creating the structure above creates a [nx1] structure object. This section 
    //forces the creation of a list to match the archaeologic syntax 
    for i=1:1:ncham
        if i==1
            str = "list(ac.assembly.chambers(1)" 
        else
            str = strcat([str,",","ac.assembly.chambers(",string(i),")"])
            //       disp(str)
        end
    end
    execstr(strcat(["ac.assembly.chambers = ",str,")"]))
    for i=1:1:orificecount
        if i==1
            str = "list(ac.assembly.orifices(1)" 
        else
            str = strcat([str,",","ac.assembly.orifices(",string(i),")"])
            //       disp(str)
        end
    end
    execstr(strcat(["ac.assembly.orifices = ",str,")"]))
endfunction

function [ac]=GetHeatTransferDetails1(ac, text, ncham)  
    //  from AIPP:  REAL(DP) :: rhosteel = 7833.d0, cpsteel=510.d0, ksteel=45.0d0
    default_density_string="7833.0 kg/m^3"
    default_conductivity_string="45.0 W/(m K)"
    default_specific_heat_string="510.0 J/(kg K)"
    default_heat_transfer_coefficient = "10 W/(m^2 K)"

    for i=1:ncham
        ac.assembly.walls(i).area=ComputeAreaFromVolume(ac.assembly.chambers(i).volume)
        ac.assembly.walls(i).thickness=nab(text,'wall_thickness_mass', i, 'mm')
        ac.assembly.walls(i).density=default_density_string
        ac.assembly.walls(i).thermal_conductivity=default_conductivity_string
        ac.assembly.walls(i).specific_heat=default_specific_heat_string
        ac.assembly.walls(i).temperature=nab(text,'conditioning_temperature',1,'K')
        ac.assembly.walls(i).right_connection.type='CONSTANT_HEAT'
        ac.assembly.walls(i).right_connection.heat='0 W'
        ac.assembly.walls(i).left_connection.type='CONSTANT_COEFFICIENT'
        ac.assembly.walls(i).left_connection.chamber_index=i//string(i)
        ac.assembly.walls(i).left_connection.heat_transfer_coefficient=...
        nab(text, 'wall_heatloss_factor', i, 'W/(m^2 K)');
        
        first = part( ac.assembly.walls(i).left_connection.heat_transfer_coefficient,1)

        if first == "+" | first =="-"
            ac.assembly.walls(i).left_connection.heat_transfer_coefficient ...
            = part(ac.assembly.walls(i).left_connection.heat_transfer_coefficient,2:$)
        end
        
        ac.assembly.walls(ncham).temperature='294.15 K' // override the conditioning temp for the tank wall
        
        if i ==1 
            str = "ac.assembly.walls = list(ac.assembly.walls(1)"
        else
            str = str + "ac.assembly.walls(" + string(i)...
        + ")"
        end
    
        if i ~= ncham
             str = str + "," 
        else
            str = str + ")"
        end
    end
    
    execstr(str)
        
endfunction

function [ac]=GetFilterDetails1(ac, text, ncham)  
    //  from AIPP:  REAL(DP) :: rhosteel = 7833.d0, cpsteel=510.d0, ksteel=45.0d0
    default_density_string="7833.0 kg/m^3"
    default_specific_heat_string="510.0 J/(kg K)"

    for i=1:ncham-1 // no filters in tank


        FilterCode=nab(text,'heat_loss_method',1,'') // 1st string
        FC=stripblanks(FilterCode)
        if(FC =='percentage') then
            ac.assembly.chambers(i).filter.density=default_density_string
            ac.assembly.chambers(i).filter.specific_heat=default_specific_heat_string
            ac.assembly.chambers(i).filter.mass=nab(text,'filter_weight',i,'g')
            ac.assembly.chambers(i).filter.method='PERCENTAGE'
            ac.assembly.chambers(i).filter.coefficient=strtod(nab(text,'pack_heatloss_percent_removed',i,''))/100.
            ac.assembly.chambers(i).filter.orifices='['+string(i)+']'
        else
            ac.assembly.chambers(i).filter.density=default_density_string
            ac.assembly.chambers(i).filter.specific_heat=default_specific_heat_string
            ac.assembly.chambers(i).filter.mass=nab(text,'filter_weight',i,'g')
            ac.assembly.chambers(i).filter.method='KNTU' // will become KNTU once Archaeologic fixes it.
            ac.assembly.chambers(i).filter.coefficient=strtod(nab(text,'kntu_value',1,''))
            ac.assembly.chambers(i).filter.orifices='['+string(i)+']'
        end
    end
endfunction

function [area]=ComputeAreaFromVolume1(vol)
    volume=strtod(tokens(vol)(1));
    unit=tokens(vol)(2)
    select unit
    case("mm^3") then
        volume=volume/1e9
    case("cm^3") then
        volume=volume/1e6
    case("L") then 
        volume=volume/1e3
    end
    pi=3.141592653
    // below, artificially scaling by 2.5 like AIPP-2.3.5 does
    area=(2.5*(4.0*pi)*((3.0*volume)/(4.0*pi))^(2.0/3.0))
    area=string(area*1e4)+' cm^2'
endfunction

function []=cls
    close(winsid())
endfunction
