function varargout = plot_resting_state_connectivity_matrix( conn_result, IDs )
%plot_resting_state_connectivity_matrix will plot connectivity matrix using
%the output of job_timeseries_to_connectivity_matrix
%
% SYNTAX
%             plot_resting_state_connectivity_matrix( output_of__job_timeseries_to_connectivity_matrix      )
%             plot_resting_state_connectivity_matrix( output_of__job_timeseries_to_connectivity_matrix, IDs )
%   guidata = plot_resting_state_connectivity_matrix( output_of__job_timeseries_to_connectivity_matrix, IDs )
%
% IDs is a cellstr that will be used as 'Title' (1 per volume), typically
% it is the list of subject name
%
% See also job_extract_timeseries_from_atlas job_timeseries_to_connectivity_matrix

if nargin==0, help(mfilename('fullpath')); return; end


%% Checks

if exist('IDs','var')
    assert(iscellstr(IDs),'IDs MUST be a cellstr') %#ok<ISCLSTR> 
    assert(length(conn_result) == length(IDs), 'conn_result and IDs MUST have the same length')
    ID_list = IDs;
else
    ID_list = {conn_result.volume};
end


%% Load data

atlas_name = conn_result(1).atlas_name;
nAtlas = length(atlas_name);

for iVol = 1 : length(conn_result)
    for atlas_idx = 1 : nAtlas
        conn_result(iVol).connectivity_matrix.([atlas_name{atlas_idx} '_content']) = load(conn_result(iVol).connectivity_matrix.(atlas_name{atlas_idx}));
    end
end


%% Prepare GUI

%--------------------------------------------------------------------------
%- Open figure

% Create a figure
figHandle = figure( ...
    'Name'            , mfilename                , ...
    'NumberTitle'     , 'off'                    , ...
    'Units'           , 'Pixels'                 , ...
    'Position'        , [50, 50, 1200, 800]      );

% Set some default colors
figureBGcolor = [0.9 0.9 0.9]; set(figHandle,'Color',figureBGcolor);
buttonBGcolor = figureBGcolor - 0.1;
editBGcolor   = [1.0 1.0 1.0];

% Create GUI handles : pointers to access the graphic objects
handles               = guihandles(figHandle);
handles.figHandle     = figHandle;
handles.figureBGcolor = figureBGcolor;
handles.buttonBGcolor = buttonBGcolor;
handles.editBGcolor   = editBGcolor  ;

handles.conn_result = conn_result;

%--------------------------------------------------------------------------
%- Prepare panels

panel_pos = [
    0.00   0.00   0.10   1.00
    0.10   0.00   0.20   1.00
    0.30   0.00   0.60   1.00
    0.90   0.00   0.10   1.00
    ];

handles.uipanel_select = uipanel(figHandle,...
    'Title',          'Selection',...
    'Units',          'Normalized',...
    'Position',        panel_pos(1,:),...
    'BackgroundColor', figureBGcolor);

handles.uipanel_roi = uipanel(figHandle,...
    'Title',          'ROI',...
    'Units',          'Normalized',...
    'Position',        panel_pos(2,:),...
    'BackgroundColor', figureBGcolor);

handles.uipanel_plot = uipanel(figHandle,...
    'Title',          'Plot',...
    'Units',          'Normalized',...
    'Position',        panel_pos(3,:),...
    'BackgroundColor', figureBGcolor);

handles.uipanel_threshold = uipanel(figHandle,...
    'Title',          'Threshold',...
    'Units',          'Normalized',...
    'Position',        panel_pos(4,:),...
    'BackgroundColor', figureBGcolor);

%--------------------------------------------------------------------------
%- Prepare Selection

tag = 'listbox_atlas';
handles.(tag) = uicontrol(handles.uipanel_select, 'Style', 'listbox',...
    'String',   atlas_name,...
    'Value',    1,...
    'Units',    'normalized',...
    'Position', [0.00 0.90 1.00 0.10],...
    'Tag',      tag,...
    'Callback', @UPDATE);

tag = 'listbox_id';
handles.(tag) = uicontrol(handles.uipanel_select, 'Style', 'listbox',...
    'String',   ID_list,...
    'Value',    1,...
    'Units',    'normalized',...
    'Position', [0.00 0.00 1.00 0.90],...
    'Tag',      tag,...
    'Callback', @UPDATE);

%--------------------------------------------------------------------------
%- Prepare ROI

tag = 'uitable_roi';
handles.(tag) = uitable(handles.uipanel_roi,...
    'Units',    'normalized',...
    'Position', [0.00 0.00 1.00 1.00],...
    'Tag',      tag);

%--------------------------------------------------------------------------
%- Prepare Threshold

handles.default_threshold = 0.00; % from 0 to 1

