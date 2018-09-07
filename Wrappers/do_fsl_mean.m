function [ out, job ]= do_fsl_mean(fin,outname,par,jobappend)

if ~exist('par'),par ='';end
if ~exist('jobappend','var'), jobappend ='';end


defpar.sge=0;
defpar.fsl_output_format = 'NIFTI_GZ'; %ANALYZE, NIFTI, NIFTI_PAIR, NIFTI_GZ
defpar.jobname='fslmean';
defpar.skip = 1;
%defpar
job ='';

par = complet_struct(par,defpar);

if iscell(outname)
    if length(fin)~=length(outname)
        error('the 2 cell input must have the same lenght')
    end
    
    
    for k=1:length(outname)
        do_fsl_mean(fin(k),outname{k},par);
    end
    return
end

%remove extention
% [pp ff] = fileparts(outname);
% outname=fullfile(pp,ff);
outname = change_file_extension(outname,'');

ext='';
switch par.fsl_output_format
    case 'NIFTI_GZ'
        ext = '.nii.gz';
    case 'NIFTI'
        ext = '.nii';
    case ('NIFTI_PAIR')
        ext = '.img';
end
out = [outname ext];

if par.skip && exist(out,'file')
    fprintf('skipping fsl mean because %s exist\n',out)
    return
end
    
fin = cellstr(char(fin));

[pp ffo]=get_parent_path(fin);

cmd = sprintf('export FSLOUTPUTTYPE=%s;\ncd %s;\nfslmaths %s -nan -thr 0',par.fsl_output_format,pp{1},fin{1});
% cmd = sprintf('cur_dir=pwd;\nexport FSLOUTPUTTYPE=%s;\ncd %s;\nfslmaths %s -nan -thr 0;\n cd $cur_dir',par.fsl_output_format,pp{1},fo{1});
if length(fin)==1 %this is a 4D volume
    cmd = sprintf('%s -Tmean %s;\n',cmd,outname);
else
    
    for k=2:length(fin)
        cmd = sprintf('%s -add  %s -nan ',cmd,fin{k});
    end
    
    cmd = sprintf('%s %s',cmd,outname);
    
    cmd = sprintf('%s\nfslmaths %s -div  %d %s -odt float',cmd,outname,length(fin),outname);
end


job{1}=cmd;


job = do_cmd_sge(job,par,jobappend);

end % function

