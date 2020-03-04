function spm2wfu_pickatlas()
% When SPM result UI is opened, copy the current coordinates into WFU PickAltas

% Get spm_result_ui coordinates
xyz = spm_results_ui('GetCoords');

% Get wfu_pickatlas handles
Fwfu = wfu_findFigure('WFU_PickAtlas');
handles = guidata(Fwfu(1));

% Set coordinates in wfu GUI
set(handles.txtMniX,'string',num2str(xyz(1)));
set(handles.txtMniY,'string',num2str(xyz(2)));
set(handles.txtMniZ,'string',num2str(xyz(3)));

% Call wfu routine to update the GUI
wfu_pickatlas('cmdGo2_Callback',[],[],handles)

end % function
