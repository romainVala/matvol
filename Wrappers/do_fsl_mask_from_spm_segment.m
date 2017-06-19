function [fo job] = do_fsl_mask_from_spm_segment(fanat,par)

if ~exist('par'),par ='';end

defpar.fsl_output_format = 'NIFTI_GZ';
defpar.seuil = 0;
defpar.prefix = '';
defpar.bin = 1;
defpar.sge=0;
defpar.jobname = 'fsl_mask';
defpar.walltime = '00:10:00';

par = complet_struct(par,defpar);

anat=get_parent_path(fanat);

ff=get_subdir_regex_files(anat,'^c[123]',3);
fo=addsuffixtofilenames(anat,'/mask_brain');

dosge=0;
if par.sge, par.sge=-1;dosge=1;end

[fm par.jobappend] = do_fsl_add(ff,fo,par);
par

%fm=get_subdir_regex_files(anat,'^mask_brain.nii',1); 

par.type = {'erode','dilate','dilate','erode'};

[fm2 par.jobappend]=mask_erode(fm,par);
do_delete(fm,0)

if dosge, par.sge=1;end

fo = addprefixtofilenames(fanat,'brain_');
job = do_fsl_mult(concat_cell(fm2,fanat),fo,par);

