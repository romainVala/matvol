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
% See also job_extract_timeseries job_timeseries_to_connectivity_matrix get_resting_state_connectivity_matrix

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

for iVol = 1 : length(conn_result)
    conn_result(iVol).connectivity_content = load(conn_result(iVol).connectivity_path);
end

listbox_name = {'<all>'};


%% Networks ?

use_network = false;
if isfield(conn_result(1), 'network')
    use_network = true;
    network_list = {conn_result(1).connectivity_content.static_network_data.name};
    listbox_name = [listbox_name '_inter_::avg' '_inter_::var' network_list ];
end


%% Dynamic ?

use_dynamic = false;
if isfield(conn_result(1), 'dynamic')
    use_dynamic = true;
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

handles.use_network = use_network;
handles.use_dynamic = use_dynamic;
handles.conn_result = conn_result;

%--------------------------------------------------------------------------
%- Prepare panels

panel_pos = [
    0.00   0.05   0.10   0.95
    0.10   0.05   0.20   0.95
    0.30   0.05   0.60   0.10
    0.30   0.15   0.60   0.85
    0.90   0.05   0.10   0.95
    0.00   0.00   1.00   0.05
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

handles.uipanel_highlight = uipanel(figHandle,...
    'Title',          'Highlight',...
    'Units',          'Normalized',...
    'Position',        panel_pos(3,:),...
    'BackgroundColor', figureBGcolor);

handles.uipanel_plot = uipanel(figHandle,...
    'Title',          'Plot',...
    'Units',          'Normalized',...
    'Position',        panel_pos(4,:),...
    'BackgroundColor', figureBGcolor);

handles.uipanel_threshold = uipanel(figHandle,...
    'Title',          'Threshold',...
    'Units',          'Normalized',...
    'Position',        panel_pos(5,:),...
    'BackgroundColor', figureBGcolor);

handles.uipanel_dynamic = uipanel(figHandle,...
    'Title',          'Dynamic',...
    'Units',          'Normalized',...
    'Position',        panel_pos(6,:),...
    'BackgroundColor', figureBGcolor);


%--------------------------------------------------------------------------
%- Prepare Selection

tag = 'listbox_name';
handles.(tag) = uicontrol(handles.uipanel_select, 'Style', 'listbox',...
    'String',   listbox_name,...
    'Value',    1,...
    'Units',    'normalized',...
    'Position', [0.00 0.80 1.00 0.20],...
    'Tag',      tag,...
    'Callback', @UPDATE);

tag = 'listbox_id';
handles.(tag) = uicontrol(handles.uipanel_select, 'Style', 'listbox',...
    'String',   ID_list,...
    'Value',    1,...
    'Units',    'normalized',...
    'Position', [0.00 0.00 1.00 0.80],...
    'Tag',      tag,...
    'Callback', @UPDATE);

%--------------------------------------------------------------------------
%- Prepare ROI

tag = 'uitable_roi';
handles.(tag) = uitable(handles.uipanel_roi,...
    'Units',    'normalized',...
    'Position', [0.00 0.00 1.00 1.00],...
    'Tag',      tag,...
    'CellSelectionCallback',@HIGHLIGHT);

%--------------------------------------------------------------------------
%- Prepare highlight

tag = 'uitable_highlight';
handles.(tag) = uitable(handles.uipanel_highlight,...
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
%- Prepare Dynamic
if handles.use_dynamic
    handles.dynamic_volume.nVolume = size(conn_result(1).connectivity_content.dynamic_connectivity_matrix,3);
else
    handles.dynamic_volume.nVolume = 1;
end
handles.dynamic_volume.iVolume = 1;
tag = 'slider_volume';
handles.(tag) = uicontrol(handles.uipanel_dynamic, 'Style', 'slider',...
    'Min',        0,...
    'Max',        handles.dynamic_volume.nVolume,...
    'Value',      1, ...
    'SliderStep', [1/handles.dynamic_volume.nVolume 10/handles.dynamic_volume.nVolume],...
    'Units',      'normalized',...
    'Position',   [0.00 0.0 1.00 1.00],...
    'Tag',        tag,...
    'Callback',   @UPDATE,...
    'Visible', handles.use_dynamic);

%--------------------------------------------------------------------------
%- Done

% Initialize other variables, for latter usage
handles.highlight_idx = []; % i cant find any variable representing the cell selected in an uitable

% IMPORTANT
guidata(figHandle,handles)
% After creating the figure, dont forget the line
% guidata(figHandle,handles) . It allows smart retrive like
% handles=guidata(hObject)

% Initilization of the plot. I know, this looks weird... but it works, and it's fast enough.
image(handles.axes, 0);
set_mx(figHandle)
set_axes(figHandle)
set_threshold(figHandle)

% Initialize table
set_roi(figHandle)

if nargout > 0
    varargout{1} = handles;
end


end % function

%--------------------------------------------------------------------------
function set_axes(hObject)
% set/reset function of the matrix display
handles = guidata(hObject); % retrieve guidata

axe = handles.axes;

[matrix, abbrev_x, abbrev_y] = get_conn_content(hObject);
imagesc(axe, matrix);

colormap(axe,jet)
caxis(axe,[-1 +1])
colorbar(axe);

axe.TickLabelInterpreter = 'none';
axe.XTick = 1:length(abbrev_x);
axe.XTickLabel = abbrev_x;
axe.XTickLabelRotation = 45;
axe.YTick = 1:length(abbrev_y);
axe.YTickLabel = abbrev_y;

axe.Color = handles.figureBGcolor;

axe.Children.ButtonDownFcn = @print_click; % matrix (image) callback
handles.uitable_highlight.CellSelectionCallback = @print_click;

guidata(hObject, handles); % need to save stuff
end

%--------------------------------------------------------------------------
function set_mx(hObject)
% get correlation matrix using GUI info and display it
handles = guidata(hObject); % retrieve guidata

val = handles.slider_volume.Value;
rval = round(val);
if val ~= rval
    handles.slider_volume.Value = rval;
end
handles.dynamic_volume.iVolume = rval;
guidata(hObject, handles); % need to save stuff

matrix = get_conn_content(hObject);
handles.axes.Children.CData = matrix;

guidata(hObject, handles); % need to save stuff
end

%--------------------------------------------------------------------------
function set_roi(hObject)
% update ROI list
handles = guidata(hObject); % retrieve guidata

[~, abbrev_x, ~, descrip_x, ~] = get_conn_content(hObject);
handles.uitable_roi.Data = [abbrev_x(:) descrip_x(:)];
handles.uitable_roi.ColumnName = {'abbreviation', 'description'};

guidata(hObject, handles); % need to save stuff
end

%--------------------------------------------------------------------------
function threshold_mx(hObject, pos, neg)
% use the thresholds in the GUI to update the matrix display
handles = guidata(hObject); % retrieve guidata

if handles.checkbox_use_threshold.Value
    handles.axes.Children.AlphaData = ~(handles.axes.Children.CData <= pos & handles.axes.Children.CData >= neg);
else
    handles.axes.Children.AlphaData = true(size(handles.axes.Children.CData));
end

guidata(hObject, handles); % need to save stuff
end

%--------------------------------------------------------------------------
function UPDATE(hObject,~)
% Entry point for many actions. This is the "main" callback
handles = guidata(hObject); % retrieve guidata

switch hObject.Tag

    case 'slider_pos'
        set_pos(handles, hObject.Value);
        if handles.checkbox_link_pos_neg.Value
            set_neg(handles, hObject.Value);
        end
        threshold_mx(hObject, str2double(handles.edit_pos.String), str2double(handles.edit_neg.String))
        set_highlight(hObject)

    case 'edit_pos'
        set_pos(handles, str2double(hObject.String));
        if handles.checkbox_link_pos_neg.Value
            set_neg(handles, str2double(hObject.String));
        end
        threshold_mx(hObject, str2double(handles.edit_pos.String), str2double(handles.edit_neg.String))
        set_highlight(hObject)

    case 'slider_neg'
        set_neg(handles, hObject.Value);
        if handles.checkbox_link_pos_neg.Value
            set_pos(handles, hObject.Value);
        end
        threshold_mx(hObject, str2double(handles.edit_pos.String), str2double(handles.edit_neg.String))
        set_highlight(hObject)

    case 'edit_neg'
        set_neg(handles, -str2double(hObject.String));
        if handles.checkbox_link_pos_neg.Value
            set_pos(handles, -str2double(hObject.String));
        end
        threshold_mx(hObject, str2double(handles.edit_pos.String), str2double(handles.edit_neg.String))
        set_highlight(hObject)

    case 'checkbox_link_pos_neg'
        if hObject.Value
            set_neg(handles, handles.slider_pos.Value);
        end
        threshold_mx(hObject, str2double(handles.edit_pos.String), str2double(handles.edit_neg.String))
        set_highlight(hObject)

    case 'listbox_id'
        set_mx(hObject)
        if handles.checkbox_use_threshold.Value
            threshold_mx(hObject, str2double(handles.edit_pos.String), str2double(handles.edit_neg.String))
        else
            threshold_mx(hObject, 0, 0)
        end
        set_highlight(hObject)

    case 'listbox_name'
        set_axes(hObject)
        set_mx(hObject)
        threshold_mx(hObject, str2double(handles.edit_pos.String), str2double(handles.edit_neg.String))
        set_roi(hObject)
        handles.highlight_idx = [];

    case 'checkbox_use_threshold'
        set_threshold(hObject)
        set_highlight(hObject)

    case 'slider_volume'
        set_mx(hObject)

    otherwise
        warning(hObject.Tag)
end
drawnow()

guidata(hObject, handles); % store guidata
end

%--------------------------------------------------------------------------
function set_pos(handles, value)
% set positive threshold
if isnan(value) || value < 0 || value > 1
    value = handles.default_threshold;
end
value = round5pct(value);
handles.edit_pos.String = num2str(value);
handles.slider_pos.Value = value;
end

%--------------------------------------------------------------------------
function set_neg(handles, value)
% set negative threshold
if isnan(value) || value < 0 || value > 1
    value = handles.default_threshold;
end
value = round5pct(value);
handles.edit_neg.String = num2str(-value);
handles.slider_neg.Value = value;
end

%--------------------------------------------------------------------------
function out = round5pct(in)
out = round(in * 20) / 20;
end

%--------------------------------------------------------------------------
function [matrix, abbrev_x, abbrev_y, descrip_x, descrip_y] = get_conn_content(hObject)
% retrieve current selected atlas in the GUI
handles = guidata(hObject); % retrieve guidata

connn_result = handles.conn_result(handles.listbox_id.Value).connectivity_content;

if handles.use_network && ~handles.use_dynamic

    label = handles.listbox_name.String{handles.listbox_name.Value};
    if strcmp(label, '<all>')
        matrix    = connn_result.static_connectivity_matrix;
        abbrev_x  = connn_result.ts_table.abbreviation;
        abbrev_y  = connn_result.ts_table.abbreviation;
        descrip_x = connn_result.ts_table.description;
        descrip_y = connn_result.ts_table.description;
    elseif strcmp(label, '_inter_::avg')
        matrix    = reshape([connn_result.static_network_connectivity.avg], size(connn_result.static_network_connectivity));
        abbrev_x  = {connn_result.static_network_data.name};
        abbrev_y  = {connn_result.static_network_data.name};
        descrip_x = {connn_result.static_network_data.name};
        descrip_y = {connn_result.static_network_data.name};
    elseif strcmp(label, '_inter_::var')
        matrix    = reshape([connn_result.static_network_connectivity.var], size(connn_result.static_network_connectivity));
        abbrev_x  = {connn_result.static_network_data.name};
        abbrev_y  = {connn_result.static_network_data.name};
        descrip_x = {connn_result.static_network_data.name};
        descrip_y = {connn_result.static_network_data.name};
    else
        res = strsplit(label, '::');
        network = res{1};
        network_idx = find(strcmp({connn_result.static_network_data.name}, network));
        matrix    = connn_result.static_network_data(network_idx).mx;
        abbrev_x  = connn_result.static_network_data(network_idx).abbreviation;
        abbrev_y  = connn_result.static_network_data(network_idx).abbreviation;
        descrip_x = connn_result.static_network_data(network_idx).description;
        descrip_y = connn_result.static_network_data(network_idx).description;
    end
elseif ~handles.use_network && handles.use_dynamic

    if handles.dynamic_volume.iVolume == 0
        matrix= connn_result.static_connectivity_matrix;
    else
        matrix= connn_result.dynamic_connectivity_matrix(:,:,handles.dynamic_volume.iVolume);
    end
    abbrev_x  = connn_result.ts_table.abbreviation;
    abbrev_y  = connn_result.ts_table.abbreviation;
    descrip_x = connn_result.ts_table.description;
    descrip_y = connn_result.ts_table.description;

elseif handles.use_network && handles.use_dynamic

    label = handles.listbox_name.String{handles.listbox_name.Value};
    if strcmp(label, '<all>')
        if handles.dynamic_volume.iVolume == 0
            matrix= connn_result.static_connectivity_matrix;
        else
            matrix= connn_result.dynamic_connectivity_matrix(:,:,handles.dynamic_volume.iVolume);
        end
        abbrev_x  = connn_result.ts_table.abbreviation;
        abbrev_y  = connn_result.ts_table.abbreviation;
        descrip_x = connn_result.ts_table.description;
        descrip_y = connn_result.ts_table.description;
    elseif strcmp(label, '_inter_::avg')
        if handles.dynamic_volume.iVolume == 0
            matrix    = reshape([connn_result.static_network_connectivity.avg], size(connn_result.static_network_connectivity));
        else
            matrix    = reshape([connn_result.dynamic_network_connectivity(:,:,handles.dynamic_volume.iVolume).avg], size(connn_result.dynamic_network_connectivity(:,:,handles.dynamic_volume.iVolume)));
        end
        abbrev_x  = {connn_result.static_network_data.name};
        abbrev_y  = {connn_result.static_network_data.name};
        descrip_x = {connn_result.static_network_data.name};
        descrip_y = {connn_result.static_network_data.name};
    elseif strcmp(label, '_inter_::var')
        if handles.dynamic_volume.iVolume == 0
            matrix    = reshape([connn_result.static_network_connectivity.var], size(connn_result.static_network_connectivity));
        else
            matrix    = reshape([connn_result.dynamic_network_connectivity(:,:,handles.dynamic_volume.iVolume).var], size(connn_result.dynamic_network_connectivity(:,:,handles.dynamic_volume.iVolume)));
        end
        abbrev_x  = {connn_result.static_network_data.name};
        abbrev_y  = {connn_result.static_network_data.name};
        descrip_x = {connn_result.static_network_data.name};
        descrip_y = {connn_result.static_network_data.name};
    else
        res = strsplit(label, '::');
        network = res{1};
        network_idx = find(strcmp({connn_result.static_network_data.name}, network));
        if handles.dynamic_volume.iVolume == 0
            matrix= connn_result.static_network_data(network_idx).mx;
        else
            matrix= connn_result.dynamic_network_data(network_idx,handles.dynamic_volume.iVolume).mx;
        end
        abbrev_x  = connn_result.static_network_data(network_idx).abbreviation;
        abbrev_y  = connn_result.static_network_data(network_idx).abbreviation;
        descrip_x = connn_result.static_network_data(network_idx).description;
        descrip_y = connn_result.static_network_data(network_idx).description;
    end

else

    matrix    = connn_result.static_connectivity_matrix;
    abbrev_x  = connn_result.ts_table.abbreviation;
    abbrev_y  = connn_result.ts_table.abbreviation;
    descrip_x = connn_result.ts_table.description;
    descrip_y = connn_result.ts_table.description;
end

guidata(hObject, handles); % need to save stuff
end

%--------------------------------------------------------------------------
function set_threshold(hObject)
% callback to manage the threshold checkbox behaviour
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

%--------------------------------------------------------------------------
function print_click(hObject, eventData)
% callback used when click on :
% - a pixel in the Image
% - a cell in the highlight table
handles = guidata(hObject); % retrieve guidata

% fetch data point
switch class(eventData)
    case 'matlab.graphics.eventdata.Hit'
        coord = round(eventData.IntersectionPoint(1:2));
    case 'matlab.ui.eventdata.CellSelectionChangeData'
        if isempty(eventData.Indices)
            return
        end
        coord = [handles.highlight_idx eventData.Indices(2)];
end
[matrix, abbrev_x, abbrev_y, descrip_x, descrip_y] = get_conn_content(hObject);

% prepare infos
R = matrix(coord(1), coord(2));
roi_1_abbr = abbrev_x  {coord(1)};
roi_2_abbr = abbrev_y  {coord(2)};
roi_1_name = descrip_x {coord(1)};
roi_2_name = descrip_y {coord(2)};

fprintf('R = %+1.3f --- %-11s / %-11s --- %s / %s \n', R, roi_1_abbr, roi_2_abbr, roi_1_name, roi_2_name)

guidata(hObject, handles); % need to save stuff
end

%--------------------------------------------------------------------------
function HIGHLIGHT(hObject, eventData)
% callback to update the pearson R in the highlight table
handles = guidata(hObject); % retrieve guidata

if isempty(eventData.Indices)
    handles.uitable_highlight.Data = [];
    handles.uitable_highlight.ColumnName = [];
    return
end

idx = eventData.Indices(1);
handles.highlight_idx = idx; % need to save this variable, since the selection on the uitable is not accessible

R_num = handles.axes.Children.CData(idx,:);
if handles.checkbox_use_threshold.Value
    R_mask = handles.axes.Children.AlphaData(idx,:);
else
    R_mask = true(size(R_num));
end
rgb_map_num = colormap(handles.axes);
R_rgp_num = pearson2color(R_num, rgb_map_num);
R_html = cell(size(R_num));
for i = 1 : numel(R_html)
    if R_mask(i)
        R_html{i} = color2html(R_rgp_num(i,:), R_num(i));
    else
        R_html{i} = '';
    end
end

handles.uitable_highlight.Data = R_html;
handles.uitable_highlight.ColumnName = handles.axes.XTickLabel;

guidata(hObject, handles); % need to save stuff
end

%--------------------------------------------------------------------------
function set_highlight(hObject)
% wrapper function re-call a callback
handles = guidata(hObject); % retrieve guidata
if handles.highlight_idx
    evt = struct;
    evt.Indices = handles.highlight_idx;
    HIGHLIGHT(hObject, evt);
end
guidata(hObject, handles); % need to save stuff
end

%--------------------------------------------------------------------------
function color = pearson2color(pearson, colormap)
% peearson : vector of R values, from -1 to +1
% colormap : nx3 rgb values, from 0 to 1
% color    : corlor triplet for each pearson R
color = interp1(linspace(-1,+1,size(colormap,1)), colormap, pearson);
end

%--------------------------------------------------------------------------
function str = color2html( rgb, value )
% Transform [R G B] = [0-1 0-1 0-1] into hexadecimal #rrggbb ,
% then add it into an html code, with the corresponding value

s = cellstr(dec2hex(round(rgb*255)))';

color = sprintf('#%s%s%s',s{:});

str = ['<html>< <table bgcolor=',color,'>',num2str(value,'%+1.3f'),'</table></html>'];

end % function
