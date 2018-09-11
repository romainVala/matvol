function [ examArray ] = auto_import_obj( baseDir, par )
%AUTO_IMPORT_OBJ will analyse recursively **baseDir** to build objects
%according to the dirs found and json content (sequence name)
%
% Syntax : [ examArray ] = auto_import_obj( baseDir, par )
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

assert( ischar(baseDir)          , 'baseDir must be a char'      )
assert(  exist(baseDir,'dir')==7 , 'baseDir must be a valid dir' )


%% defpar

defpar.anat_regex_volume = '^s.*nii';
defpar.anat_tag_volume   = 's';
defpar.anat_tag_json     = 'json';

defpar.dwi_regex_volume  = '^f.*nii';
defpar.dwi_tag_volume    = 'f';
defpar.dwi_tag_json      = 'json';

defpar.func_regex_volume = '^f.*nii';
defpar.func_tag_volume   = 'f';
defpar.func_tag_json     = 'json';

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

SequenceRegex = 'CsaSeries.MrPhoenixProtocol.tSequenceFileName';

% 1 : sequence name contains this
% 2 : BIDS modality
% 3 : volume regex
% 4 : volume tag
% 5 : json   tag
SequenceCategory = {
    'tfl'  'anat' defpar.anat_regex_volume defpar.anat_tag_volume defpar.anat_tag_json
    'diff' 'dwi'  defpar.dwi_regex_volume  defpar.dwi_tag_volume  defpar.dwi_tag_json
    'bold' 'func' defpar.func_regex_volume defpar.func_tag_volume defpar.func_tag_json
    };


%% Go

examArray = exam(baseDir, '.*'); % add all subdir as @exam objects

for ex = 1 : numel(examArray)
    
    % Fetch all subdir
    subdir = gdir(examArray(ex).path,'.*');
    if isempty(subdir)
        continue
    end
    
    SequenceName = cell(size(subdir)); % container, pre-allocation
    
    if par.verbose > 0
        fprintf( '[%s] : Working on %d/%d : %s \n', mfilename, ex, numel(examArray) , examArray(ex).path )
    end
    
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
        
        % Fetch the line content
        start = regexp(content           , SequenceRegex, 'once');
        stop  = regexp(content(start:end), ','  , 'once');
        line = content(start:start+stop); 
        token = regexp(line, ': (.*),','tokens'); % extract the value from the line
        if isempty(token)
            continue
        end
        res = token{1}{1};
        res = res(2:end-1); % remove " @ beguining and end
        
        split = regexp(res,'\\\\','split'); % exemple : "%SiemensSeq%\\ep2d_bold"
        SequenceName{ser} = split{end};
        
    end % ser
    
    if par.verbose > 1
        fprintf('SequenceName found : \n')
        disp(SequenceName)
        fprintf('\n')
    end
    
    % Try to fit the sequence name to the category
    for idx = 1 : size(SequenceCategory, 1)
        
        where = find( ~cellfun( @isempty , regexp(SequenceName,SequenceCategory{idx,1}) ) );
        if isempty(where)
            continue
        end
        
        [~, upper_dir_name] = get_parent_path(subdir(where));          % extract dir name
        examArray(ex).addSerie(upper_dir_name,SequenceCategory{idx,2}) % add the @serie, with BIDS tag
        
        % Add volume & json
        examArray(ex).getSerie(SequenceCategory{idx,2}).addVolume(SequenceCategory{idx,3},SequenceCategory{idx,4});
        examArray(ex).getSerie(SequenceCategory{idx,2}).addJson('json$',SequenceCategory{idx,5});
        
    end % categ
    
end % ex


end % function
