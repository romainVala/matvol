function TS_struct = job_timeseries_to_connectivity_matrix(TS_struct, par)
%job_timeseries_to_connectivity_matrix
%
% WORKFLOW
%   1. TS = run job_extract_timeseries(...)
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

for iVol = 1 : nVol
        
    % prepare output file names and paths
    connectivity_path = addprefixtofilenames(TS_struct(iVol).timeseries_path,'connectivity__');
    TS_struct(iVol).connectivity_path = connectivity_path;
    
    % skip ?
    if exist(connectivity_path, 'file') && ~par.redo
        fprintf('[%s]: connectivity matrix exists : %d/%d - %s - %s \n', mfilename, iVol, nVol, TS_struct(iVol).outname, connectivity_path)
        continue
    end
    
    % load timeseries and compute connectivity matrix
    ts_data = load(TS_struct(iVol).timeseries_path);
    [connectivity_matrix, confidence_matrix] = corrcoef(ts_data.timeseries);
    
    % save
    ts_table = ts_data.ts_table;
    save(connectivity_path, 'connectivity_matrix', 'confidence_matrix', 'ts_table');
    
end % iVol

end % function