tag = 'slider_pos';
handles.slider_pos = uicontrol(handles.uipanel_threshold, 'Style', 'slider',...
    'Min',      0,...
    'Max',      1,...
    'Value',    handles.default_threshold, ...
    'SliderStep', [0.05 0.10],...
    'Units',    'normalized',...
    'Position', [0.00 0.00 0.50 0.80],...
    'Tag',      tag,...
    'Callback', @UPDATE);

tag = 'edit_pos';
handles.(tag) = uicontrol(handles.uipanel_threshold, 'Style', 'edit',...
    'String',   num2str(handles.default_threshold), ...
    'Units',    'normalized',...
    'Position', [0.00 0.80 0.50 0.10],...
    'Tag',      tag,...
    'Callback', @UPDATE);

tag = 'slider_neg';
handles.(tag) = uicontrol(handles.uipanel_threshold, 'Style', 'slider',...
    'Min',      0,...
    'Max',      1,...
    'Value',    handles.default_threshold, ...
    'SliderStep', [0.05 0.10],...
    'Units',    'normalized',...
    'Position', [0.50 0.00 0.50 0.80],...
    'Tag',      tag,...
    'Callback', @UPDATE);

tag = 'edit_neg';
handles.(tag) = uicontrol(handles.uipanel_threshold, 'Style', 'edit',...
    'String',   num2str(-handles.default_threshold), ...
    'Units',    'normalized',...
    'Position', [0.50 0.80 0.50 0.10],...
    'Tag',      tag,...
    'Callback', @UPDATE);

tag = 'checkbox_link_pos_neg';
handles.(tag) = uicontrol(handles.uipanel_threshold, 'Style', 'checkbox',...
    'String',   'link + & -',...
    'Value',    1, ...
    'Units',    'normalized',...
    'Position', [0.00 0.90 1.00 0.05],...
    'Tag',      tag,...
    'Callback', @UPDATE);

tag = 'checkbox_use_threshold';
handles.(tag) = uicontrol(handles.uipanel_threshold, 'Style', 'checkbox',...
    'String',   'threshold',...
    'Value',    0, ...
    'Units',    'normalized',...
    'Position', [0.00 0.95 1.00 0.05],...
    'Tag',      tag,...
    'Callback', @UPDATE);

%--------------------------------------------------------------------------
%- Prepare Plot

handles.axes = axes(handles.uipanel_plot);

%--------------------------------------------------------------------------
%- Done

% IMPORTANT
guidata(figHandle,handles)
% After creating the figure, dont forget the line
% guidata(figHandle,handles) . It allows smart retrive like
% handles=guidata(hObject)

% Initilization of the plot. I know, this looks weird... but it works, and it's fast enough.
imagesc(handles.axes, 0);
set_axes(figHandle)
set_mx(figHandle)
set_axes(figHandle)
set_threshold(figHandle)

% assign callback after creation of objects
handles.axes.Children.ButtonDownFcn = @plot_click; % matrix (image) callback

% Initialize table
set_roi(figHandle)

if nargout > 0
    varargout{1} = handles;
end


end % function

function set_axes(hObject)
    handles = guidata(hObject); % retrieve guidata

    axe = handles.axes;
    
    content = get_atlas_content(hObject);
    imagesc(axe, content.connectivity_matrix);
    
    colormap(axe,jet)
    caxis(axe,[-1 +1])
    colorbar(axe);
    axis(axe,'equal')
    
    axe.XTick = 1:size(content.atlas_table,1);
    axe.XTickLabel = content.atlas_table.ROIabbr;
    axe.XTickLabelRotation = 45;
    axe.YTick = 1:size(content.atlas_table,1);
    axe.YTickLabel = content.atlas_table.ROIabbr;
    
    axe.Color = handles.figureBGcolor;
    
    guidata(hObject, handles); % need to save stuff
end

function set_mx(hObject)
    handles = guidata(hObject); % retrieve guidata
    
    content = get_atlas_content(hObject);
    handles.axes.Children.CData = content.connectivity_matrix;
    
    guidata(hObject, handles); % need to save stuff
end

function set_roi(hObject)
    handles = guidata(hObject); % retrieve guidata
    
    content = get_atlas_content(hObject);
    handles.uitable_roi.Data = [content.atlas_table.ROIabbr content.atlas_table.ROIname];
    handles.uitable_roi.ColumnName = {'ROIabbr', 'ROIname'};
    
    guidata(hObject, handles); % need to save stuff
end

function threshold_mx(hObject, pos, neg)
    handles = guidata(hObject); % retrieve guidata
    
    handles.axes.Children.AlphaData = ~(handles.axes.Children.CData <= pos & handles.axes.Children.CData >= neg);
    handles.axes.Children.AlphaData = handles.axes.Children.AlphaData & ~diag(diag(handles.axes.Children.AlphaData));
    
    guidata(hObject, handles); % need to save stuff
