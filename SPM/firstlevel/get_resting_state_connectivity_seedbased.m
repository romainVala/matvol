function file_list = get_resting_state_connectivity_seedbased( conn_results )
% get_resting_state_connectivity_seedbased will build path in SPM style to
% access ROI seedbased connectivity, wich is contained in a 4D volume.
%
% SYNTAX
%       file_list = get_resting_state_connectivity_seedbased( output_of___job_timeseries_to_connectivity_seedbased )
%
% OUTPUT
%         !!! in this exemple, nVolume = 34 (= nSubject) !!!
%
%         file_list = 
%         
%           struct with fields:
%         
%             pearson: [1×1 struct]    # pearson correlation coefficents, values ranger is [-1   +1  ]
%             zfisher: [1×1 struct]    # zfisher correlation coefficents, values ranger is [-inf +inf] // zfisher = atanh(pearson)
%         
%         file_list.pearson
%         
%         ans = 
%         
%           struct with fields:        # here there is 1 field per ROI
%         
%                  lPreCG: {34×1 cell} # cellstr with SPM style, ready for a second-level analysis
%                  rPreCG: {34×1 cell}
%                    lSFG: {34×1 cell}
%                    rSFG: {34×1 cell}
%                    lMFG: {34×1 cell}
%                    rMFG: {34×1 cell}
%
% See also job_extract_timeseries job_timeseries_to_connectivity_seedbased

if nargin==0, help(mfilename('fullpath')); return; end


%% Checks

assert( isfield(conn_results, 'connectivity_seedbased'), '.connectivity_seedbased field is not prensent : please run "job_timeseries_to_connectivity_seedbased" first')


%% Load table

data = load(conn_results(1).timeseries_path);
ts_table = data.ts_table;
nROI = size(ts_table, 1);


%% Prepare paths

connectivity_seedbased = [conn_results.connectivity_seedbased];
pearson_path = {connectivity_seedbased.pearson}';
zfisher_path = {connectivity_seedbased.zfisher}';

file_list = struct;
for iROI = 1 : nROI
    file_list.pearson.(ts_table.abbreviation{iROI}) = strcat(pearson_path, ',', num2str(iROI));
    file_list.zfisher.(ts_table.abbreviation{iROI}) = strcat(zfisher_path, ',', num2str(iROI));
end % iROI


end % function
