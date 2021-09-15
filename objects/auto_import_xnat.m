function [ examArray, error_log ] = auto_import_xnat( baseDir, par )
%AUTO_IMPORT_XANT will analyse recursively **baseDir** to build objects
%according to the dirs found and json content (sequence name)
%
% Syntax : [ examArray ] = auto_import_xnat( baseDir, par )
%
% IMPORTANT note : this funcion assumes the the series alphabetical order
% is the the same as the sequence order. For exemple, if you have
% S25_gre_field_map and S26_gre_field_map_phase , they come from the SAME
% sequence even if the magnitude and phase diff arrive in different
% directories.
%
%
% See also exam exam2bids get_sequence_param_from_json
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
defpar.anat_regex_volume      = '^v_.*nii$';
defpar.anat_tag_volume        = 'v';
defpar.anat_tag_json_dcmstack = 'j_dcmstack';
defpar.anat_tag_json_dcm2niix = 'j_dcm2niix';

% dwi
defpar.dwi_regex_volume      = '^v_.*nii$';
defpar.dwi_tag_volume        = 'v';
defpar.dwi_tag_json_dcmstack = 'j_dcmstack';
defpar.dwi_tag_json_dcm2niix = 'j_dcm2niix';

% func
defpar.func_regex_volume      = '^v_.*nii$';
defpar.func_tag_volume        = 'v';
defpar.func_tag_json_dcmstack = 'j_dcmstack';
defpar.func_tag_json_dcm2niix = 'j_dcm2niix';

% fmap
defpar.fmap_regex_volume      = '^v_.*nii$';
defpar.fmap_tag_volume        = 'v';
defpar.fmap_tag_json_dcmstack = 'j_dcmstack';
defpar.fmap_tag_json_dcm2niix = 'j_dcm2niix';

% swi
defpar.swi_regex_volume      = '^v_.*nii$';
defpar.swi_tag_volume        = 'v';
defpar.swi_tag_json_dcmstack = 'j_dcmstack';
defpar.swi_tag_json_dcm2niix = 'j_dcm2niix';

% asl
defpar.asl_regex_volume      = '^v_.*nii$';
defpar.asl_tag_volume        = 'v';
defpar.asl_tag_json_dcmstack = 'j_dcmstack';
defpar.asl_tag_json_dcm2niix = 'j_dcm2niix';

% medic
defpar.medic_regex_volume      = '^v_.*nii$';
defpar.medic_tag_volume        = 'v';
defpar.medic_tag_json_dcmstack = 'j_dcmstack';
defpar.medic_tag_json_dcm2niix = 'j_dcm2niix';

%--------------------------------------------------------------------------

