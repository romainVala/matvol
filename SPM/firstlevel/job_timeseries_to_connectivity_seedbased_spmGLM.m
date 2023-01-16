function job_timeseries_to_connectivity_seedbased_spmGLM(TS_struct, par)
%job_timeseries_to_connectivity_seedbased_spmGLM
%
% WORKFLOW
%   1. TS = run job_extract_timeseries_from_atlas(...)
%   2. job_timeseries_to_connectivity_matrix(TS)
%
% SYNTAX
%   TS = job_timeseries_to_connectivity_seedbased_spmGLM(TS)
%   TS = job_timeseries_to_connectivity_seedbased_spmGLM(TS, par)
%
% AFTER
%
%
% See also job_timeseries_to_connectivity_matrix plot_resting_state_connectivity_matrix job_timeseries_to_connectivity_network

warning('please use job_timeseries_to_connectivity_seedbased_pearson_zfisher instead')

if nargin==0, help(mfilename('fullpath')); return; end


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

%% defpar

% classic matvol
defpar.redo = 0;

par = complet_struct(par,defpar);


%% main

nVol   = numel(TS_struct              );
nAtlas = numel(TS_struct(1).atlas_name);

for iVol = 1 : nVol
    
    vol_data = TS_struct(iVol); % shortcut
    
    for atlas_idx = 1 : nAtlas
        
        % shortucts
        atlas_name = vol_data.atlas_name{atlas_idx};
        atlas_mdl_dir = fullfile(vol_data.outdir, 'seedbased', atlas_name);
        
        spmT = fullfile(atlas_mdl_dir, 'spmT.nii');
        
        if par.redo
            do_delete(atlas_mdl_dir,0);
        end

        if exist(spmT, 'file')
            fprintf('[%s]: %d/%d %s exists %s \n', mfilename, iVol, nVol, atlas_name, spmT)
            continue
        end
        
        timeseries_data = load( vol_data.(atlas_name) );
        nROI = size(timeseries_data.atlas_table,1);
        TR    = timeseries_data.TR;
        % nTR   = timeseries_data.nTR;
        scans = timeseries_data.scans;
        
        for iROI = 1 : nROI
            
            ROIname       = timeseries_data.atlas_table.ROIabbr{iROI};
            ROItimeseries = timeseries_data.timeseries(:,iROI);
            ROI_model_dir = fullfile(atlas_mdl_dir, ROIname);
            
            clear matlabbatch
            
            % specification
            matlabbatch{1}.spm.stats.fmri_spec.dir = {ROI_model_dir};
            matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
            matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR;
            matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
            matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
            matlabbatch{1}.spm.stats.fmri_spec.sess.scans = scans;
            matlabbatch{1}.spm.stats.fmri_spec.sess.cond = struct('name',{}, 'onset',{}, 'duration',{}, 'tmod',0, 'pmod',{}, 'orth', 0);
            matlabbatch{1}.spm.stats.fmri_spec.sess.multi = {''};
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress.name = ROIname;
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress.val  = ROItimeseries;
            matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = timeseries_data.par.confound(iVol); %%%%
            matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = 128;
            matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
            matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
            matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
            matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
            matlabbatch{1}.spm.stats.fmri_spec.mthresh = timeseries_data.par.mask_threshold;
            if isfield(timeseries_data.par, 'mask')
                matlabbatch{1}.spm.stats.fmri_spec.mask = timeseries_data.par.mask(iVol); %%%
            else
                matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
            end
            matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
            
            % estimation
            matlabbatch{2}.spm.stats.fmri_est.spmmat(1)        = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
            matlabbatch{2}.spm.stats.fmri_est.write_residuals  = 0;
            matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
            
            % contrast
            matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
            matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = ROIname;
            matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
            matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
            matlabbatch{3}.spm.stats.con.delete = 1;
            
            spm_jobman('run', matlabbatch);
        
        end
        
        % concatenate all spmT (1 for each ROI) in a single 4D volume : easier review
        
        clear matlabbatch
        
        matlabbatch{1}.spm.util.cat.vols = fullfile(vol_data.outdir, 'seedbased', atlas_name, timeseries_data.atlas_table.ROIabbr, 'spmT_0001.nii');
        matlabbatch{1}.spm.util.cat.name = spmT;
        matlabbatch{1}.spm.util.cat.dtype = 0;
        matlabbatch{1}.spm.util.cat.RT = NaN;
        
        spm_jobman('run', matlabbatch);
        
    end
    
end

end % function
