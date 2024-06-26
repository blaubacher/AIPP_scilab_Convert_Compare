// Copyright (C) 2024 - Autoliv - B. Laubacher
//
// Date of creation: Feb 7, 2024
//

function [ac]=GetTimes(text)   
    ac.time_specs.output_time_step=nab(text,'output_dt',1,'s')
    ac.time_specs.end_time=nab(text,'t1_end',1,'s')
    ac.time_specs.simulation_time_step=nab(text,'dt1',1,'s')
endfunction
    
function [ac]=GetChamberDetails(ac, text, ncham)
    specnames=['h2o','co2','n2','o2','h2','co','he','ar','n2o']
    propername=["H2O","CO2",'N2','O2','H2','CO','He','Ar','N2O']
    [junk,nspecies]=size(specnames)
    // start assembly.chambers
    for i=1:ncham
        if(i<ncham)
            ac.assembly.chambers(i).volume=nab(text,'gas_volume',i,'mm^3')
        else
            ac.assembly.chambers(i).volume=nab(text,'gas_volume',i,'L')
        end
        ac.assembly.chambers(i).temperature=nab(text,'conditioning_temperature',1,'K') // it's always the first token for all chambers
        ac.assembly.chambers(i).mass=nab(text,'gas_mass',i,'g')
        for j=1:nspecies
            strin=specnames(j)+"%"
            maybe_value=nab(text,strin,i,"")
            if(strtod(maybe_value) > 0) then
                strtoex='ac.assembly.chambers('+string(i)+').mol_fractions.'+propername(j)+'='+maybe_value
                execstr(strtoex)
            end
        end
        ac.assembly.walls(ncham).temperature='294.15 K' // override the conditioning temp for the tank wall
        ac.assembly.chambers(ncham).temperature='294.15 K'
    end 
    
    
endfunction


function [ac]=GetPyroDetails(ac, text, ncham)
    for i=1:ncham
        temp=nab(text,'pyro_file',i,'')
//        disp('temp is ',temp)
        name=(strsplit(temp,'.'))(1) // omit the .pyro file extension
        pyromass=GetNumFromDeck(text,'generant_weight',i);
//        disp('first pyromass is ',pyromass)

        if pyromass ~= 0 then
            ac.assembly.chambers(i).pyro.formulation=strsubst(name,"-","_")
            // get the actual number of the density 
            rho=GetNumFromDeck(text,'generant_density',i)
            ac.assembly.chambers(i).pyro.density=nab(text,'generant_density',i,'g/cm^3')
            ac.assembly.chambers(i).pyro.amount=msprintf("%.6f",pyromass)+' g'  
            ac.assembly.chambers(i).pyro.piles=1
            ac.assembly.chambers(i).pyro.flame_spread_time=nab(text,'flame_spread_time',i,'s')  
            ac.assembly.chambers(i).pyro.ignition_time=nab(text,'ignition_delay',i,'s')      
            ac.assembly.chambers(i).pyro.reference_burn_rate=nab(text,'ref_burn_rate',i,'mm/s')
            ac.assembly.chambers(i).pyro.burn_rate_exponent=strtod(nab(text,'burn_rate_pressure_exp_n',i,''))
            ac.assembly.chambers(i).pyro.burn_rate_temperature_sensitivity=nab(text,'burn_rate_temp_sensitivity_sigma_p',i,'1/K')                
            ac.assembly.chambers(i).pyro.amount=nab(text,'generant_weight',i,'g')        
            // now a somewehat complex process is involved to identify the proper tags for the different shapes, so this will  be a 'case' statement
            shape_code=strtod(nab(text,'gen_shape_code',i,""))
//            disp('shape_code',shape_code)
            select shape_code
            case(1) then // tablet (don't need to worry about the number of tablets, aipp will calc that)
                ac.assembly.chambers(i).pyro.shape.geometry="tablet"
                ac.assembly.chambers(i).pyro.shape.total_height=nab(text,'starID_waferID_triBL_surfAREA',i,'mm') 
                ac.assembly.chambers(i).pyro.shape.diameter=nab(text,'tabOD_waferOD_starMD_triRAD',i,'mm')         
                ac.assembly.chambers(i).pyro.shape.dome_height=nab(text,'tabTHICK_triTHICK_waferTHICK_starOD',i,'mm') 
                ac.assembly.chambers(i).pyro.amount=msprintf("%.6f",pyromass)+' g'  
                
            case(2) then //sphere (don't need to worry about the number of spheres, aipp will calc that)
                ac.assembly.chambers(i).pyro.shape.geometry="sphere"           
                temp=nab(text,'sphereOD_starNFIN',i,''); // just get the value
                temp=strcat([string(strtod(temp)/2), " mm"]) // convert diameter to radius
                ac.assembly.chambers(i).pyro.shape.radius=temp;
                ac.assembly.chambers(i).pyro.amount=msprintf("%.6f",pyromass)+' g'  
            
            case(3) then  // wafer
                // now calculate the nearest integer value of wafers
                id=GetNumFromDeck(text,'tabTHICK_triTHICK_waferTHICK_starOD',i)
                od=GetNumFromDeck(text,'tabOD_waferOD_starMD_triRAD',i)
                h=GetNumFromDeck(text,'starID_waferID_triBL_surfAREA',i)
                vol=pi*(od^2-id^2)*h/4;
                n=round(1000*(pyromass/(vol*rho))) // 1000 is units correction
//                disp('n_wafers was found to be ',n)    
                
                
                nwafers=1000*pyromass/(vol*rho) // scaled
//                disp('nwafers as real is ',nwafers)
                nwafersi=round(nwafers)