defpar.sge      = 0;
defpar.jobname  = 'matvol_auto_import_xnat';
defpar.walltime = '00:30:00';
defpar.pct      = 0; % Parallel Computing Toolbox

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
    'tfl'                          'anat'  par. anat_regex_volume  par. anat_tag_volume  par. anat_tag_json_dcmstack par. anat_tag_json_dcm2niix % 3DT1 mprage & mp2rage
    'mp2rage'                      'anat'  par. anat_regex_volume  par. anat_tag_volume  par. anat_tag_json_dcmstack par. anat_tag_json_dcm2niix % some mp2rage WIP
    'tse_vfl'                      'anat'  par. anat_regex_volume  par. anat_tag_volume  par. anat_tag_json_dcmstack par. anat_tag_json_dcm2niix % 3DT2 space & 3DFLAIR space_ir
    'diff'                         'dwi'   par.  dwi_regex_volume  par.  dwi_tag_volume  par.  dwi_tag_json_dcmstack par.  dwi_tag_json_dcm2niix % diffusion
    'PtkSmsVB13ADwDualSpinEchoEpi' 'dwi'   par.  dwi_regex_volume  par.  dwi_tag_volume  par.  dwi_tag_json_dcmstack par.  dwi_tag_json_dcm2niix % diffusion from Trio
    '(bold)|(pace)'                'func'  par. func_regex_volume  par. func_tag_volume  par. func_tag_json_dcmstack par. func_tag_json_dcm2niix % bold fmri
    'gre_field_mapping'            'fmap'  par. fmap_regex_volume  par. fmap_tag_volume  par. fmap_tag_json_dcmstack par. fmap_tag_json_dcm2niix % gre_field_mapping
    '^gre$'                        'swi'   par.  swi_regex_volume  par.  swi_tag_volume  par.  swi_tag_json_dcmstack par.  swi_tag_json_dcm2niix % gre SWI
    '^gre$'                        'anat'  par. anat_regex_volume  par. anat_tag_volume  par. anat_tag_json_dcmstack par. anat_tag_json_dcm2niix % gre FLASH
    '^icm_gre$'                    'anat'  par. anat_regex_volume  par. anat_tag_volume  par. anat_tag_json_dcmstack par. anat_tag_json_dcm2niix % gre FLASH ICM
    '^tse$'                        'anat'  par. anat_regex_volume  par. anat_tag_volume  par. anat_tag_json_dcmstack par. anat_tag_json_dcm2niix % tse, usually AX_2DT1 or AX_2DT2
    'ep2d_se'                      'anat'  par. func_regex_volume  par. anat_tag_volume  par. anat_tag_json_dcmstack par. anat_tag_json_dcm2niix % SpinEcho EPI
    'pcasl'                        'asl'   par.  asl_regex_volume  par.  asl_tag_volume  par.  asl_tag_json_dcmstack par.  asl_tag_json_dcm2niix % pCASL
    'pasl'                         'asl'   par.  asl_regex_volume  par.  asl_tag_volume  par.  asl_tag_json_dcmstack par.  asl_tag_json_dcm2niix % 3DASL
    'medic'                        'medic' par.medic_regex_volume  par.medic_tag_volume  par.medic_tag_json_dcmstack par.medic_tag_json_dcm2niix % medic
    };


to_discard = {'haste'};

% put the to_discard on the TOP, not useful now, but maybe latter...
SequenceCategory = [repmat(cell(1,size(SequenceCategory,2)),[length(to_discard) 1]) ; SequenceCategory];
for d = 1 : length(to_discard)
    SequenceCategory(d,[1 2]) = [to_discard(d) {'discard'}];
end


%% Fetch exam, fill series, volumes ans jsons

examArray = exam( baseDir , par.exam_regex ); % add all subdir as @exam objects
N = numel(examArray);
error_log = cell(size(examArray));

if par.pct
    
    parfor ex = 1 : N
        [examArray(ex), error_log{ex}] = analyse_exam( examArray(ex), ex, N, SequenceCategory, par );
    end % ex
    
else
    
    for ex = 1 : N
        [examArray(ex), error_log{ex}] = analyse_exam( examArray(ex), ex, N, SequenceCategory, par );
    end % ex
    
end

%% Post operations

% Reorder series to they are in alphabetical==time order, according to their name S01, S02, S03, ...
examArray.reorderSeries('name');


end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [EXAM, error_log] = analyse_exam( EXAM, ex, N, SequenceCategory, par )

error_log = '';

if par.verbose > 0
    error_log = log(error_log,sprintf( '[%s] : Working on %d/%d : %s \n', mfilename, ex, N , EXAM.path ), 1);
end

% Fetch all series dir
subdir = gdir(EXAM.path, 'SCANS',par.serie_regex,'NIFTI');
if isempty(subdir)
    error_log = log(error_log,warning( 'empty dir' ), 1);
    return
end


%======================================================================

% Fetch dcmstack json files in the serie dir
json = gfile(subdir,'^stack_.*json$',struct('verbose',0));
if isempty(json)
    EXAM.is_incomplete = 1;
    return
end

for j = 1 : length(json)
    if size(json{j},1) > 1 % several lines (several json files in this serie)
        res = regexp(cellstr(json{j}),'\-\d{3}\.json'); % elimenate the -00x.json files, it messes ImagePosition
        json{j} = json{j}(isemptyCELL(res),:);
    end
end

% Extract all parameters
param_struct = get_sequence_param_from_json( json, par );
if isempty(param_struct), return, end
if isstruct(param_struct), param_struct = {param_struct}; end % only happens when there is only 1 serie
hdr_str = fieldnames(param_struct{1});
hdr = cell2struct(num2cell(1:length(hdr_str)),hdr_str,2);

