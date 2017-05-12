function job = do_free_seg_stat(src,ref,par)

if ~exist('par'),par ='';end

defpar.prefix = 'free_stat_';
defpar.sge = 0;
defpar.jobname='free_sge_stat';

par = complet_struct(par,defpar);

fo = addprefixtofilenames(src,par.prefix);
fo = change_file_extension(fo,'.txt');
nbj=1;

[a b]=unix('which freesurfer5') ;

cmd0 = sprintf('source %s \n',b);
cmd0 = sprintf('source /export/data/opt/CENIR/bin/freesurfer5')

for k=1:length(ref)
    ff = cellstr(src{k});
    ffo = cellstr(fo{k});
    
    for kk=1:length(ff)
%mri_segstats --seg aparc.a2009s+aseg.mgz --ctab $FREESURFER_HOME/FreeSurferColorLUT.txt 
%--i ranat_mean_fonc.nii.gz --sum ttt.stats

        cmd = sprintf('%s\nmri_segstats --seg %s --ctab $FREESURFER_HOME/FreeSurferColorLUT.txt --i %s --sum %s \n',...
            cmd0,ref{k},ff{kk},ffo{kk});
        job{nbj} = cmd;
        nbj=nbj+1;
    end
    
end

do_cmd_sge(job,par);