//                disp('rounded, it is  ',nwafersi)
                
                disp(' current density is in gm/cm^3              ',rho)
                perfect_density=rho*nwafersi/nwafers
                disp(' for perfect Wafer density, alter it to ',perfect_density)   
                
                ac.assembly.chambers(i).pyro.shape.geometry="wafer"       
                ac.assembly.chambers(i).pyro.shape.outer_radius=strcat([string(od/2),' mm'])
                ac.assembly.chambers(i).pyro.shape.inner_radius=strcat([string(id/2),' mm'])        
                ac.assembly.chambers(i).pyro.shape.height=nab(text,'starID_waferID_triBL_surfAREA',i,'mm')     
                ac.assembly.chambers(i).pyro.amount=n;
                ac.assembly.chambers(i).pyro.density=(msprintf("%.6f",perfect_density)+' g/cm^3')

            case(7) then // grain               
                id=GetNumFromDeck(text,'tabOD_waferOD_starMD_triRAD',i)     
                od=GetNumFromDeck(text,'sphereOD_starNFIN',i)     
                fd=GetNumFromDeck(text,'starID_waferID_triBL_surfAREA',i)     
                finthick=GetNumFromDeck(text,'tabDOME_waferNBREAK_starFINTHICK',i)
                height=10.0  // just a place holder since the current deck files don't contain this information
                nfins=GetNumFromDeck(text,'tabTHICK_triTHICK_waferTHICK_starOD',i)
    
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
               //vol=area*height/10. // convert to cu cm
               // disp('the grain end area is, in sq. cm. ' ,area)
               // disp('the grain vol is, in cc''s ',vol)
               disp('the grain lengtch was computed as ',height*1000)
                
    /*            ngrains=pyromass/(vol*rho) // scaled
                mprintf('ngrains as real is %.6f \n',ngrains)
                ngrainsi=round(ngrains)
                mprintf('rounded, it is     %.0f \n',ngrainsi)  */
                ngrainsi=1 ; // force to 1 grain temporarily
             //   mprintf(' the current density is %.6f \n',rho)
             //   perfect_density=rho*ngrainsi/ngrains
             //   mprintf(' for perfect Grain density, it was altered to %.6f \n', perfect_density)
                
                
    
                ac.assembly.chambers(i).pyro.shape.geometry="grain"
                ac.assembly.chambers(i).pyro.shape.inner_diameter=nab(text,'tabOD_waferOD_starMD_triRAD',i,'mm')     
                ac.assembly.chambers(i).pyro.shape.outer_diameter=nab(text,'sphereOD_starNFIN',i,'mm')     
                ac.assembly.chambers(i).pyro.shape.fin_diameter=nab(text,'starID_waferID_triBL_surfAREA',i,'mm')     
                ac.assembly.chambers(i).pyro.shape.fin_thickness=nab(text,'tabDOME_waferNBREAK_starFINTHICK',i,'mm')        
                ac.assembly.chambers(i).pyro.shape.cylinder_height="10 mm" // just a placeholder since the deck files don't havethis information
                
                lenstr=msprintf('%.5f mm',height)
                ac.assembly.chambers(i).pyro.shape.cylinder_height=lenstr;
                ac.assembly.chambers(i).pyro.shape.num_fins=strtod(nab(text,'tabTHICK_triTHICK_waferTHICK_starOD',i,''))
                ac.assembly.chambers(i).pyro.amount=ngrainsi;
         //     ac.assembly.chambers(i).pyro.density=(msprintf("%.6f",perfect_density)+' g/cm^3')
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


function [ac]=GetOrificeDetails(ac, text, ncham)
    orificecount=0;
    for i=1: ncham
        norificegroups=strtod(nab(text,'num_orifice_sizes',i,""))
//        disp('chamber and group number',[i,norificegroups])
        for j=1:norificegroups
            orificecount=orificecount+1 ; // incrememnt which orifice to write to JSON
            norifices=strtod(nab(text,strcat(["num_orifice",string(j)]),i,'mm'));
            ord=strtod(nab(text,strcat(["diameter",string(j)]),i,'mm'));
//            disp('ord is ', ord)
            if(isnan(ord)) then
//                disp('in the breakloop')
                break
            end

            deq=sqrt(norifices)*ord
            ac.assembly.orifices(1,orificecount).diameter=strcat([string(deq),' mm']) ; // equivalent diameter assuming 1 orifice for the group
            ac.assembly.orifices(1,orificecount).open=%f
            ac.assembly.orifices(1,orificecount).discharge_coefficient=strtod(nab(text,strcat(["cd_value",string(j)]),i,''));
            ac.assembly.orifices(1,orificecount).from=i
            ac.assembly.orifices(1,orificecount).to=strtod(nab(text,strcat(["chamber_connection"]),i,''));
            ac.assembly.orifices(1,orificecount).viscous_flow_factor=strtod(nab(text,"visc_flow",1,''));

            ocodestr='orifice_type_code'+string(j)
            ocode=strtod(nab(text,ocodestr,i,'thistringdoesnotmatter'))
            select ocode
            case 2 then
                ac.assembly.orifices(1,orificecount).opens_at=nab(text,strcat(["burst_pressure",string(j)]),i,'MPa')
            case 4 then
                ac.assembly.orifices(1,orificecount).opens_at=nab(text,strcat(["burst_time",string(j)]),i,'s')
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

function [ac]=GetHeatTransferDetails(ac, text, ncham)  
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

function [ac]=GetFilterDetails(ac, text, ncham)  
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

function [area]=ComputeAreaFromVolume(vol)
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
