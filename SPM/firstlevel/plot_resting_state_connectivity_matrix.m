function plot_resting_state_connectivity_matrix( conn_result, IDs )
%PLOT_RESTING_STATE_CONNECTIVITY_MATRIX will plot connectivity matrix using
%the output of job_timeseries_to_connectivity_matrix
%
% SYNTAX
%   PLOT_RESTING_STATE_CONNECTIVITY_MATRIX( output_of__job_timeseries_to_connectivity_matrix )
%   PLOT_RESTING_STATE_CONNECTIVITY_MATRIX( output_of__job_timeseries_to_connectivity_matrix, IDs )
%
% IDs is a cellstr that will be used as 'Title' for the tab (1 per volume),
% typically it is the list of subject name
%
% See also job_resting_state_connectivity_matrix

if nargin==0, help(mfilename('fullpath')); return; end


%% Checks

use_IDs = false;
if exist('IDs','var')
    use_IDs = true;
    assert(iscellstr(IDs),'IDs MUST be a cellstr') %#ok<ISCLSTR> 
    assert(length(conn_result) == length(IDs), 'conn_result and IDs MUST have the same length')
end


%% Main

atlas_name = conn_result(1).atlas_name;
nAtlas = length(atlas_name);

% 1 figure per atlas
for atlas_idx = 1 : nAtlas
    
    atlas = atlas_name{atlas_idx};
    
    fig = figure('Name',atlas,'NumberTitle','off');
    tabgroup = uitabgroup(fig);
    
    % 1 tab per volume (usually 1 per subject)
    for iVol = 1 : length(conn_result)
        
        if use_IDs
            title = IDs{iVol};
        else
            title = conn_result(iVol).volume;
        end
        tab = uitab(tabgroup,'Title',title);
        ax(iVol) = axes(tab); %#ok<AGROW,LAXES> 
        axe = ax(iVol); % just a shortcut, for readability
        
        conn = load(conn_result(iVol).connectivity.(atlas));
        
        imagesc(axe,conn.connectivity_matrix);
        colormap(axe,jet)
        caxis(axe,[-1 +1])
        colorbar(axe)
        axis(axe,'equal')
        
        axe.XTick = 1:size(conn.atlas_table,1);
        axe.XTickLabel = conn.atlas_table.ROIabbr;
        axe.XTickLabelRotation = 45;
        axe.YTick = 1:size(conn.atlas_table,1);
        axe.YTickLabel = conn.atlas_table.ROIname;
        
    end
    
    linkaxes(ax, 'xy')
    
end


end % function
