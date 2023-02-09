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
defpar.redo = 0;

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
    clear noetwork conn_network
    
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
            [~,idx_roi_in_netwok,~] = intersect(ts_data.ts_table.abbreviation , n.roi);
            n.table = ts_data.ts_table(idx_roi_in_netwok,:);
            assert(length(idx_roi_in_netwok) == n.size, 'in network ''%s'' did not find exactly once each ROI abbreveiation ', n.name)
            for roi_idx = 1 : n.size
                n.ts(:,roi_idx) = ts_data.timeseries(:,n.table.id(roi_idx));
            end
            n.mx   = corrcoef(n.ts);
            n.mask = triu(true(n.size),+1); % mask to fetch each pair only once
            
            % intra connectivity
            n.avg = sum(n.mx(:).*n.mask(:)) / n.nconn;
            n.var = sum( ((n.mx(:) - n.avg).^2).*n.mask(:) ) / n.nconn;
            n.std = sqrt(n.var);
            
            % save
            network(i) = n; %#ok<AGROW> 
        end
        
        % intra & inter connectivity
        for i = 1 : length(network_list)
            for j = 1 : length(network_list)
                cn = struct; % current connectivity network struct, storing all infos
                
                cn.name1  = network_list{i};
                cn.name2  = network_list{j};
                cn.roi1   = network(i).roi;
                cn.roi2   = network(j).roi;
                cn.size1  = numel(cn.roi1);
                cn.size2  = numel(cn.roi2);
                cn.table1 = network(i).table;
                cn.table2 = network(j).table;
                
                if i == j
                    cn.type  = 'intra';
                    cn.nconn = network(i).nconn;
                    cn.mx    = network(i).mx;
                    cn.mask  = network(i).mx;
                    cn.avg   = network(i).avg;
                    cn.var   = network(i).var;
                    cn.std   = network(i).std;
                end
                
                if i ~= j
                    cn.type  = 'inter';
                    cn.nconn = cn.size1 * cn.size2;
                    
                    % fetch timeseries of each network, already extracted a few lines above
                    ts1 = network(i).ts;
                    ts2 = network(j).ts;
                    
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
                conn_network(i,j) = cn; %#ok<AGROW> 
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