end

function UPDATE(hObject,eventData)
    handles = guidata(hObject); % retrieve guidata
    
    switch hObject.Tag
        
        case 'slider_pos'
            set_pos(handles, hObject.Value);
            if handles.checkbox_link_pos_neg.Value
                set_neg(handles, hObject.Value);
            end
            threshold_mx(hObject, str2double(handles.edit_pos.String), str2double(handles.edit_neg.String))
            
        case 'edit_pos'
            set_pos(handles, str2double(hObject.String));
            if handles.checkbox_link_pos_neg.Value
                set_neg(handles, str2double(hObject.String));
            end
            threshold_mx(hObject, str2double(handles.edit_pos.String), str2double(handles.edit_neg.String))
            
        case 'slider_neg'
            set_neg(handles, hObject.Value);
            if handles.checkbox_link_pos_neg.Value
                set_pos(handles, hObject.Value);
            end
            threshold_mx(hObject, str2double(handles.edit_pos.String), str2double(handles.edit_neg.String))
            
        case 'edit_neg'
            set_neg(handles, -str2double(hObject.String));
            if handles.checkbox_link_pos_neg.Value
                set_pos(handles, -str2double(hObject.String));
            end
            threshold_mx(hObject, str2double(handles.edit_pos.String), str2double(handles.edit_neg.String))
            
        case 'checkbox_link_pos_neg'
            if hObject.Value
                set_neg(handles, handles.slider_pos.Value);
            end
            threshold_mx(hObject, str2double(handles.edit_pos.String), str2double(handles.edit_neg.String))
            
        case 'listbox_id'
            set_mx(hObject)
            if handles.checkbox_use_threshold.Value
                threshold_mx(hObject, str2double(handles.edit_pos.String), str2double(handles.edit_neg.String))
            else
                threshold_mx(hObject, 0, 0)
            end
            
        case 'listbox_atlas'
            set_axes(hObject)
            set_mx(hObject)
            threshold_mx(hObject, str2double(handles.edit_pos.String), str2double(handles.edit_neg.String))
            set_roi(hObject)
            
        case 'checkbox_use_threshold'
            set_threshold(hObject)
            
        otherwise
            warning(hObject.Tag)
    end
    
    guidata(hObject, handles); % store guidata
end

function set_pos(handles, value)
    if isnan(value) || value < 0 || value > 1
        value = handles.default_threshold;
    end
    value = round5pct(value);
    handles.edit_pos.String = num2str(value);
    handles.slider_pos.Value = value;
end

function set_neg(handles, value)
    if isnan(value) || value < 0 || value > 1
        value = handles.default_threshold;
    end
    value = round5pct(value);
    handles.edit_neg.String = num2str(-value);
    handles.slider_neg.Value = value;
end

function out = round5pct(in)
    out = round(in * 20) / 20;
end

function content = get_atlas_content(hObject)
    handles = guidata(hObject); % retrieve guidata
    
    atlas_name = handles.listbox_atlas.String{handles.listbox_atlas.Value};
    content = handles.conn_result(handles.listbox_id.Value).connectivity_matrix.([atlas_name '_content']);
    
    guidata(hObject, handles); % need to save stuff
end

function set_threshold(hObject)
    handles = guidata(hObject); % retrieve guidata
    
    % visibility
    if handles.checkbox_use_threshold.Value
        visible = 'on';
    else
        visible = 'off';
    end
    handles.checkbox_link_pos_neg.Visible = visible;
    handles.edit_pos.Visible = visible;
    handles.edit_neg.Visible = visible;
    handles.slider_pos.Visible = visible;
    handles.slider_neg.Visible = visible;
    
    % update threshold
    if handles.checkbox_use_threshold.Value
        threshold_mx(hObject, str2double(handles.edit_pos.String), str2double(handles.edit_neg.String))
    else
        threshold_mx(hObject, 0, 0)
    end
    
    guidata(hObject, handles); % need to save stuff
end

function plot_click(hObject, eventData)
    handles = guidata(hObject); % retrieve guidata
    
    % fetch data point
    coord = round(eventData.IntersectionPoint(1:2));
    content = get_atlas_content(hObject);
    
    % prepare infos
    R = content.connectivity_matrix(coord(1), coord(2));
    roi_1_abbr = content.atlas_table.ROIabbr{coord(1)};
    roi_2_abbr = content.atlas_table.ROIabbr{coord(2)};
    roi_1_name = content.atlas_table.ROIname{coord(1)};
    roi_2_name = content.atlas_table.ROIname{coord(2)};
    
    fprintf('R = %+1.3f --- %-11s / %-11s --- %s / %s \n', R, roi_1_abbr, roi_2_abbr, roi_1_name, roi_2_name)
    
    guidata(hObject, handles); % need to save stuff
end
