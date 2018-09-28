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
% See also exam
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

fetch.SequenceFileName  = 'CsaSeries.MrPhoenixProtocol.tSequenceFileName';
fetch.SequenceName      = 'SequenceName';
fetch.ImageType         = 'ImageType';
fetch.SeriesDescription = 'SeriesDescription';
% fetch.SeriesNumber      = 'SeriesNumber';
fetch.SequenceID        = 'CsaSeries.MrPhoenixProtocol.lSequenceID';
fetch.B_value           = 'CsaImage.B_value';
fetch.B_vect            = 'CsaImage.DiffusionGradientDirection';
fetch.ProtocolName      = 'CsaSeries.MrPhoenixProtocol.tProtocolName';

% 1 : sequence name contains this
% 2 : BIDS modality
% 3 : volume regex
% 4 : volume tag
% 5 : json   tag
SequenceCategory = {
    'tfl'                'anat'  par.anat_regex_volume  par.anat_tag_volume  par.anat_tag_json % 3DT1 mprage & mp2rage
    'tse_vfl'            'anat'  par.anat_regex_volume  par.anat_tag_volume  par.anat_tag_json % 3DT2 space & 3DFLAIR space_ir
    'diff'               'dwi'   par. dwi_regex_volume  par. dwi_tag_volume  par. dwi_tag_json % diffusion
    '(bold)|(pace)'      'func'  par.func_regex_volume  par.func_tag_volume  par.func_tag_json % bold fmri
    'gre_field_mapping'  'fmap'  par.fmap_regex_volume  par.fmap_tag_volume  par.fmap_tag_json % gre_field_mapping
    '^gre$'              'swi'   par. swi_regex_volume  par. swi_tag_volume  par. swi_tag_json % gre SWI
    '^gre$'              'anat'  par.anat_regex_volume  par.anat_tag_volume  par.anat_tag_json % gre FLASH
    '^tse$'              'anat'  par.anat_regex_volume  par.anat_tag_volume  par.anat_tag_json % tse, usually AX_2DT1 or AX_2DT2
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
    
    exam_SequenceData = cell(numel(subdir),9); % container, pre-allocation
    
    if par.verbose > 0
        error_log = log(error_log,ex,sprintf( '[%s] : Working on %d/%d : %s \n', mfilename, ex, numel(examArray) , examArray(ex).path ), 1);
    end
    
    %======================================================================
    
    % For all subdir found, try to recognize if there is a json,
    % and then try to extract the sequence name i nhe json
    for ser = 1 : numel(subdir)
        
        % Fetch all json files
        json = gfile(subdir{ser},'json$',struct('verbose',0));
        if isempty(json)
            continue
        end
        
        json = json{1}; % in case of multiple volumes, only keep the first file
        content = get_file_content_as_char(deblank(json(1,:)));
        
        % Fetch the line content ------------------------------------------
        
        SequenceFileName = get_field_one(content, fetch.SequenceFileName);
        if isempty(SequenceFileName)
            continue
        end
        split = regexp(SequenceFileName,'\\\\','split'); % example : "%SiemensSeq%\\ep2d_bold"
        exam_SequenceData{ser,1} = split{end};
        
        SequenceName = get_field_one(content, fetch.SequenceName);
        exam_SequenceData{ser,2} = SequenceName;
        
        ImageType  = get_field_mul(content, fetch.ImageType);
        MAGorPHASE = ImageType{3};
        exam_SequenceData{ser,3} = MAGorPHASE;
        
        SequenceID  = get_field_one(content, fetch.SequenceID);
        exam_SequenceData{ser,4} = str2double(SequenceID);
        
        SeriesDescription = get_field_one(content, fetch.SeriesDescription);
        exam_SequenceData{ser,5} = SeriesDescription;
        
        if regexp(split{end}, 'diff')
            
            B_value = get_field_mul(content, fetch.B_value);
            exam_SequenceData{ser,6} = str2double(B_value)';
            
            B_vect  = get_field_mul_vect(content, fetch.B_vect);
            exam_SequenceData{ser,7} = B_vect;
            
        end
        
        ProtocolName = get_field_one(content, fetch.ProtocolName);
        exam_SequenceData{ser,8} = ProtocolName;
        
    end % ser
    
    examArray(ex).other.SequenceData = exam_SequenceData;
    
    if par.verbose > 2
        fprintf('SequenceName found : \n')
        disp(exam_SequenceData)
        fprintf('\n')
    end
    
    
    %======================================================================
    
    % Try to fit the sequence name to the category
    for idx = 1 : size(SequenceCategory, 1)
        
        flag_add = 0;
        
        where = find( ~cellfun( @isempty , regexp(exam_SequenceData(:,1),SequenceCategory{idx,1}) ) );
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
            
            type = exam_SequenceData(where,3); % mag or phase
            name = exam_SequenceData(where,5); % serie name
            
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
                
                SequenceFileName = exam_SequenceData(where,1);
                SequenceName     = exam_SequenceData(where,2);
                
                tfl = strcmp(SequenceFileName, 'tfl');
                if any( tfl ), examArray(ex).addSerie(upper_dir_name( tfl ),'anat_T1w'), exam_SequenceData(where( tfl ),end) = {'anat_T1w'}; flag_add = 1; end
                
                tse_vfl = strcmp(SequenceFileName, 'tse_vfl');
                if any( tse_vfl )
                    spcir = ~isemptyCELL(strfind(SequenceName, 'spcir_')); if any( spcir ), examArray(ex).addSerie(upper_dir_name( spcir ),'anat_FLAIR'), exam_SequenceData(where( spcir ),end) = {'anat_FLAIR'}; flag_add = 1; end
                    spc   = ~isemptyCELL(strfind(SequenceName, 'spc_'  )); if any( spc   ), examArray(ex).addSerie(upper_dir_name( spc   ),'anat_T2w'  ), exam_SequenceData(where( spc   ),end) = {'anat_T2w'  }; flag_add = 1; end
                end
                
                gre = strcmp(SequenceFileName, 'gre');
                if any( gre )
                    
                    fl = ~isemptyCELL(strfind(SequenceName, 'fl'));
                    
                    type   = exam_SequenceData(where,3); % mag or phase
                    
                    type_M = strcmp(type,'M'); fl_mag = fl & type_M;
                    type_P = strcmp(type,'P'); fl_pha = fl & type_P;
                    
                    if any( fl_mag ), examArray(ex).addSerie(upper_dir_name( fl_mag ), 'anat_FLASH_mag'  ), exam_SequenceData(where( fl_mag ),end) = {'anat_FLASH_mag'  }; flag_add = 1; end
                    if any( fl_pha ), examArray(ex).addSerie(upper_dir_name( fl_pha ), 'anat_FLASH_phase'), exam_SequenceData(where( fl_pha ),end) = {'anat_FLASH_phase'}; flag_add = 1; end
                    
                end
                
                tse = strcmp(SequenceFileName, 'tse');
                if any( tse ), examArray(ex).addSerie(upper_dir_name( tse ),'anat_T1w'), exam_SequenceData(where( tse ),end) = {'anat_T1w'}; flag_add = 1; end
                
            end
            
            %--------------------------------------------------------------
            % fmap
            %--------------------------------------------------------------
        elseif strcmp(SequenceCategory{idx,2},'fmap')
            
            type = exam_SequenceData(where,3); % mag or phase
            
            type_M = strcmp(type,'M');
            type_P = strcmp(type,'P');
            
            if any(type_M), examArray(ex).addSerie(upper_dir_name(type_M), 'fmap_mag'  ), exam_SequenceData(where(type_M),end) = {'fmap_mag'  }; flag_add = 1; end
            if any(type_P), examArray(ex).addSerie(upper_dir_name(type_P), 'fmap_phase'), exam_SequenceData(where(type_P),end) = {'fmap_phase'}; flag_add = 1; end
            
            
            %--------------------------------------------------------------
            % swi
            %--------------------------------------------------------------
        elseif strcmp(SequenceCategory{idx,2},'swi')
            
            subcategory = {'Mag_','Pha_','mIP_','SWI_'}; % swi
            
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
                
                SequenceName     = exam_SequenceData(where,2);
                
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
                    SeqData_struct = cell2struct( exam_SequenceData( ~cellfun(@isempty,regexp(exam_SequenceData(:,end),exam_SequenceData{ser,end})) , 1:end-1) , fieldnames(fetch) , 2 );
                    for s = 1 : length(Serie_obj)
                        Serie_obj(s).other.SequenceData = SeqData_struct(s);
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
    
end % ex


%% Post operations

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = get_field_one(content, regex)

% Fetch the line content
start = regexp(content           , regex, 'once');
stop  = regexp(content(start:end), ','  , 'once');
line = content(start:start+stop);
token = regexp(line, ': (.*),','tokens'); % extract the value from the line
if isempty(token)
    result = [];
else
    res = token{1}{1};
    if strcmp(res(1),'"')
        result = res(2:end-1); % remove " @ beguining and end
    else
        result = res;
    end
end

end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = get_field_mul(content, regex)

% Fetch the line content
start = regexp(content           , regex, 'once');
stop  = regexp(content(start:end), ']'  , 'once');
line = content(start:start+stop);

if strfind(line(length(regex):end),'Csa') % in cas of single value, and not multiple ( such as signle B0 value for diff )
    stop  = regexp(content(start:end), ','  , 'once');
    line = content(start:start+stop);
end

token = regexp(line, ': (.*),','tokens'); % extract the value from the line
if isempty(token)
    result = [];
else
    res    = token{1}{1};
    VECT_cell_raw = strsplit(res,'\n')';
    if length(VECT_cell_raw)>1
        VECT_cell = VECT_cell_raw(2:end-1);
    else
        VECT_cell = VECT_cell_raw;
    end
    VECT_cell = strrep(VECT_cell,',','');
    VECT_cell = strrep(VECT_cell,' ','');
    result    = strrep(VECT_cell,'"','');
end

end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = get_field_mul_vect(content, regex)

% with Siemens product, [0,0,0] vectors are written as 'null'
% but 'null' is dirty, i prefrer real null vectors [0,0,0]
content_new = regexprep(content,'null',sprintf('[\n 0,\n 0,\n 0 \n]'));

% Fetch the line content
start = regexp(content_new           , regex, 'once');
stop  = regexp(content_new(start:end), '\]\s+\]'  , 'once');
line = content_new(start:start+stop+1);

if strfind(line(length(regex):end),'Csa') % in cas of single value, and not multiple ( such as signle B0 value for diff )
    stop  = regexp(content(start:end), '\],\s+"'  , 'once');
    line = content(start:start+stop);
end

VECT_cell_raw = strsplit(line,'\n')';

if length(VECT_cell_raw)>1
    VECT_cell = VECT_cell_raw(2:end-1);
else
    VECT_cell = VECT_cell_raw;
end
VECT_cell = strrep(VECT_cell,',','');
VECT_cell = strrep(VECT_cell,' ','');
VECT_cell = strrep(VECT_cell,'[','');
VECT_cell = strrep(VECT_cell,']','');
VECT_cell = VECT_cell(~cellfun(@isempty,VECT_cell));

v = str2double(VECT_cell);
result = reshape(v,[3 numel(v)/3]);

end % function
