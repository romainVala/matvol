function cout = get_val_from_mrtrix_track(f_trk,par,cout)


if ~exist('cout')
    cout = struct;
end

if ~exist('par'),  par='';end
defpar.wm='';
defpar.wm_name='';

par=complet_struct(par,defpar);



%cout = count_mrtrix_track(f_trk,cout);

f_prob = addsuffixtofilenames(f_trk,'_prob');
f_prob = change_file_extension(f_prob,'.nii');


for nb_trk = 1:size(f_trk{1},1)
    for nbsuj = 1:length(f_prob)
        fsuj_trk{nb_trk}{nbsuj} = deblank(f_trk{nbsuj}(nb_trk,:));
    end
end

for nb_trk = 1:size(f_trk{1},1)
    
    [pp fname] = get_parent_path(f_prob(1));   
    fname = cellstr(char(fname));
    fname = change_file_extension(fname,'');
    
    cout = count_mrtrix_track(fsuj_trk{nb_trk},cout);
    
    for nbsuj = 1:length(f_prob)
        fcon = deblank(f_prob{nbsuj}(nb_trk,:));
        
        if ~exist(fcon,'file')
            error('compute the _prob file first %s doeas not exist\n',fcon)
        end
        
        [v m s p98] = do_fsl_getvol(fcon);
        
        field_name = ['Vol_' fname{nb_trk}];
        cout = setfield(cout,field_name,{nbsuj},v(1,2));
        
        field_name = ['Mean_' fname{nb_trk}];
        cout = setfield(cout,field_name,{nbsuj},m);
        %cm
        
        [v m ] = do_fsl_getvol(fcon,p98*0.1);
 

        field_name = ['Vol_10p_' fname{nb_trk}];
        cout = setfield(cout,field_name,{nbsuj},v(1,2));
        
        field_name = ['Mean_10p_' fname{nb_trk}];
        cout = setfield(cout,field_name,{nbsuj},m);
        
        if ~isempty(par.wm)
            wmimages = cellstr(par.wm{nbsuj});
            for nbwm =1:length(wmimages)
                y = get_wheited_mean(wmimages(1),fcon);
                yp = get_wheited_mean(wmimages(1),fcon,p98);
                
                field_name = [par.wm_name{nbwm} '_' fname{nb_trk}];
                cout = setfield(cout,field_name,{nbsuj},y); 
                field_name = [par.wm_name{nbwm} '_10p_' fname{nb_trk}];
                cout = setfield(cout,field_name,{nbsuj},yp); 
            end
        end
            
    end
end
