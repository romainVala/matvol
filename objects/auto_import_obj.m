function [ examArray, error_log ] = auto_import_obj( baseDir, par )
%AUTO_IMPORT_OBJ will analyse recursively **baseDir** to build objects
%according to the dirs found and json content (sequence name)
%
% Syntax : [ examArray ] = auto_import_obj( baseDir, par )
%
% IMPORTANT note : this funcion assumes the the series alphabetical order
% is the the same as the sequence order For exemple, if you have
% S25_gre_field_map and S26_gre_field_map_phase , they come from the SAME
% sequence even if the magnitude and phase diff arrive in different
% directories.
%
%
% See also exam exam2bids
%

if nargin == 0
    help(mfilename)
    return
end


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

assert( ischar(baseDir)          , 'baseDir must be a char'          )
assert(  exist(baseDir,'dir')==7 , 'Not a valid dir : %s'  , baseDir )


%% defpar

defpar.exam_regex  = '.*';
defpar.serie_regex = '.*';

% BIDS names :

% anat
defpar.anat_regex_volume = '^s.*nii';
defpar.anat_tag_volume   = 's';
defpar.anat_tag_json     = 'j';

% dwi
defpar.dwi_regex_volume  = '^(f|s).*nii'; % f : multiple volumes (99% of cases) // s : only one volume (1% of cases, but it may happen)
defpar.dwi_tag_volume    = 'f';
defpar.dwi_tag_json      = 'j';

% func
defpar.func_regex_volume = '^(f|s).*nii'; % f : multiple volumes (99% of cases) // s : only one volume (1% of cases, but it may happen)
defpar.func_tag_volume   = 'f';
defpar.func_tag_json     = 'j';

% fmap
defpar.fmap_regex_volume = '^s.*nii';
defpar.fmap_tag_volume   = 's';
defpar.fmap_tag_json     = 'j';

% swi
defpar.swi_regex_volume = '^s.*nii';
defpar.swi_tag_volume   = 's';
defpar.swi_tag_json     = 'j';

%--------------------------------------------------------------------------

defpar.sge      = 0;
defpar.jobname  = 'matvol_auto_import_obj';
defpar.walltime = '00:30:00';
defpar.pct      = 0;

defpar.redo     = 0;
defpar.run      = 1;
defpar.display  = 0;
defpar.verbose  = 1;

par = complet_struct(par,defpar);


%% Some parameters

% 1 : sequence name contains this
% 2 : BIDS modality
% 3 : volume regex
% 4 : volume tag
% 5 : json   tag
SequenceCategory = {
    'tfl'                'anat'  par.anat_regex_volume  par.anat_tag_volume  par.anat_tag_json % 3DT1 mprage & mp2rage
    'mp2rage'            'anat'  par.anat_regex_volume  par.anat_tag_volume  par.anat_tag_json % some mp2rage WIP
    'tse_vfl'            'anat'  par.anat_regex_volume  par.anat_tag_volume  par.anat_tag_json % 3DT2 space & 3DFLAIR space_ir
    'diff'               'dwi'   par. dwi_regex_volume  par. dwi_tag_volume  par. dwi_tag_json % diffusion
    '(bold)|(pace)'      'func'  par.func_regex_volume  par.func_tag_volume  par.func_tag_json % bold fmri
    'gre_field_mapping'  'fmap'  par.fmap_regex_volume  par.fmap_tag_volume  par.fmap_tag_json % gre_field_mapping
    '^gre$'              'swi'   par. swi_regex_volume  par. swi_tag_volume  par. swi_tag_json % gre SWI
    '^gre$'              'anat'  par.anat_regex_volume  par.anat_tag_volume  par.anat_tag_json % gre FLASH
    '^tse$'              'anat'  par.anat_regex_volume  par.anat_tag_volume  par.anat_tag_json % tse, usually AX_2DT1 or AX_2DT2
    'ep2d_se'            'anat'  par.func_regex_volume  par.anat_tag_volume  par.anat_tag_json % SpinEcho EPI
    };


to_discard = {'haste'};

for d = 1 : length(to_discard)
    SequenceCategory(end+1,[1 2]) = [to_discard(d) {'discard'}]; %#ok<AGROW>
end


