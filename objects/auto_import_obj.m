function [ examArray ] = auto_import_obj( baseDir, par )
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
fetch.SeriesNumber      = 'SeriesNumber';
fetch.SequenceID        = 'CsaSeries.MrPhoenixProtocol.lSequenceID';

% 1 : sequence name contains this
% 2 : BIDS modality
% 3 : volume regex
% 4 : volume tag
% 5 : json   tag
SequenceCategory = {
    'tfl'               'anat' par.anat_regex_volume par.anat_tag_volume par.anat_tag_json
    'diff'              'dwi'  par. dwi_regex_volume par. dwi_tag_volume par. dwi_tag_json
    '(bold)|(pace)'     'func' par.func_regex_volume par.func_tag_volume par.func_tag_json
    'gre_field_mapping' 'fmap' par.fmap_regex_volume par.fmap_tag_volume par.fmap_tag_json
    };


%% Fetch exam, fill series, volumes ans jsons

examArray = exam(baseDir, par.exam_regex); % add all subdir as @exam objects

for ex = 1 : numel(examArray)
    
    % Fetch all subdir
    subdir = gdir(examArray(ex).path, par.serie_regex);
    if isempty(subdir)
        continue
    end
    
    exam_SequenceData = cell(numel(subdir),5); % container, pre-allocation
    
    if par.verbose > 0
        fprintf( '[%s] : Working on %d/%d : %s \n', mfilename, ex, numel(examArray) , examArray(ex).path )
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
        
    end % ser
    
    if par.verbose > 1
        fprintf('SequenceName found : \n')
        disp(exam_SequenceData)
        fprintf('\n')
    end
    
    %======================================================================
    
    %     [~,~,SeqIDX] = unique(cell2mat(exam_SequenceData(:,4)));
    
    % Try to fit the sequence name to the category
    for idx = 1 : size(SequenceCategory, 1)
        
        where = find( ~cellfun( @isempty , regexp(exam_SequenceData(:,1),SequenceCategory{idx,1}) ) );
        %         where_SeqIDX = SeqIDX(where);
        %         where_SeqIDX = cellstr(num2str(where_SeqIDX,'%.3d'));
        if isempty(where)
            continue
        end
        
        [~, upper_dir_name] = get_parent_path(subdir(where)); % extract dir name
        
        %%%%%%%%%%%%%%%%%
        % Special cases %
        %%%%%%%%%%%%%%%%%
        
        % func ------------------------------------------------------------
        if strcmp(SequenceCategory{idx,2},'func')
            
            type = exam_SequenceData(where,3); % mag or phase
            name = exam_SequenceData(where,5); % serie name
            
            type_SBRef = ~cellfun(@isempty,regexp(name,'SBRef$'));
            
            type_M = strcmp(type,'M');
            type_P = strcmp(type,'P');
            
            type_M = logical( type_M - type_SBRef );
            
            %             if any(type_M), examArray(ex).addSerie(upper_dir_name(type_M), strcat('func_', where_SeqIDX(type_M), '_mag'  )), end
            %             if any(type_P), examArray(ex).addSerie(upper_dir_name(type_P), strcat('func_', where_SeqIDX(type_P), '_phase')), end
            if any(type_SBRef), examArray(ex).addSerie(upper_dir_name(type_SBRef), 'func_sbref'), end
            if any(type_M)    , examArray(ex).addSerie(upper_dir_name(type_M    ), 'func_mag'  ), end
            if any(type_P)    , examArray(ex).addSerie(upper_dir_name(type_P    ), 'func_phase'), end
            
            % anat --------------------------------------------------------
        elseif strcmp(SequenceCategory{idx,2},'anat')
            
            subcategory = {'_INV1','_INV2','_UNI_Images','_T1_Images'}; % mp2rage
            for sc = 1 : length(subcategory)
                
                where_sc = ~cellfun(@isempty, regexp(upper_dir_name,subcategory{sc})); % do we find this subcategory ?
                if any(where_sc) % yes
                    %                     examArray(ex).addSerie(upper_dir_name(where_sc), strcat('anat_', where_SeqIDX(where_sc), subcategory{sc})  )% add them
                    examArray(ex).addSerie(upper_dir_name(where_sc), strcat('anat', subcategory{sc})  )% add them
                    upper_dir_name(where_sc) = []; % remove them from the list
                end
                
            end
            
            if ~isempty(upper_dir_name) % if the list is not empty, it means some non-mp2rage sereies remains, such as classic mprage, or else...
                examArray(ex).addSerie(upper_dir_name,'anat')
            end
            
            % fmap --------------------------------------------------------
        elseif strcmp(SequenceCategory{idx,2},'fmap')
            
            type = exam_SequenceData(where,3); % mag or phase
            
            type_M = strcmp(type,'M');
            type_P = strcmp(type,'P');
            %             if any(type_M), examArray(ex).addSerie(upper_dir_name(type_M), strcat('fmap_', where_SeqIDX(type_M), '_mag'  )), end
            %             if any(type_P), examArray(ex).addSerie(upper_dir_name(type_P), strcat('fmap_', where_SeqIDX(type_P), '_phase')), end
            if any(type_M), examArray(ex).addSerie(upper_dir_name(type_M), 'fmap_mag'  ), end
            if any(type_P), examArray(ex).addSerie(upper_dir_name(type_P), 'fmap_phase'), end
            
        else
            examArray(ex).addSerie(upper_dir_name,SequenceCategory{idx,2}) % add the @serie, with BIDS tag
        end
        
        % Add volume & json
        examArray(ex).getSerie(SequenceCategory{idx,2}).addVolume(SequenceCategory{idx,3},SequenceCategory{idx,4});
        examArray(ex).getSerie(SequenceCategory{idx,2}).addJson('json$',SequenceCategory{idx,5});
        
    end % categ
    
end % ex


%% Post operations

% Reorder series to they are in alphabetical==time order, according to their name S01, S02, S03, ...
examArray.reorderSeries;


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
token = regexp(line, ': (.*),','tokens'); % extract the value from the line
if isempty(token)
    result = [];
else
    res    = token{1}{1};
    VECT_cell_raw = strsplit(res,'\n')';
    VECT_cell = VECT_cell_raw(2:end-1);
    VECT_cell = strrep(VECT_cell,',','');
    VECT_cell = strrep(VECT_cell,' ','');
    result    = strrep(VECT_cell,'"','');
end

end % function
