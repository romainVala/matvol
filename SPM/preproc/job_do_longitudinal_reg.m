function  jobs = job_do_longitudinal_reg(img,timeline,index_grouping,par)
%
% INPUT : img can be 'char' of volume(file), single-level 'cellstr' of volume(file), '@volume' array
%
% for spm12 segment, if img{nbsuj} has several line then it is a multichannel
%
%


%% Check input arguments

if ~exist('par', 'var')
    par='';
end

if nargin < 1
    help(mfilename)
    error('[%s]: not enough input arguments - image list is required',mfilename)
end

obj = 0;
if isa(img,'volume')
    obj = 1;
    in_obj  = img;
elseif ischar(img) || iscellstr(img)
    % Ensure the inputs are cellstrings, to avoid dimensions problems
    img = cellstr(img)';
else
    error('[%s]: wrong input format (cellstr, char, @volume)', mfilename)
end


%% defpar

defpar.cat12 = 0 ; % if non 0 it will perform the cat12 longitudinal registration
defpar.auto_add_obj = 1;

defpar.run     = 1;
defpar.display = 0;
defpar.redo    = 0;
defpar.sge     = 0;

defpar.jobname  = 'spm_longitudinal';
defpar.walltime = '02:00:00';

par = complet_struct(par,defpar);

defpar.matlab_opt = ' -nodesktop ';


par = complet_struct(par,defpar);

% Security
if par.sge
    par.auto_add_obj = 0;
end


%% Prepare job generation

% unzip volumes if required
if obj
    in_obj.unzip(par);
    img = in_obj.toJob;
else
    if ~iscell(img)
        img = cellstr(img);
    end
    img = unzip_volume(img);
end


%% Prepare job

skip=[];
tot_number_suj = max(index_grouping);

