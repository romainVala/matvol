function do_fsl_apply_fieldmap_from_topup(fin,topupdir,par,jobappend)

% % % resting state echo spacing 0.51   EPI fonc : tot echo spacing 0.0196 
% % % fugue -i toto.nii.gz --dwell=0.00055 --loadfmap=rfsl_fieldmap_rads.nii.gz  -u uwtoto --unwarpdir=y -s 1 
% % rosso@tac /servernas/images4/rosso/PAS_AVC4D/2015_03_23_PAS_AVC_Patient003/S04_rsfMRI > 
% % toto = foncmean rest
% % fslmath field_4D_B0_topup.nii.gz -mul 6.28 -mul 0.005 -div totreadout_time (0.0025)
% % fslroi ../topup/4D_orig.nii.gz  foncmean 0 1
% % flirt -in foncmean.nii.gz  -ref toto.nii.gz  -omat fonctorest.txt -o rfoncmean
% % flirt -in ../topup/my_fieldmap_rads.nii.gz -ref toto.nii.gz -init fonctorest.txt -applyxfm -o rrrfsl_fieldmap_rads.nii.gz 
% % fugue -i toto.nii.gz --dwell=0.00055 --loadfmap=rrrfsl_fieldmap_rads.nii.gz  -u uwtoto --unwarpdir=y -s 1

if ~exist('par'),par ='';end
if ~exist('jobappend','var'), jobappend ='';end


defpar.outprefix = 'ut';
defpar.sge=1;
defpar.topup_readouttime = 0.005 ;
defpar.epi_dwelltime = 0;
defpar.epi_phase_dir = 'y';

defpar.fsl_output_format = 'NIFTI';

par = complet_struct(par,defpar);

for nbs = 1:length(fin)
    
    tpd = topupdir{nbs};
    ffonc = cellstr(fin{nbs});
    
    [dirfonc pp] = get_parent_path(ffonc(1));
    
    fB0 = get_subdir_regex_files(tpd,'^4D_orig.nii.gz$')
    
    cmd = sprintf('cd %s\n export FSLOUTPUTTYPE=NIFTI \n fslroi %s firstmean 0 1',tpd,fB0{1});
    unix(cmd);
    
    ffield = get_subdir_regex_files(tpd,'^field_4D_orig_topup.nii') ; 
    fo = addprefixtofilenames(ffield,'rad_s_');
    
    cmd = sprintf('cd %s\n export FSLOUTPUTTYPE=NIFTI \n fslmaths %s  -mul 6.28 -mul 0.05 -div %f %s ',...
        tpd,ffield{1},par.topup_readouttime,fo{1});
    unix(cmd);
    
    f1 = get_subdir_regex_files(tpd,'firstmean',1);
    ffield = get_subdir_regex_files(tpd,'^rad_s_',1);
    
    hdr_copy_nifti_header(ffield,f1,0)
    
    %coregister
    
    cmd =sprintf('cd %s\n flirt -in %s -ref %s -omat topup_to_here.txt -o rfsl_first_topup',dirfonc{1},f1{1},ffonc{1});
    unix(cmd)
    
    cmd = sprintf('cd %s\n flirt -in %s -ref %s -init topup_to_here.txt -applyxfm -o fieldmap_rads',...
        dirfonc{1},ffield{1},ffonc{1});
    unix(cmd)
    
    %apply fieldmap
    fo = addprefixtofilenames(ffonc,par.outprefix);
    
    for k=1:length(ffonc)
        cmd =  sprintf('cd %s\n  export FSLOUTPUTTYPE=NIFTI; fugue -i %s --dwell=%s --loadfmap=fieldmap_rads.nii.gz -u %s --unwarpdir=%s -s 2'...
            ,dirfonc{1},ffonc{k},par.epi_dwelltime,fo{k},par.epi_phase_dir);
        unix(cmd);
    end
    
end