% Transform the structure into a cell, easier to display and manipulate in that case
exam_SequenceData = cell(size(param_struct,1),length(hdr_str));
for p = 1 : numel(param_struct)
    if ~isempty(param_struct{p})
        exam_SequenceData(p,:) = struct2cell(param_struct{p}(1))';
    end
end

% Add one last column
exam_SequenceData(:,end+1) = {''};

%======================================================================

% Try to fit the sequence name to the category
for idx = 1 : size(SequenceCategory, 1)
    
    flag_add = 0;
    
    where = find( ~isemptyCELL( regexp(exam_SequenceData(:,hdr.SequenceFileName),SequenceCategory{idx,1}) ) );
    if isempty(where)
        continue
    end
    
    upper_dir_name = exam_SequenceData(where,hdr.SeriesDescription);
    SeriesNumber   = exam_SequenceData(where,hdr.SeriesNumber     );
    SeriesNumber   = cellfun(@num2str,SeriesNumber,'UniformOutput',0);
    
    
    %%%%%%%%%%%%%%%%%
    % Special cases %
    %%%%%%%%%%%%%%%%%
    
    %----------------------------------------------------------------------
    % func
    %----------------------------------------------------------------------
    if strcmp(SequenceCategory{idx,2},'func')
        
        % type of image (mag, phase, sbref)
        type_ = exam_SequenceData(where,hdr.ImageType        ); % mag or phase
        type = split_(type_);
        type = type(:,3);
        name = exam_SequenceData(where,hdr.SeriesDescription); % serie name
        
        type_SBRef = ~isemptyCELL(regexp(name,'SBRef$'));
        
        type_M = strcmp(type,'M');
        type_P = strcmp(type,'P');
        
        type_M = logical( type_M - type_SBRef );
        
        type_name = cell(size(type));
        type_name(type_SBRef) = {'func_sbref'};
        type_name(type_M    ) = {'func_mag'  };
        type_name(type_P    ) = {'func_phase'};
        
        type_empty = isemptyCELL(type_name); % error managment
        type_name(type_empty) = {'func_UNKNOWN'};
        
        % phase dir
        bids_dir = exam_SequenceData(where,hdr.PhaseEncodingDirection);
        bids_dir(strcmp(bids_dir, 'j' )) = {'PA'};
        bids_dir(strcmp(bids_dir, 'j-')) = {'AP'};
        bids_dir(strcmp(bids_dir, 'i' )) = {'LR'};
        bids_dir(strcmp(bids_dir, 'i-')) = {'RL'};
        
        % contatenate the type and the phase dir
        name = strcat( type_name, '_', bids_dir );
        
        % add series in the exam object smartly, so there is an auto-increment when multiple series
        [unique_name,~,table_name] = unique(name,'stable');
        for n = 1 : length(unique_name)
            EXAM.addSerie('SCANS', strcat('^',SeriesNumber(table_name == n),'$'), 'NIFTI', unique_name{n}) % add the @serie, with BIDS tag
            flag_add = 1;
            exam_SequenceData(where(table_name == n),end) = unique_name(n);
        end
        
        
        %----------------------------------------------------------------------
        % asl
        %----------------------------------------------------------------------
    elseif strcmp(SequenceCategory{idx,2},'asl')
        
        subcategory = {'pcasl','casl','asl'}; % mp2rage
        for sc = 1 : length(subcategory)
            
            where_sc = ~isemptyCELL( regexp(exam_SequenceData(where,hdr.SequenceFileName),subcategory{sc})); % do we find this subcategory ?
            if any(where_sc) % yes
                EXAM.addSerie('SCANS', strcat('^',SeriesNumber(where_sc),'$'), 'NIFTI', subcategory{sc})% add them
                flag_add = 1;
                exam_SequenceData(where(where_sc),end) = subcategory(sc);
                upper_dir_name(where_sc) = []; % remove them from the list
                where(where_sc) = [];
            end
            
        end
        
        if ~isempty(upper_dir_name) % if the list is not empty, it means some non-mp2rage sereies remains, such as classic mprage, or else...
            
            type_ = exam_SequenceData(where,hdr.ImageType        ); % mag or phase
            type = split_(type_);
            type = type(:,3);
            name = exam_SequenceData(where,hdr.SeriesDescription); % serie name
            
            type_SBRef = ~isemptyCELL(regexp(name,'SBRef$'));
            
            type_M = strcmp(type,'M');
            type_P = strcmp(type,'P');
            
            type_M = logical( type_M - type_SBRef );
            
            if any(type_SBRef), EXAM.addSerie(upper_dir_name(type_SBRef), 'asl_sbref'), exam_SequenceData(where(type_SBRef),end) = {'asl_sbref'}; flag_add = 1; end
            if any(type_M)    , EXAM.addSerie(upper_dir_name(type_M    ), 'asl_mag'  ), exam_SequenceData(where(type_M    ),end) = {'asl_mag'  }; flag_add = 1; end
            if any(type_P)    , EXAM.addSerie(upper_dir_name(type_P    ), 'asl_phase'), exam_SequenceData(where(type_P    ),end) = {'asl_phase'}; flag_add = 1; end
            
        end
        
        
        %------------------------------------------------------------------
        % anat
        %------------------------------------------------------------------
    elseif strcmp(SequenceCategory{idx,2},'anat')
        
        subcategory = {'_INV1','_INV2','_UNI_Images','_T1_Images'}; % mp2rage
        for sc = 1 : length(subcategory)
            
            where_sc = ~isemptyCELL( regexp(upper_dir_name,subcategory{sc})); % do we find this subcategory ?
            if any(where_sc) % yes
                EXAM.addSerie('SCANS', strcat('^',SeriesNumber(where_sc),'$'), 'NIFTI', strcat('anat', subcategory{sc})  )% add them
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
            if any( tfl ), EXAM.addSerie('SCANS', strcat('^',SeriesNumber(tfl),'$'), 'NIFTI', 'anat_T1w'), exam_SequenceData(where( tfl ),end) = {'anat_T1w'}; flag_add = 1; end
            
            tse_vfl = strcmp(SequenceFileName, 'tse_vfl');
            if any( tse_vfl )
                spcir = ~isemptyCELL(strfind(SequenceName, 'spcir')); if any( spcir ), EXAM.addSerie('SCANS', strcat('^',SeriesNumber(spcir),'$'), 'NIFTI','anat_FLAIR'), exam_SequenceData(where( spcir ),end) = {'anat_FLAIR'}; flag_add = 1; end
                SequenceName(spcir) = {''}; % delete 'spcir', because regex('spcir') & regex('spc') have the same result...
                spc   = ~isemptyCELL(strfind(SequenceName, 'spc'  )); if any( spc   ), EXAM.addSerie('SCANS', strcat('^',SeriesNumber(spc),'$'), 'NIFTI','anat_T2w'  ), exam_SequenceData(where( spc   ),end) = {'anat_T2w'  }; flag_add = 1; end
            end
            
            gre = strcmp(SequenceFileName, 'gre') | strcmp(SequenceFileName, 'icm_gre');
            if any( gre )
                
                fl = ~isemptyCELL(strfind(SequenceName, 'fl'));
                
                % Remove the localizer
                SeriesDescription = exam_SequenceData(where,hdr.SeriesDescription);
                loca              = ~isemptyCELL(strfind(lower(SeriesDescription), 'loca'));
                if any( loca ), exam_SequenceData(where( loca ),end) = {'discard'}; end % don't add the serie, just discard it
                fl                = logical(fl - loca);
                
                type_  = exam_SequenceData(where,hdr.ImageType); % mag or phase
                type   = split_(type_);
                type   = type(:,3);
                type_M = strcmp(type,'M'); fl_mag = fl & type_M;
                type_P = strcmp(type,'P'); fl_pha = fl & type_P;
                
                if any( fl_mag ), EXAM.addSerie('SCANS', strcat('^',SeriesNumber(fl_mag),'$'), 'NIFTI', 'anat_FLASH_mag'  ), exam_SequenceData(where( fl_mag ),end) = {'anat_FLASH_mag'  }; flag_add = 1; end
                if any( fl_pha ), EXAM.addSerie('SCANS', strcat('^',SeriesNumber(fl_pha),'$'), 'NIFTI', 'anat_FLASH_phase'), exam_SequenceData(where( fl_pha ),end) = {'anat_FLASH_phase'}; flag_add = 1; end
                
            end
            
            tse = strcmp(SequenceFileName, 'tse');
            if any( tse ), EXAM.addSerie('SCANS', strcat('^',SeriesNumber(tse),'$'), 'NIFTI','anat_TSE'), exam_SequenceData(where( tse ),end) = {'anat_TSE'}; flag_add = 1; end
            
            ep2d_se = ~isemptyCELL(strfind(SequenceFileName, 'ep2d_se'));
            if any( ep2d_se )
                
                % type of image (mag, phase, sbref)
                type_ = exam_SequenceData(where,hdr.ImageType        ); % mag or phase
                type = split_(type_);
                type = type(:,3);
                name = exam_SequenceData(where,hdr.SeriesDescription); % serie name
                
                type_SBRef = ~isemptyCELL(regexp(name,'SBRef$'));
                
                type_M = strcmp(type,'M');
                type_P = strcmp(type,'P');
                
                type_M = logical( type_M - type_SBRef );
                
                type_name = cell(size(type));
                type_name(type_SBRef) = {'anat_ep2d_se_sbref'};
                type_name(type_M    ) = {'anat_ep2d_se_mag'  };
                type_name(type_P    ) = {'anat_ep2d_se_phase'};
                
                type_empty = isemptyCELL(type_name); % error managment
                type_name(type_empty) = {'anat_ep2d_se_UNKNOWN'};
                
                % phase dir
                bids_dir = exam_SequenceData(where,hdr.PhaseEncodingDirection);
                bids_dir(strcmp(bids_dir, 'j' )) = {'PA'};
                bids_dir(strcmp(bids_dir, 'j-')) = {'AP'};
                bids_dir(strcmp(bids_dir, 'i' )) = {'LR'};
                bids_dir(strcmp(bids_dir, 'i-')) = {'RL'};
                
                % contatenate the type and the phase dir
                name = strcat( type_name, '_', bids_dir );
                
                % add series in the exam object smartly, so there is an auto-increment when multiple series
                [unique_name,~,table_name] = unique(name,'stable');
                for n = 1 : length(unique_name)
                    EXAM.addSerie('SCANS', strcat('^',SeriesNumber(table_name == n),'$'), 'NIFTI',unique_name{n}) % add the @serie, with BIDS tag
                    flag_add = 1;
                    exam_SequenceData(where(table_name == n),end) = unique_name(n);
                end
                
            end % ep2d_se
            
        end
        
        
        %------------------------------------------------------------------
        % fmap
        %------------------------------------------------------------------
    elseif strcmp(SequenceCategory{idx,2},'fmap')
        
        type_ = exam_SequenceData(where,hdr.ImageType); % mag or phase
        type = split_(type_);
        type = type(:,3);
        type_M = strcmp(type,'M');
        type_P = strcmp(type,'P');
        
        if any(type_M), EXAM.addSerie('SCANS', strcat('^',SeriesNumber(type_M),'$'), 'NIFTI', 'fmap_mag'  ), exam_SequenceData(where(type_M),end) = {'fmap_mag'  }; flag_add = 1; end
        if any(type_P), EXAM.addSerie('SCANS', strcat('^',SeriesNumber(type_P),'$'), 'NIFTI', 'fmap_phase'), exam_SequenceData(where(type_P),end) = {'fmap_phase'}; flag_add = 1; end
        
        
        %------------------------------------------------------------------
        % swi
        %------------------------------------------------------------------
    elseif strcmp(SequenceCategory{idx,2},'swi')
        
        subcategory = {'Mag_Images','Pha_Images','mIP_Images','SWI_Images'}; % swi
        
        for sc = 1 : length(subcategory)
            
            where_sc = ~isemptyCELL( regexp(upper_dir_name,subcategory{sc})); % do we find this subcategory ?
            
            if any(where_sc) % yes
                EXAM.addSerie('SCANS', strcat('^',SeriesNumber(where_sc),'$'), 'NIFTI', strcat('swi', '_', subcategory{sc}(1:end-1)) )% add them
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
                    error_log = log(error_log,str,0);
                end
                
            end % SequenceFileName
            
        end
        
        
        %------------------------------------------------------------------
        % DISCARD
        %------------------------------------------------------------------
    elseif strcmp(SequenceCategory{idx,2},'discard')
        exam_SequenceData(where,end) = SequenceCategory(idx,2);
        continue
        
        
        %------------------------------------------------------------------
        % dwi
        %------------------------------------------------------------------
    elseif strcmp(SequenceCategory{idx,2},'dwi')
        
        % SBRef ?
        name = exam_SequenceData(where,hdr.SeriesDescription); % serie name
        type_SBRef = ~isemptyCELL(regexp(name,'SBRef$'));
        if any(type_SBRef)
            
            where_sbref = where(type_SBRef);
            
            % phase dir
            bids_dir = exam_SequenceData(where_sbref,hdr.PhaseEncodingDirection);
            bids_dir(strcmp(bids_dir, 'j' )) = {'PA'};
            bids_dir(strcmp(bids_dir, 'j-')) = {'AP'};
            bids_dir(strcmp(bids_dir, 'i' )) = {'LR'};
            bids_dir(strcmp(bids_dir, 'i-')) = {'RL'};
            
            % concat dwi + bvals + bvects + phase dir
            name_sbref = strcat('dwi_sbref_', bids_dir );
            
            % add series in the exam object smartly, so there is an auto-increment when multiple series
            [unique_name_sbref,~,table_name_sbref] = unique(name_sbref,'stable');
            for n = 1 : length(unique_name_sbref)
                EXAM.addSerie('SCANS', strcat('^',SeriesNumber(table_name_sbref == n),'$'), 'NIFTI', unique_name_sbref{n}) % add the @serie, with BIDS tag
                exam_SequenceData(where_sbref(table_name_sbref == n),end) = unique_name_sbref(n);
            end
            flag_add = 1;
            where(type_SBRef) = [];
            
        end
        
        
        % Only keep ORIGINAL
        ImageType_ = exam_SequenceData(where,hdr.ImageType); % mag or phase
        ImageType  = split_(ImageType_);
        type_ORIG = strcmp(ImageType(:,1),'ORIGINAL');
        
        where = where(type_ORIG);
        if numel(where)==0
            continue
        else % update the list of series because we might have removed some of them
            SeriesNumber = exam_SequenceData(where,hdr.SeriesNumber     );
            SeriesNumber = cellfun(@num2str,SeriesNumber,'UniformOutput',0);
        end
        
        % DiffDirections
        DiffDirections = exam_SequenceData(where,hdr.DiffDirections);
        DiffDirections = cell2mat(DiffDirections);
        DiffDirections = DiffDirections + 1; % Siemens adds one b0. Its mandatory
        
        % bvals
        B_value = exam_SequenceData(where,hdr.B_value);
        bvals1  = cellfun(@max,B_value);
        BValues = exam_SequenceData(where,hdr.BValue);
        bvals2  = cell2mat(BValues);
        bvals = bvals2;
        bvals(isnan(bvals)) = bvals1(isnan(bvals));
        
        % bvects
        B_vect = exam_SequenceData(where,hdr.B_vect);
        bvects = zeros(size(B_vect));
        for b = 1 : length(B_vect)
            bvects(b) = sum( sum(abs(B_vect{b}),1) > 0 );
        end
        
        % INTERRUPT ?
        INTERRUPT = cell(size(DiffDirections));
        for b = 1 : length(B_vect)
            nDir_theoric = DiffDirections(b);
            nDir_real    = size(B_vect{b},2);
            if nDir_theoric == nDir_real
                INTERRUPT{b} = '';
            elseif nDir_theoric > nDir_real
                INTERRUPT{b} = 'INTERRUPT_';
            else
                % error('wtf ?') % I don't know what to do...
                INTERRUPT{b} = '';
            end
        end
        
        % phase dir
        bids_dir = exam_SequenceData(where,hdr.PhaseEncodingDirection);
        bids_dir(strcmp(bids_dir, 'j' )) = {'PA'};
        bids_dir(strcmp(bids_dir, 'j-')) = {'AP'};
        bids_dir(strcmp(bids_dir, 'i' )) = {'LR'};
        bids_dir(strcmp(bids_dir, 'i-')) = {'RL'};
        
        % concat dwi + bvals + bvects + phase dir
        name = regexprep( strcat('dwi_', INTERRUPT, 'b', cellstr(num2str(bvals)), '_d', cellstr(num2str(bvects)), '_', bids_dir) , ' ', '' );
        
        % add series in the exam object smartly, so there is an auto-increment when multiple series
        [unique_name,~,table_name] = unique(name,'stable');
        for n = 1 : length(unique_name)
            EXAM.addSerie('SCANS', strcat('^',SeriesNumber(table_name == n),'$'), 'NIFTI', unique_name{n}) % add the @serie, with BIDS tag
            flag_add = 1;
            exam_SequenceData(where(table_name == n),end) = unique_name(n);
        end
        
        
        %------------------------------------------------------------------
        % other ?
        %------------------------------------------------------------------
    else
        EXAM.addSerie('SCANS', strcat('^',SeriesNumber,'$'), 'NIFTI', SequenceCategory{idx,2}) % add the @serie, with BIDS tag
        flag_add = 1;
        exam_SequenceData(where,end) = SequenceCategory(idx,2);
    end
    
    % Add volume & json
    if flag_add
        EXAM.getSerie(SequenceCategory{idx,2}).addVolume(SequenceCategory{idx,3},SequenceCategory{idx,4});
        EXAM.getSerie(SequenceCategory{idx,2}).addJson('^stack_.*json$',SequenceCategory{idx,5});
        EXAM.getSerie(SequenceCategory{idx,2}).addJson(    '^v_.*json$',SequenceCategory{idx,6});
    end
    
