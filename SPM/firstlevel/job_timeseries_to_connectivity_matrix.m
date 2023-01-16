function TS_struct = job_timeseries_to_connectivity_matrix(TS_struct, par)
%job_timeseries_to_connectivity_matrix
%
% WORKFLOW
%   1. TS = run job_extract_timeseries_from_atlas(...)
%   2. TS = job_timeseries_to_connectivity_matrix(TS)    <=== this function
%   The whole timeseries of each region will be used to compute pearson coeeficients
%   Use plot_resting_state_connectivity_matrix to plot the result
%
% SYNTAX
%   TS = job_timeseries_to_connectivity_matrix(TS)
%   TS = job_timeseries_to_connectivity_matrix(TS, par)
%
% AFTER
%   use plot_resting_state_connectivity_matrix(TS) to plot
%
% See also job_timeseries_to_connectivity_matrix plot_resting_state_connectivity_matrix job_timeseries_to_connectivity_network job_timeseries_to_connectivity_seedbased

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

nVol = numel(TS_struct);
nAtlas = numel(TS_struct(1).atlas_name);

for iVol = 1 : nVol
    
    vol_data = TS_struct(iVol); % shortcut
    
    for atlas_idx = 1 : nAtlas
        
        % shortucts
        atlas_name = vol_data.atlas_name{atlas_idx};
        atlas_path = vol_data.(atlas_name);
        
        % prepare output file names and paths
        atlas_connectivity_path = addprefixtofilenames(atlas_path,'connectivity_');
        TS_struct(iVol).connectivity_matrix.(atlas_name) = atlas_connectivity_path;
        
        % skip ?
        if exist(atlas_connectivity_path, 'file') && ~par.redo
            fprintf('[%s]: connectivity matrix exists : %d/%d - %s - %s \n', mfilename, iVol, nVol, atlas_name, atlas_connectivity_path)
            continue
        end
        
        % load timeseries and compute connectivity matrix
        atlas_data = load(atlas_path);
        connectivity_matrix = corrcoef(atlas_data.timeseries);
        
        % save
        atlas_table = atlas_data.atlas_table;
        save(atlas_connectivity_path, 'connectivity_matrix', 'atlas_table');
        fprintf('[%s]: connectivity matrix saved : %d/%d // %s // %s \n', mfilename, iVol, nVol, atlas_name, atlas_connectivity_path)
        
    end
    
end

end % function