for nbsuj = 1:tot_number_suj
    ii = find(index_grouping == nbsuj);
    if par.cat12
        jobs{nbsuj}.spm.tools.cat.long.datalong.subjects = { img(ii) }';
        jobs{nbsuj}.spm.tools.cat.long.longmodel = 1;
        jobs{nbsuj}.spm.tools.cat.long.enablepriors = 1;
        jobs{nbsuj}.spm.tools.cat.long.bstr = 0;
        jobs{nbsuj}.spm.tools.cat.long.nproc = 24;
        jobs{nbsuj}.spm.tools.cat.long.opts.tpm = {'/network/lustre/iss01/cenir/software/irm/spm12/tpm/TPM.nii'};
        jobs{nbsuj}.spm.tools.cat.long.opts.affreg = 'mni';
        jobs{nbsuj}.spm.tools.cat.long.opts.ngaus = [1 1 2 3 4 2];
        jobs{nbsuj}.spm.tools.cat.long.opts.warpreg = [0 0.001 0.5 0.05 0.2];
        jobs{nbsuj}.spm.tools.cat.long.opts.bias.biasstr = 0.5;
        jobs{nbsuj}.spm.tools.cat.long.opts.acc.accstr = 0.5;
        jobs{nbsuj}.spm.tools.cat.long.opts.redspmres = 0;
        jobs{nbsuj}.spm.tools.cat.long.extopts.segmentation.restypes.optimal = [1 0.3];
        jobs{nbsuj}.spm.tools.cat.long.extopts.segmentation.setCOM = 1;
        jobs{nbsuj}.spm.tools.cat.long.extopts.segmentation.APP = 1070;
        jobs{nbsuj}.spm.tools.cat.long.extopts.segmentation.affmod = 0;
        jobs{nbsuj}.spm.tools.cat.long.extopts.segmentation.NCstr = -Inf;
        jobs{nbsuj}.spm.tools.cat.long.extopts.segmentation.spm_kamap = 0;
        jobs{nbsuj}.spm.tools.cat.long.extopts.segmentation.LASstr = 0.5;
        jobs{nbsuj}.spm.tools.cat.long.extopts.segmentation.LASmyostr = 0;
        jobs{nbsuj}.spm.tools.cat.long.extopts.segmentation.gcutstr = 2;
        jobs{nbsuj}.spm.tools.cat.long.extopts.segmentation.cleanupstr = 0.5;
        jobs{nbsuj}.spm.tools.cat.long.extopts.segmentation.BVCstr = 0.5;
        jobs{nbsuj}.spm.tools.cat.long.extopts.segmentation.WMHC = 2;
        jobs{nbsuj}.spm.tools.cat.long.extopts.segmentation.SLC = 0;
        jobs{nbsuj}.spm.tools.cat.long.extopts.segmentation.mrf = 1;
        jobs{nbsuj}.spm.tools.cat.long.extopts.registration.T1 = {'/network/lustre/iss01/cenir/software/irm/spm12/toolbox/cat12/templates_MNI152NLin2009cAsym/T1.nii'};
        jobs{nbsuj}.spm.tools.cat.long.extopts.registration.brainmask = {'/network/lustre/iss01/cenir/software/irm/spm12/toolbox/cat12/templates_MNI152NLin2009cAsym/brainmask.nii'};
        jobs{nbsuj}.spm.tools.cat.long.extopts.registration.cat12atlas = {'/network/lustre/iss01/cenir/software/irm/spm12/toolbox/cat12/templates_MNI152NLin2009cAsym/cat.nii'};
        jobs{nbsuj}.spm.tools.cat.long.extopts.registration.darteltpm = {'/network/lustre/iss01/cenir/software/irm/spm12/toolbox/cat12/templates_MNI152NLin2009cAsym/Template_1_Dartel.nii'};
        jobs{nbsuj}.spm.tools.cat.long.extopts.registration.shootingtpm = {'/network/lustre/iss01/cenir/software/irm/spm12/toolbox/cat12/templates_MNI152NLin2009cAsym/Template_0_GS.nii'};
        jobs{nbsuj}.spm.tools.cat.long.extopts.registration.regstr = 0.5;
        jobs{nbsuj}.spm.tools.cat.long.extopts.registration.bb = 12;
        jobs{nbsuj}.spm.tools.cat.long.extopts.registration.vox = 1.5;
        jobs{nbsuj}.spm.tools.cat.long.extopts.surface.pbtres = 0.5;
        jobs{nbsuj}.spm.tools.cat.long.extopts.surface.pbtmethod = 'pbt2x';
        jobs{nbsuj}.spm.tools.cat.long.extopts.surface.SRP = 22;
        jobs{nbsuj}.spm.tools.cat.long.extopts.surface.reduce_mesh = 1;
        jobs{nbsuj}.spm.tools.cat.long.extopts.surface.vdist = 2;
        jobs{nbsuj}.spm.tools.cat.long.extopts.surface.scale_cortex = 0.7;
        jobs{nbsuj}.spm.tools.cat.long.extopts.surface.add_parahipp = 0.1;
        jobs{nbsuj}.spm.tools.cat.long.extopts.surface.close_parahipp = 1;
        jobs{nbsuj}.spm.tools.cat.long.extopts.admin.experimental = 0;
        jobs{nbsuj}.spm.tools.cat.long.extopts.admin.new_release = 0;
        jobs{nbsuj}.spm.tools.cat.long.extopts.admin.lazy = 0;
        jobs{nbsuj}.spm.tools.cat.long.extopts.admin.ignoreErrors = 1;
        jobs{nbsuj}.spm.tools.cat.long.extopts.admin.verb = 2;
        jobs{nbsuj}.spm.tools.cat.long.extopts.admin.print = 2;
        jobs{nbsuj}.spm.tools.cat.long.output.BIDS.BIDSno = 1;
        jobs{nbsuj}.spm.tools.cat.long.output.surface = 1;
        jobs{nbsuj}.spm.tools.cat.long.ROImenu.atlases.neuromorphometrics = 1;
        jobs{nbsuj}.spm.tools.cat.long.ROImenu.atlases.lpba40 = 0;
        jobs{nbsuj}.spm.tools.cat.long.ROImenu.atlases.cobra = 1;
        jobs{nbsuj}.spm.tools.cat.long.ROImenu.atlases.hammers = 0;
        jobs{nbsuj}.spm.tools.cat.long.ROImenu.atlases.thalamus = 0;
        jobs{nbsuj}.spm.tools.cat.long.ROImenu.atlases.ibsr = 0;
        jobs{nbsuj}.spm.tools.cat.long.ROImenu.atlases.aal3 = 0;
        jobs{nbsuj}.spm.tools.cat.long.ROImenu.atlases.mori = 0;
        jobs{nbsuj}.spm.tools.cat.long.ROImenu.atlases.anatomy3 = 0;
        jobs{nbsuj}.spm.tools.cat.long.ROImenu.atlases.julichbrain = 0;
        jobs{nbsuj}.spm.tools.cat.long.ROImenu.atlases.Schaefer2018_100Parcels_17Networks_order = 0;
        jobs{nbsuj}.spm.tools.cat.long.ROImenu.atlases.Schaefer2018_200Parcels_17Networks_order = 0;
        jobs{nbsuj}.spm.tools.cat.long.ROImenu.atlases.Schaefer2018_400Parcels_17Networks_order = 0;
        jobs{nbsuj}.spm.tools.cat.long.ROImenu.atlases.Schaefer2018_600Parcels_17Networks_order = 0;
        jobs{nbsuj}.spm.tools.cat.long.ROImenu.atlases.ownatlas = {''};
        jobs{nbsuj}.spm.tools.cat.long.longTPM = 1;
        jobs{nbsuj}.spm.tools.cat.long.modulate = 1;
        jobs{nbsuj}.spm.tools.cat.long.dartel = 0;
        jobs{nbsuj}.spm.tools.cat.long.delete_temp = 1;


    else
        jobs{nbsuj}.spm.tools.longit{1}.series.vols = img(ii);
        jobs{nbsuj}.spm.tools.longit{1}.series.times = timeline(ii);
        jobs{nbsuj}.spm.tools.longit{1}.series.noise = NaN;
        jobs{nbsuj}.spm.tools.longit{1}.series.wparam = [0 0 100 25 100];
        jobs{nbsuj}.spm.tools.longit{1}.series.bparam = 1000000;
        jobs{nbsuj}.spm.tools.longit{1}.series.write_avg = 1;
        jobs{nbsuj}.spm.tools.longit{1}.series.write_jac = 0;
        jobs{nbsuj}.spm.tools.longit{1}.series.write_div = 1;
        jobs{nbsuj}.spm.tools.longit{1}.series.write_def = 0;
    end
end

[ jobs ] = job_ending_rountines( jobs, skip, par );


%% Add outputs objects

if obj && par.auto_add_obj && par.run
    fprintf('TODO OOOOUUUU');
end

end % function