end % categ

% Add sequence data to each serie, or write a line in error_log
for ser = 1 : size(exam_SequenceData,1)
    
    % Add sequence data
    if ~isempty( exam_SequenceData{ser,end} )
        
        if strcmp(exam_SequenceData{ser,end},'discard')
            % pass
        else
            
            Serie_obj = EXAM.getSerie(exam_SequenceData{ser,end});
            if ~isempty( Serie_obj )
                SeqData_struct = param_struct( ~isemptyCELL( regexp(exam_SequenceData(:,end),exam_SequenceData{ser,end}) ) );
                for s = 1 : length(Serie_obj)
                    Serie_obj(s).sequence = SeqData_struct{s};
                end
            else
                str = warning('[%s] : we have a problem in %s, I can''t find any serie for [ %s ]', mfilename, EXAM.path, exam_SequenceData{ser,end});
                error_log = log(error_log,str,0);
            end
            
        end
        
    else % Error log
        in = exam_SequenceData(ser,:);
        out=cellfun(@num2str,in,'UniformOutput',0); % transform num to str
        str = sprintf(['Unrecognized Sequence : %s with this parameters = [ ' repmat('%s ', [1 numel(out)]) ']'], subdir{ser}, out{:});
        error_log = log(error_log,str);
    end
    
end % ser

if par.verbose > 2
    fprintf('SequenceName found : \n')
    disp(exam_SequenceData)
    fprintf('\n')
end

EXAM.other.SequenceData     = exam_SequenceData;
EXAM.other.SequenceData_hdr = hdr;

% on xnat, the last dir containing the volume is 'NIFTI', so I rename it using SeriesDescription
for ser = 1 : length(EXAM.serie)
        EXAM.serie(ser).name = EXAM.serie(ser).sequence.SeriesDescription;
end % ser

end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = split_( input )

split = regexp(input,'_','split');
result = {};
for s = 1 : length(split)
    result(s,1:length(split{s})) = split{s}; %#ok<AGROW>
end

end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = isemptyCELL( input )

result = cellfun('isempty', input);

end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function error_log = log(error_log,str,print)

if nargin < 3
    print = 0;
end

if print
    fprintf('%s',str)
end

error_log = [error_log str sprintf('\n')];

end % function
