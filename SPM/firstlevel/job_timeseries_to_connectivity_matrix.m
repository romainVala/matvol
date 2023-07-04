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
%
%----------------------------------------------------------------------------------------------------------------------------------------------------
% defining networks
%----------------------------------------------------------------------------------------------------------------------------------------------------
%
%   GENERAL SYNTAX
%          .network.<network_name> = {<abbrev_list>}
%
%   EXEMPLE
%       par.network.motor = {'lSMA', 'rSMA', 's3lGPe', 's2lGPi', 'mStriatum'};
%       par.network.language = {'mBroca', 'lHIP', 'rHIP'};
%       par.network.cingular = {
%           'lPCC', 'rPCC'
%           'lMCC', 'rMCC'
%           'lACCsub', 'rACCsub'
%           'lACCpre', 'rACCpre'
%           'lACCsub', 'rACCsub'
%           };
%
%   REQUIREMENT
%       Abbreviation list must come from the .roi_type from job_extract_timeseries.
%       If abbrev comes from sphere or mask, then it's easy, since user defines them.
%       If abbref comes from an atlas, user need to check it's abbreviations
%
%
%----------------------------------------------------------------------------------------------------------------------------------------------------
% dynamic connectivity
%----------------------------------------------------------------------------------------------------------------------------------------------------
%
%   SYNTAX
%          .dynmaic.window_length = <number of minutes>
%
%   EXEMPLE
%       par.dynmaic.window_length = 2;
%
%
% See also job_extract_timeseries plot_resting_state_connectivity_matrix job_timeseries_to_connectivity_seedbased

if nargin==0, help(mfilename('fullpath')); return; end


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

%% defpar

% classic matvol
defpar.redo = 0;

par = complet_struct(par,defpar);


%% check network

use_network = false;

if isfield(par, 'network')
    use_network = true;

    assert(isstruct(par.network), 'par.network must be a structure. Check help')

    network_list = fieldnames(par.network);
    assert(~isempty(network_list), 'empty network list')

    for i = 1 : length(network_list)
        network_name = network_list{i};
        network_roi  = par.network.(network_name);
        assert(iscellstr(network_roi) && ~isempty(network_roi), 'par.network.%s must be non-empty cellstr. Check help', network_name) %#ok<ISCLSTR>
    end

end


%% check dynamic

use_dynamic = false;

if isfield(par, 'dynamic')
    use_dynamic = true;

    assert(isstruct(par.dynamic), 'par.dynamic must be a structure. Check help')
    assert(isfield(par.dynamic,'window_length'), 'par.dynamic.window_length must be a defined. Check help')

end


%% main

nVol = numel(TS_struct);

