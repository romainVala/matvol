function [data, conn_result] = get_resting_state_connectivity_matrix(conn_result)
% get_resting_state_connectivity_matrix will load connectivity matrix (and network)
% using the output of job_timeseries_to_connectivity_matrix
%
% SYNTAX
%        data               = get_resting_state_connectivity_matrix( output_of__job_timeseries_to_connectivity_matrix )
%       [data, conn_result] = get_resting_state_connectivity_matrix( output_of__job_timeseries_to_connectivity_matrix )
%
% OUTPUT
%       conn_result : A copy of output_of__job_timeseries_to_connectivity_matrix, with the connectivity matrix data inside, as a new field.
%                     The new field is "conn_result(iVol).connectivity_content"
%
%       data : Here is a description of the data structure content.
%              !!! in this exemple, nVolume = 34 (= nSubject) !!!
%
%             data = 
%             
%               struct with fields:
%             
%                   table: [161×7 table]          # just a copy of the table in each output of "job_extract_timeseries"
%                      mx: [161×161×34 double]    # [nROI nROI nVolume] this is a stack of all connectivity matrix
%                 network: [1×1 struct]           # this field only appears when par.network is given to "job_timeseries_to_connectivity_matrix"
%
%             data.network =                      # in this exemple, there are 2 networks, DMN and MOTOR
%             
%               struct with fields:
%             
%                    name: {2×2 cell}             # a recall of the networks interactions                       : diagonal terms are INTRA, non-diagonal terms are INTER
%                     avg: [2×2×34 double]        # average            of network coonectivity for each network : diagonal terms are INTRA, non-diagonal terms are INTER
%                     var: [2×2×34 double]        # variance           of network coonectivity for each network : diagonal terms are INTRA, non-diagonal terms are INTER
%                     std: [2×2×34 double]        # standard deviation of network coonectivity for each network : diagonal terms are INTRA, non-diagonal terms are INTER
%                 details: [2×2×34 struct]        # a copy of all details from the network measures             : diagonal terms are INTRA, non-diagonal terms are INTER
%                     DMN: [50×50×34 double]      # connectivity matrix of the network [nROI_in_network nROI_in_network nVolume]
%                   MOTOR: [48×48×34 double]      # connectivity matrix of the network [nROI_in_network nROI_in_network nVolume]
%                 
%
% See also job_extract_timeseries job_timeseries_to_connectivity_matrix plot_resting_state_connectivity_matrix

if nargin==0, help(mfilename('fullpath')); return; end


%% Load data

assert( isfield(conn_result, 'connectivity_path'), '.connectivity_path field is not prensent : please run "job_timeseries_to_connectivity_matrix" first')

for iVol = 1 : length(conn_result)
    conn_result(iVol).connectivity_content = load(conn_result(iVol).connectivity_path);
end


%% Get data

% Prepare 
content = [conn_result.connectivity_content];
content = reshape(content, size(conn_result));

% Prepare output data structure
data = struct;

data.table = content(1).ts_table;
data.mx = cat(3,content.connectivity_matrix);

if isfield(conn_result, 'network')
    
    conn_network = cat(3,content.conn_network);
    name1 = reshape({conn_network(:,:,1).name1}, size(conn_network(:,:,1)));
    name2 = reshape({conn_network(:,:,1).name2}, size(conn_network(:,:,1)));
    
    data.network.name = strcat(name1, '__', name2);
    data.network.avg = reshape([conn_network.avg], size(conn_network));
    data.network.var = reshape([conn_network.var], size(conn_network));
    data.network.std = reshape([conn_network.std], size(conn_network));
    data.network.details = conn_network;
    
    network = cat(2,content.network);
    for n = 1 : size(network,1)
        data.network.(network(n,1).name) = cat(3,network(n,:).mx);
    end
    
end


end % function
