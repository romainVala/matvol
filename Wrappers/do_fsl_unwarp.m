function do_fsl_unwarp(fin,phase,mag,outdir,par)

%attention c'est pour la version 4.1.8
if ~exist('par'),  par='';end

if ~isfield(par,'tediff'), par.tediff = 2.46 ; end
if ~isfield(par,'unwarpdir'), par.unwarpdir = 'y-' ; end
if ~isfield(par,'TE'), par.TE = 30 ; end
if ~isfield(par,'dwelltime'), par.dwelltime = 0.35 ; end
%if ~isfield(par,''), par.= ; end



p = fileparts(which('do_fsl_unwarp.m'));

confin = fullfile(p,'unwarp.fsf');
cmd = sprintf('cat %s',confin);
[a conf_base ] = unix(cmd);


for k=1:length(outdir)
    
    %first convert siemens phase in rad
    phase_out = fullfile(outdir{k},'phase_rad');
    
    scale=pi/4096;    
    cmd = sprintf('fslmaths %s -mul %f %s',phase{k},scale,phase_out);
    unix(cmd);
    
    phase_out = [phase_out '.nii.gz'];

    %unwarp the phase map
    cmd = sprintf('prelude -a %s -p %s -o %s',mag{k},phase_out,phase_out);
    unix(cmd);
    
    %convert in rad/s
    scale = 1/par.tediff*1000;
    cmd = sprintf('fslmaths %s -mul %f %s',phase_out,scale,phase_out);
    unix(cmd);
    
    %do the feat config and run
    confout = fullfile(outdir{k},'unwarp.fsf');
    fid = fopen(confout,'w+');
    
    fprintf(fid,'%s\n',conf_base);
    
    fprintf(fid,'set fmri(outputdir) "%s" \n',outdir{k});
    fprintf(fid,'set fmri(dwell) %f\n',par.dwelltime);
    fprintf(fid,'set fmri(te) %f \n',par.TE);
    fprintf(fid,'set fmri(unwarp_dir) %s\n',par.unwarpdir);
    fprintf(fid,'set unwarp_files(1) "%s"\n',phase_out);
    fprintf(fid,'set unwarp_files_mag(1) "%s"\n',mag{k});
    fprintf(fid,'set feat_files(1) "%s"\n',fin{k});

    %fprintf(fid,'\n',);
    fclose(fid);
    
    cmd = sprintf('feat %s',confout)
    
    unix(cmd);
    
end
