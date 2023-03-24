function jobs = job_compute_TIV(fseg,par)
% job_compute_TIV : SPM12:Util:Tissue Volume
%                or
% job_compute_TIV : CAT12:Statistical Analysis:Get TIV
%
%
%
% Input
%     fseg : file .mat generated by SPM segmentation
%            or
%          : file .xml generated by CAT12 segmentation
% Output
%     Add to file *_seg8.mat .volumes
%            or
%     generate txt file contains TIV [^tiv.*txt]
%


if ~exist('par','var')
    par='';
end


defpar.volTIV   = 1;      % 0 : save TIV & GM/WM/CSF/WMH  // 1: save only TIV (xml files)
defpar.sge      = 0;
defpar.run      = 0;
defpar.display  = 0;
defpar.jobname  ='TIV';
defpar.walltime = '06:00:00';
defpar.mem      = '8G';
par = complet_struct(par,defpar);

fseg = cellstr(fseg);



[~,namefilss] = get_parent_path(fseg,1);
extmat = unique(contains(namefilss,'.mat'));
extxml = unique(contains(namefilss,'.xml'));



if  extmat(1)
    for nbr = 1:length(fseg)
        jobs{nbr}.spm.util.tvol.matfiles = fseg(nbr);
        jobs{nbr}.spm.util.tvol.tmax     = 3;
        jobs{nbr}.spm.util.tvol.mask     = {[spm('dir') '/tpm/mask_ICV.nii,1']};
        jobs{nbr}.spm.util.tvol.outf     = '';
    end
elseif extxml(1)
    ftiv = change_file_extension(fseg,'.txt');
    ftiv = addprefixtofilenames(ftiv,'tiv_');
    for nbr = 1:length(fseg)
        jobs{nbr}.spm.tools.cat.tools.calcvol.data_xml     = fseg(nbr);
        jobs{nbr}.spm.tools.cat.tools.calcvol.calcvol_TIV  = par.volTIV;
        jobs{nbr}.spm.tools.cat.tools.calcvol.calcvol_name = ftiv{nbr};
    end
else
    
    error('Unexpected files extension');
end

job_ending_rountines( jobs, [], par );


end