for iVol = 1 : nVol
    clear noetwork conn_network

    % prepare output file names and paths
    connectivity_prefix = 'static_conn__';
    if use_network
        connectivity_prefix = sprintf('%s%s__', connectivity_prefix, strjoin(network_list, '_'));
        TS_struct(iVol).network = par.network;
    end
    if use_dynamic
        connectivity_prefix = sprintf('%s%s__', connectivity_prefix, 'dynamic_conn');
        TS_struct(iVol).dynamic = par.dynamic;
    end
    connectivity_path = addprefixtofilenames(TS_struct(iVol).timeseries_path,connectivity_prefix);
    TS_struct(iVol).connectivity_path = connectivity_path;

    % skip ?
    if exist(connectivity_path, 'file') && ~par.redo
        fprintf('[%s]: connectivity matrix exists : %d/%d - %s - %s \n', mfilename, iVol, nVol, TS_struct(iVol).outname, connectivity_path)
        continue
    end

    % load timeseries and compute connectivity matrix : all ROIs
    ts_data = load(TS_struct(iVol).timeseries_path);
    static_connectivity_matrix = corrcoef(ts_data.timeseries);

    if use_network
        [static_network_data , static_network_connectivity] = timeseries_to_network( ts_data.timeseries, ts_data.ts_table, par.network );
    end
    
    if use_dynamic
        window_length_in_TR = round(par.dynamic.window_length*60 / (ts_data.TR)); % minutes -> number_of_TRs
        dynamic_ts = timeseries_static_to_dynamic(ts_data.timeseries, window_length_in_TR);
        
        dynamic_connectivity_matrix = zeros([size(static_connectivity_matrix) ts_data.nTR]);
        for idx_TR = 1 : ts_data.nTR
            dynamic_connectivity_matrix(:,:,idx_TR) = corrcoef(squeeze(dynamic_ts(idx_TR,:,:))');
        end
    end

    % save
    ts_table = ts_data.ts_table;

    if      use_network && ~use_dynamic
        save(connectivity_path, 'ts_table', 'static_connectivity_matrix', 'static_network_data', 'static_network_connectivity');
    elseif ~use_network &&  use_dynamic
        save(connectivity_path, 'ts_table', 'static_connectivity_matrix', 'dynamic_connectivity_matrix');
    elseif  use_network &&  use_dynamic
        
    else
        save(connectivity_path, 'ts_table', 'static_connectivity_matrix');
    end
    fprintf('[%s]: connectivity matrix saved : %d/%d - %s - %s \n', mfilename, iVol, nVol, TS_struct(iVol).outname, connectivity_path)

end % iVol

end % function

%----------------------------------------------------------------------------------------------------------------------------------------------------
function dynamic_ts = timeseries_static_to_dynamic(timeseries, window_length)

nTR  = size(timeseries,1);
nROI = size(timeseries,2);
dynamic_ts = zeros(nTR, nROI, window_length); % pre-allocation

for idx_TR = 1 : nTR
    mask = round((-window_length/2 : +window_length/2) - idx_TR);
    mask(mask < 1) = [];
    mask(mask > nTR) = [];
    sub_ts = timeseries(mask,:);
    sub_ts = [sub_ts ; zeros(window_length-length(mask),nROI)]; % padding : happens on the borders
    dynamic_ts(idx_TR, :, :) = sub_ts';
end

end % fcn

%----------------------------------------------------------------------------------------------------------------------------------------------------
function [network_data , network_conn] = timeseries_to_network( timeseries, table, network_struct )

network_list = fieldnames(network_struct);

for i = 1 : length(network_list)

    % set network
    n = struct; % current network struct, storing all infos
    n.name = network_list{i};
    n.roi  = network_struct.(n.name);
    n.size = numel(n.roi);
    n.ts   = zeros(size(timeseries,1), n.size);
    n.nconn= n.size*(n.size-1)/2;

    % check network !

    % absent
    networkROI_not_in_Table = setdiff(n.roi, table.abbreviation, 'stable');
    assert(isempty(networkROI_not_in_Table), 'roi from ''%s'' network not in extracted timeseries : %s', n.name, strjoin(networkROI_not_in_Table, ' '))

    % duplicate
    [~, uniqueIdx] = unique(n.roi); % Find the indices of the unique strings
    duplicates = n.roi; % Copy the original into a duplicate array
    duplicates(uniqueIdx) = []; % remove the unique strings, anything left is a duplicate
    duplicates = unique(duplicates); % find the unique duplicates
    assert(isempty(duplicates), 'roi from ''%s'' network has duplicates : %s', n.name, strjoin(duplicates, ' '))

    % extract timeseries
    [~,~,idx_roi_in_netwok] = intersect(n.roi, table.abbreviation, 'stable');
    n.table = table(idx_roi_in_netwok,:);
    for roi_idx = 1 : n.size
        n.ts(:,roi_idx) =timeseries(:,n.table.id(roi_idx));
    end
    n.mx   = corrcoef(n.ts);
    n.mask = triu(true(n.size),+1); % mask to fetch each pair only once

    % intra connectivity
    n.avg = sum(n.mx(:).*n.mask(:)) / n.nconn;
    n.var = sum( ((n.mx(:) - n.avg).^2).*n.mask(:) ) / n.nconn;
    n.std = sqrt(n.var);

    % save
    network_data(i) = n; %#ok<AGROW>
end
network_data = network_data(:);


% intra & inter connectivity
for i = 1 : length(network_data)
    for j = 1 : length(network_data)
        cn = struct; % current connectivity network struct, storing all infos

        cn.name1  = network_list{i};
        cn.name2  = network_list{j};
        cn.roi1   = network_data(i).roi;
        cn.roi2   = network_data(j).roi;
        cn.size1  = numel(cn.roi1);
        cn.size2  = numel(cn.roi2);
        cn.table1 = network_data(i).table;
        cn.table2 = network_data(j).table;

        if i == j
            cn.type  = 'intra';
            cn.nconn = network_data(i).nconn;
            cn.mx    = network_data(i).mx;
            cn.mask  = network_data(i).mx;
            cn.avg   = network_data(i).avg;
            cn.var   = network_data(i).var;
            cn.std   = network_data(i).std;
        end

        if i ~= j
            cn.type  = 'inter';
            cn.nconn = cn.size1 * cn.size2;

            % fetch timeseries of each network, already extracted a few lines above
            ts1 = network_data(i).ts;
            ts2 = network_data(j).ts;

            % conn matrix : network1 vs network2, the matrix is a rectangle
            % where each line   is roi@network1
            % and   each column is roi@network2
            cn.mx = zeros(cn.size1, cn.size2);
            for roi_idx1 = 1 : cn.size1
                for roi_idx2 = 1 : cn.size2
                    r = corrcoef(ts1(:,roi_idx1), ts2(:,roi_idx2)); % this is 2x2 symetric matrix...
                    cn.mx(roi_idx1, roi_idx2) = r(1,2);
                end
            end
            cn.mask  = true(size(cn.mx)); % keep all
            cn.avg   = mean(cn.mx(:));
            cn.var   = var (cn.mx(:));
            cn.std   = std (cn.mx(:));

        end

        % save
        network_conn(i,j) = cn; %#ok<AGROW>
    end
end

end % fcn

