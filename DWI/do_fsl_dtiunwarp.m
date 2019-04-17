function [job fout] = do_fsl_dtiunwarp(f4D,fmdir,par,jobappend)

if ~exist('par'),par ='';end
if ~exist('jobappend','var'), jobappend ='';end

defpar.sujname='';
defpar.bvecs = '^bvecs$';
defpar.bvals = '^bvals$';
defpar.mask = 'nodif_brain_mask';
defpar.tediff = 2.46; defpar.esp = 0;
defpar.te = 0;       defpar.unwarpdir = 'y';
defpar.unwarp_outvol_suffix = '_unwarp';
%
defpar.software = 'fsl'; %to set the path
defpar.software_version = 5; % 4 or 5 : fsl version
defpar.jobname = 'dti_unwarp';
defpar.prepare_phase = 'siemens'; %bruker
defpar.phase_file_regex = '^s';
defpar.nocoregFM2dti = 0;
defpar.dti_mask = 1;
defpar.find_param_from_dicom=0;
defpar.find_param_from_json=1;
defpar.dicfile = '';
%see also default params from do_cmd_sge
defpar.sge=0;

par = complet_struct(par,defpar);

for nbs = 1:length(f4D)
    if par.find_param_from_dicom
        
        if ~isempty(par.dicfile)
            [par.esp par.unwarpdir totes par.te] = get_EPI_readout_time(par.dicfile{nbs});
        else
            
            dti_dir = get_parent_path(f4D(nbs));
            dicom_file=get_subdir_regex_files(dti_dir,'dicom_info.mat',1);
            dicom_csv=get_subdir_regex_files(dti_dir,'dicom_info.csv',1);
            l = load(dicom_file{1});
            
            [par.esp par.unwarpdir totes par.te] = get_EPI_readout_time(l.hh,dicom_csv);
            
        end
        
        warning('delta TE is supposed to be 2.46')
        par.tediff = 2.46;
    end
    if par.find_param_from_json
        [par.esp par.unwarpdir par.te totes] = get_EPI_param_from_json(f4D(nbs));
        if par.te>1000, par.te=par.te/1000;end
        par.tediff = 2.46;

    end
    
    switch par.prepare_phase
        case 'siemens'
            
            try
                mag = get_subdir_regex_images(fmdir{nbs}{1},par.phase_file_regex,2);
            catch
                mag = get_subdir_regex_images(fmdir{nbs}{1},par.phase_file_regex,3);
            end
            
            nmag = change_file_extension(mag{1}(1,:),'');
            nmag = [nmag '_brain'];
            
            phase =  get_subdir_regex_images(fmdir{nbs}{2},par.phase_file_regex,1);
            nphase = addsuffixtofilenames(fmdir{nbs}{1},'/phase_rad');

            if exist([nphase,'.nii.gz'])
                fprintf('skinping intial phase preparation ,already done\n');
                cmd='';
            else
                
                cmd = sprintf('bet %s %s\n',mag{1}(1,:), nmag);
                
                cmd = sprintf('%s\n fsl_prepare_fieldmap SIEMENS %s %s %s %f\n',cmd,phase{1},nmag,nphase,par.tediff);
            end
            
        case 'bruker'
            ff = get_subdir_regex_files(fmdir(nbs),par.phase_file_regex);
            phase = ff{1}(1,:);
            if size(ff{1},1)==2
                mag = {ff{1}(2,:)};
            else
                fprintf('no magnitude found, taking the phase diff as mag\n')
                mag = {phase};
            end
            
            nphase = addsuffixtofilenames(fmdir{nbs},'/phase_rad');
            cmd = sprintf('fslmaths %s -mul %f %s;\n',phase,2*pi,nphase);
    end
    
    
    invol = change_file_extension(f4D{nbs},'');
    
    unwarp_outvol = [invol par.unwarp_outvol_suffix];
    fout{nbs} = unwarp_outvol;
    
    %cmd = sprintf('/usr/cenir/bincenir/epidewarp.rrr.fsl --mag %s --dph %s --epi %s.nii.gz --tediff %f --esp %f --unwarpdir %s --vsm voxel_shift_map --epidw %s \n',mag,phase,outvolname,par.tediff,par.esp,par.unwarpdir,par.unwarp_outvol);
    p  = addsuffixtofilenames(get_parent_path(f4D(nbs)),'/unwarp');
    
    if exist(char(p))
        rmdir(char(p),'s');
    end
    
    
    cmd = sprintf('%s dti_preprocess -k %s -t %f -e %d -f %s -m %s -d %s -u %s',...
        cmd,invol,par.esp,par.te,nphase,mag{1}(1,:),p{1},par.unwarpdir);
    
    if par.nocoregFM2dti
        cmd = sprintf('%s -n',cmd);
    end
    
    if par.dti_mask == 0
        cmd = sprintf('%s -U',cmd);
    end
    
    
    cmd = sprintf('%s\n cd %s ;\napplywarp -i %s -o %s -r %s -w dti_preprocess/ED_UD_warp --abs\n',cmd,p{1} ,invol,unwarp_outvol,invol);
    
    job{nbs} = cmd;

end

job = do_cmd_sge(job,par,jobappend);

