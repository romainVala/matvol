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
% See also job_timeseries_to_connectivity_matrix plot_resting_state_connectivity_matrix job_timeseries_to_connectivity_network job_timeseries_to_connectivity_seedbased

if nargin==0, help(mfilename('fullpath')); return; end


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

%% defpar

% classic matvol
defpar.redo = 1;

par = complet_struct(defpar,par);


%% check network

use_network = 0;

if isfield(par, 'network')
    use_network = 1;
    
    assert(isstruct(par.network), 'par.network must be a structure. Check help')
    
    network_list = fieldnames(par.network);
    assert(~isempty(network_list), 'empty network list')
    
    for i = 1 : length(network_list)
        network_name = network_list{i};
        network_roi  = par.network.(network_name);
        assert(iscellstr(network_roi) && ~isempty(network_roi), 'par.network.%s must be non-empty cellstr. Check help', network_name) %#ok<ISCLSTR> 
    end
    
end


%% main

nVol = numel(TS_struct);

for iVol = 1 : nVol
        
    % prepare output file names and paths
    if use_network
        connectivity_path = addprefixtofilenames(TS_struct(iVol).timeseries_path,sprintf('connectivity__%s__', strjoin(network_list, '_')));
        TS_struct(iVol).network = par.network;
    else
        connectivity_path = addprefixtofilenames(TS_struct(iVol).timeseries_path,'connectivity__');
    end
    TS_struct(iVol).connectivity_path = connectivity_path;
    
    % skip ?
    if exist(connectivity_path, 'file') && ~par.redo
        fprintf('[%s]: connectivity matrix exists : %d/%d - %s - %s \n', mfilename, iVol, nVol, TS_struct(iVol).outname, connectivity_path)
        continue
    end
    
    % load timeseries and compute connectivity matrix : all ROIs
    ts_data = load(TS_struct(iVol).timeseries_path);
    connectivity_matrix = corrcoef(ts_data.timeseries);
    
    if use_network
        for i = 1 : length(network_list)
            % set network
            n = struct; % current network struct, storing all infos
            n.name = network_list{i};
            n.roi  = par.network.(n.name);
            n.size = numel(n.roi);
            n.ts   = zeros(ts_data.nTR, n.size);
            n.nconn= n.size*(n.size-1)/2;
            for roi_idx = 1 : n.size
                roi_id = find( strcmp(ts_data.ts_table.abbreviation, n.roi{roi_idx}) );
                assert(~isempty(roi_id), 'in network ''%s'' did not find ROI abbreveiation ''%s'' ', n.name, n.roi{roi_idx})
                n.ts(:,roi_idx) = ts_data.timeseries(:,roi_id);n.mx = corrcoef(n.ts);
            end
            n.mask = triu(true(n.size),+1); % mask to fetch each pair only once
            
            % intra connectivity
            n.conn_avg = sum(n.mx(:).*n.mask(:)) / n.nconn;
            n.conn_var = sum( ((n.mx(:) - n.conn_avg).^2).*n.mask(:) ) / n.nconn;
            n.conn_std = sqrt(n.conn_var);
            
            % save
            network(i) = n; %#ok<AGROW> 
        end
        
        conn_network      = struct;
        conn_network.name = network_list;
        conn_network.size = length(network_list);
        conn_network.avg  = zeros(conn_network.size);
        conn_network.var  = zeros(conn_network.size);
        conn_network.std  = zeros(conn_network.size);
        
        % intra & inter connectivity
        for i = 1 : length(network_list)
            for j = 1 : length(network_list)
                
                if i == j
                    conn_network.avg(i,j) = network(i).conn_avg;
                    conn_network.var(i,j) = network(i).conn_var;
                    conn_network.std(i,j) = network(i).conn_std;
                end
                
                if i ~= j
                    
                end
                
            end
        end
        
    end
    
    % save
    ts_table = ts_data.ts_table;
    
    if use_network
        save(connectivity_path, 'connectivity_matrix', 'ts_table', 'network', 'conn_network');
    else
        save(connectivity_path, 'connectivity_matrix', 'ts_table');
    end
    
end % iVol

end % function
