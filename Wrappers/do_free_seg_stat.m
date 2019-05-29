function job = do_free_seg_stat(src,ref,par)

if ~exist('par'),par ='';end

defpar.prefix = 'free_stat_';
defpar.sge = 0;
defpar.jobname='free_sge_stat';
defpar.mult = 1;
defpar.empty = 1;
defpar.robust = 0;
defpar.seg_erode=0;

par = complet_struct(par,defpar);

fo = addprefixtofilenames(src,par.prefix);
fo = change_file_extension(fo,'.txt');
nbj=1;

[a b]=unix('which freesurfer6') ;

cmd0 = sprintf('source %s \n',b);
%cmd0 = sprintf('source /export/data/opt/CENIR/bin/freesurfer5')
cmd0 = sprintf('%s \n mri_segstats --ctab $FREESURFER_HOME/FreeSurferColorLUT.txt ',cmd0);
if par.empty
    cmd0 = sprintf('%s --empty ',cmd0);
end

if par.robust
    cmd0 = sprintf('%s --robust ',cmd0);
end

if par.seg_erode
    cmd0 = sprintf('%s --seg-erode %d ',cmd0,par.seg_erode);
end

nbval = size(src{1},1);
if (nbval>1 & length(par.mult)==1)
    par.mult = repmat(par.mult,[1 nbval]);
end


for k=1:length(ref)
    ff = cellstr(src{k});
    ffo = cellstr(fo{k});
        
    for kk=1:length(ff)
%mri_segstats --seg aparc.a2009s+aseg.mgz --ctab $FREESURFER_HOME/FreeSurferColorLUT.txt 
%--i ranat_mean_fonc.nii.gz --sum ttt.stats

        if par.mult(kk) ~= 1
            cmd = sprintf('%s --mul %f ',cmd0,par.mult(kk));
        else 
            cmd = cmd0;
        end
        
        cmd = sprintf('%s   --seg %s  --i %s --sum %s \n',...
            cmd,ref{k},ff{kk},ffo{kk});
        job{nbj} = cmd;
        nbj=nbj+1;
    end
    
end

do_cmd_sge(job,par);

% mri_segstats 
% --seg ./anat3D/mri/wmparc.mgz
% --ctab $FREESURFER_HOME/FreeSurferColorLUT.txt 
% --i DWI/rfree_4D_dtieddycor_FA.nii.gz
% --sum fa2.csv  
% --surf-ctx-vol --surf-wm-vol --subject Pa_Dokje_IRM_V1 
% --snr --etiv
%	
% --seg-erode Nerodes Erode segmentation boundaries by Nerodes.
% 
% --robust percent
% 		compute stats after excluding percent from high and low values (volume reported is still full volume).
% 
% 	--mul val
% 		multiply input by val
% 
% 	--empty
% 		Report on segmentations listed in the color table even if they
% 		are not found in the segmentation volume.
% 
% 	--id segid <segid2 ...>
% 		Specify numeric segmentation ids. Multiple ids can be 
% 		specified with multiple IDs after a single --id or with 
% 		multiple --id invocations. SPECIFYING SEGMENTATION IDS.
% 
