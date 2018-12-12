function [fo job] = do_fsl_mask_from_spm_segment(fanat,par)

if ~exist('par'),par ='';end

defpar.fsl_output_format = 'NIFTI_GZ';
defpar.seuil = 0;
defpar.prefix = '';
defpar.bin = 1;
defpar.sge=0;
defpar.jobname = 'fsl_mask';
defpar.walltime = '00:10:00';
defpar.brain_masked = 1;
defpar.head_mask = 1;

par = complet_struct(par,defpar);

anat=get_parent_path(fanat);

ff=get_subdir_regex_files(anat,'^[cp][123].*nii',3);
fo=addsuffixtofilenames(anat,'/mask_brain');

dosge=par.sge;
if par.sge, par.sge=-1;dosge=1;end

[fm, par.jobappend] = do_fsl_add(ff,fo,par);
[fm, par.jobappend] = do_fsl_fill(fm,par);

if par.head_mask
    ff=get_subdir_regex_files(anat,'^[cp][12345].*nii');
    if size(ff{1},1)==5
        foh=addsuffixtofilenames(anat,'/mask_head');
        [foh, par.jobappend] = do_fsl_add(ff,foh,par); par.prefix='fill_'
        [foh, par.jobappend] = do_fsl_fill(foh,par);
    end
    
end

%fm=get_subdir_regex_files(anat,'^mask_brain.nii',1); 

par.type = {'erode','dilate','dilate','erode'};

[fm2 par.jobappend]=mask_erode(fm,par);
if par.sge
    for k=1:length(fm)
        par.jobappend{k} = sprintf('%s\n rm -f %s\n',par.jobappend{k},fm{k});
    end
else
    do_delete(fm,0)
end

if dosge, par.sge=1;end

if par.brain_masked
    
    fo = addprefixtofilenames(fanat,'brain_');
    [~,job] = do_fsl_mult(concat_cell(fm2,fanat),fo,par);

else
    job = par.jobappend;
    par = rmfield(par,'jobappend');
    job = do_cmd_sge(job,par);
end