%% Fetch exam, fill series, volumes ans jsons

examArray = exam(baseDir, par.exam_regex); % add all subdir as @exam objects
error_log = cell(size(examArray));

for ex = 1 : numel(examArray)
    
    % Fetch all subdir
    subdir = gdir(examArray(ex).path, par.serie_regex);
    if isempty(subdir)
        continue
    end
    
    if par.verbose > 0
        error_log = log(error_log,ex,sprintf( '[%s] : Working on %d/%d : %s \n', mfilename, ex, numel(examArray) , examArray(ex).path ), 1);
    end
    
    %======================================================================
    
    % Fetch all json files
    json = gfile(subdir,'json$',struct('verbose',0));
    if isempty(json)
        exam_SequenceData = cell(0);
        hdr = cell(0);
        continue
    end    
    
    % Extract all parameters
    param_struct = get_sequence_param_from_json( json, 1 );
    if isstruct(param_struct), param_struct = {param_struct}; end % only happens when there is only 1 serie
    hdr_str = fieldnames(param_struct{1});
    hdr = cell2struct(num2cell(1:length(hdr_str)),hdr_str,2);
    
    % Transform the structure into a cell, easier to display and manipulate in that case
    exam_SequenceData = cell(size(param_struct,1),length(hdr_str));
    for p = 1 : numel(param_struct)
        exam_SequenceData(p,:) = struct2cell(param_struct{p}(1))';
    end
    
    % Add one last column
    exam_SequenceData(:,end+1) = {''}; %#ok<AGROW>
    
    %======================================================================
    
    % Try to fit the sequence name to the category
    for idx = 1 : size(SequenceCategory, 1)
        
        flag_add = 0;
        
        where = find( ~cellfun( @isempty , regexp(exam_SequenceData(:,hdr.SequenceFileName),SequenceCategory{idx,1}) ) );
        if isempty(where)
            continue
        end
        
        [~, upper_dir_name] = get_parent_path(subdir(where)); % extract dir name
        
        %%%%%%%%%%%%%%%%%
        % Special cases %
        %%%%%%%%%%%%%%%%%
        
        %------------------------------------------------------------------
        % func
        %------------------------------------------------------------------
        if strcmp(SequenceCategory{idx,2},'func')
            
            type = exam_SequenceData(where,hdr.ImageType        ); % mag or phase
            name = exam_SequenceData(where,hdr.SeriesDescription); % serie name
            
            type_SBRef = ~cellfun(@isempty,regexp(name,'SBRef$'));
            
            type_M = strcmp(type,'M');
            type_P = strcmp(type,'P');
            
            type_M = logical( type_M - type_SBRef );
            
            if any(type_SBRef), examArray(ex).addSerie(upper_dir_name(type_SBRef), 'func_sbref'), exam_SequenceData(where(type_SBRef),end) = {'func_sbref'}; flag_add = 1; end
            if any(type_M)    , examArray(ex).addSerie(upper_dir_name(type_M    ), 'func_mag'  ), exam_SequenceData(where(type_M    ),end) = {'func_mag'  }; flag_add = 1; end
            if any(type_P)    , examArray(ex).addSerie(upper_dir_name(type_P    ), 'func_phase'), exam_SequenceData(where(type_P    ),end) = {'func_phase'}; flag_add = 1; end
            
            %--------------------------------------------------------------
            % anat
            %--------------------------------------------------------------
        elseif strcmp(SequenceCategory{idx,2},'anat')
            
            subcategory = {'_INV1','_INV2','_UNI_Images','_T1_Images'}; % mp2rage
            for sc = 1 : length(subcategory)
                
                where_sc = ~cellfun(@isempty, regexp(upper_dir_name,subcategory{sc})); % do we find this subcategory ?
                if any(where_sc) % yes
                    examArray(ex).addSerie(upper_dir_name(where_sc), strcat('anat', subcategory{sc})  )% add them
                    flag_add = 1;
                    exam_SequenceData(where(where_sc),end) = {strcat('anat', subcategory{sc})};
                    upper_dir_name(where_sc) = []; % remove them from the list
                    where(where_sc) = [];
                end
                
            end
            
            if ~isempty(upper_dir_name) % if the list is not empty, it means some non-mp2rage sereies remains, such as classic mprage, or else...
                
                SequenceFileName = exam_SequenceData(where,hdr.SequenceFileName);
                SequenceName     = exam_SequenceData(where,hdr.SequenceName);
                
                tfl = strcmp(SequenceFileName, 'tfl');
                if any( tfl ), examArray(ex).addSerie(upper_dir_name( tfl ),'anat_T1w'), exam_SequenceData(where( tfl ),end) = {'anat_T1w'}; flag_add = 1; end
                
                tse_vfl = strcmp(SequenceFileName, 'tse_vfl');
                if any( tse_vfl )
                    spcir = ~isemptyCELL(strfind(SequenceName, 'spcir')); if any( spcir ), examArray(ex).addSerie(upper_dir_name( spcir ),'anat_FLAIR'), exam_SequenceData(where( spcir ),end) = {'anat_FLAIR'}; flag_add = 1; end
                    SequenceName(spcir) = {''}; % delete 'spcir', because regex('spcir') & regex('spc') have the same result...
                    spc   = ~isemptyCELL(strfind(SequenceName, 'spc'  )); if any( spc   ), examArray(ex).addSerie(upper_dir_name( spc   ),'anat_T2w'  ), exam_SequenceData(where( spc   ),end) = {'anat_T2w'  }; flag_add = 1; end
                end
                
                gre = strcmp(SequenceFileName, 'gre');
                if any( gre )
                    
                    fl = ~isemptyCELL(strfind(SequenceName, 'fl'));
                    
                    % Remove the localizer
                    SeriesDescription = exam_SequenceData(where,hdr.SeriesDescription);
                    loca              = ~isemptyCELL(strfind(lower(SeriesDescription), 'loca'));
                    if any( loca ), exam_SequenceData(where( loca ),end) = {'discard'}; end % don't add the serie, just discard it
                    fl                = logical(fl - loca);
                    
                    type   = exam_SequenceData(where,hdr.ImageType); % mag or phase
                    
                    type_M = strcmp(type,'M'); fl_mag = fl & type_M;
                    type_P = strcmp(type,'P'); fl_pha = fl & type_P;
                    
                    if any( fl_mag ), examArray(ex).addSerie(upper_dir_name( fl_mag ), 'anat_FLASH_mag'  ), exam_SequenceData(where( fl_mag ),end) = {'anat_FLASH_mag'  }; flag_add = 1; end
                    if any( fl_pha ), examArray(ex).addSerie(upper_dir_name( fl_pha ), 'anat_FLASH_phase'), exam_SequenceData(where( fl_pha ),end) = {'anat_FLASH_phase'}; flag_add = 1; end
                    
                end
                
                tse = strcmp(SequenceFileName, 'tse');
                if any( tse ), examArray(ex).addSerie(upper_dir_name( tse ),'anat_TSE'), exam_SequenceData(where( tse ),end) = {'anat_TSE'}; flag_add = 1; end
                
                ep2d_se = ~isemptyCELL(strfind(SequenceFileName, 'ep2d_se'));
                if any( ep2d_se ), examArray(ex).addSerie(upper_dir_name( ep2d_se ),'anat_ep2d_se'), exam_SequenceData(where( ep2d_se ),end) = {'anat_ep2d_se'}; flag_add = 1; end
                
            end
            
            %--------------------------------------------------------------
            % fmap
            %--------------------------------------------------------------
        elseif strcmp(SequenceCategory{idx,2},'fmap')
            
            type = exam_SequenceData(where,hdr.ImageType); % mag or phase
            
            type_M = strcmp(type,'M');
            type_P = strcmp(type,'P');
            
            if any(type_M), examArray(ex).addSerie(upper_dir_name(type_M), 'fmap_mag'  ), exam_SequenceData(where(type_M),end) = {'fmap_mag'  }; flag_add = 1; end
            if any(type_P), examArray(ex).addSerie(upper_dir_name(type_P), 'fmap_phase'), exam_SequenceData(where(type_P),end) = {'fmap_phase'}; flag_add = 1; end
            
            
            %--------------------------------------------------------------
            % swi
            %--------------------------------------------------------------
        elseif strcmp(SequenceCategory{idx,2},'swi')
            
            subcategory = {'Mag_Images','Pha_Images','mIP_Images','SWI_Images'}; % swi
            
            for sc = 1 : length(subcategory)
                
                where_sc = ~cellfun(@isempty, regexp(upper_dir_name,subcategory{sc})); % do we find this subcategory ?
                
                if any(where_sc) % yes
                    examArray(ex).addSerie(upper_dir_name(where_sc), strcat('swi', '_', subcategory{sc}(1:end-1)) )% add them
                    flag_add = 1;
                    exam_SequenceData(where(where_sc),end) =       { strcat('swi', '_', subcategory{sc}(1:end-1)) };
                    upper_dir_name(where_sc) = []; % remove them from the list
                    where(where_sc) = [];
                end
                
            end
            
            if ~isempty(upper_dir_name) % if the list is not empty, it means some non-mp2rage sereies remains, such as classic mprage, or else...
                
                SequenceName = exam_SequenceData(where,hdr.SequenceName);
                
                for f = 1 : length(SequenceName)
                    
                    if strfind(SequenceName{f},'fl')
                        % ok its a classic gre-flash, it will be analyzed as 'anat'
                    else
                        str = warning('we have a problem with what i suppose is a SWI [ %s ]', upper_dir_name{f});
                        error_log = log(error_log,ex,str,0);
                    end
                    
                end % SequenceFileName
                
            end
            
            % discard -----------------------------------------------------
        elseif strcmp(SequenceCategory{idx,2},'discard')
            exam_SequenceData(where,end) = SequenceCategory(idx,2);
            continue
        else
            examArray(ex).addSerie(upper_dir_name,SequenceCategory{idx,2}) % add the @serie, with BIDS tag
            flag_add = 1;
            exam_SequenceData(where,end) = SequenceCategory(idx,2);
        end
        
        % Add volume & json
        if flag_add
            examArray(ex).getSerie(SequenceCategory{idx,2}).addVolume(SequenceCategory{idx,3},SequenceCategory{idx,4});
            examArray(ex).getSerie(SequenceCategory{idx,2}).addJson('json$',SequenceCategory{idx,5});
        end
        
    end % categ
    
    % Add sequence data to each serie, or write a line in error_log
    for ser = 1 : numel(subdir)
        
        % Add sequence data
        if ~isempty( exam_SequenceData{ser,end} )
            
            if strcmp(exam_SequenceData{ser,end},'discard')
                % pass
            else
                
                Serie_obj      = examArray(ex).getSerie(exam_SequenceData{ser,end});
                if ~isempty( Serie_obj )
                    SeqData_struct = param_struct( ~cellfun(@isempty, regexp(exam_SequenceData(:,end),exam_SequenceData{ser,end}) ) );
                    for s = 1 : length(Serie_obj)
                        Serie_obj(s).sequence = SeqData_struct{s};
                    end
                else
                    str = warning('[%s] : we have a problem, I can''t find any serie for [ %s ]', mfilename, exam_SequenceData{ser,end});
                    error_log = log(error_log,ex,str,0);
                end
                
            end
            
        else % Error log
            in = exam_SequenceData(ser,:);
            out=cellfun(@num2str,in,'UniformOutput',0); % transform num to str
            str = sprintf(['Unrecognized Sequence : %s with this parameters = [ ' repmat('%s ', [1 numel(out)]) ']'], subdir{ser}, out{:});
            error_log = log(error_log,ex,str);
        end
        
    end % ser
    
    if par.verbose > 2
        fprintf('SequenceName found : \n')
        disp(exam_SequenceData)
        fprintf('\n')
    end
    
end % ex


%% Post operations

examArray(ex).other.SequenceData     = exam_SequenceData;
examArray(ex).other.SequenceData_hdr = hdr;

% Reorder series to they are in alphabetical==time order, according to their name S01, S02, S03, ...
examArray.reorderSeries('name');


end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = isemptyCELL( input )

result = cellfun(@isempty, input);

end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function error_log = log(error_log,ex,str,print)

if nargin < 4
    print = 0;
end

if print
    fprintf('%s',str)
end

if isempty(error_log{ex})
    error_log{ex} = str;
else
    error_log{ex} = [error_log{ex} str sprintf('\n')];
end

end % function
