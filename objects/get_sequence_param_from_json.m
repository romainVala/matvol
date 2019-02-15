function [ param ] = get_sequence_param_from_json( json_filename, par )
%GET_SEQUENCE_PARAM_FROM_JSON read the content of the json file, and get the most useful parameters
%
% IMPORTANT : the parameters are BIDS compatible.
% Mostly, it means using SI units, with BIDS json names
%
% Syntax :  [ param ] = get_sequence_param_from_json( json_filename       )
% Syntax :  [ param ] = get_sequence_param_from_json( json_filename , par )
%
% json_filename can be char, a cellstr, cellstr containing multi-line char
%
% par is a structure of parameter
%   par.pct is a flag to activate Parallel Computing Toolbox
%   par.read_sequence_param =1  flag to activate reading of all sequence parameter
%
% see also gfile gdir parpool
%

if nargin == 0
    help(mfilename)
    return
end

AssertIsCharOrCellstr( json_filename )
json_filename = cellstr(json_filename);

if ~exist('par','var')
    par = ''; % for defpar
end

defpar.pct = 0;% Parallel Computing Toolbox
defpar.read_sequence_param = 1;% if 1 read all sequence parameter assuming dcmstack json style

par = complet_struct(par,defpar);

pct = par.pct;

%% Main loop

param = cell(size(json_filename));

if pct
    
    parfor idx = 1 : numel(json_filename)
        param{idx} = parse_jsons(json_filename{idx},par);
    end
    
else
    
    for idx = 1 : numel(json_filename)
        param{idx} = parse_jsons(json_filename{idx},par);
    end
    
end

% Jut for conviniency
if numel(param) == 1
    param = param{1};
end


end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = parse_jsons(json_filename,par)

data = struct([]);

for j = 1 : size(json_filename,1)
    %% Open & read the file
    
    content = get_file_content_as_char(json_filename(j,:));
    if isempty(content)
        warning( 'Empty file : %s', json_filename(j,:) )
        continue
    end
    
    
    %% Fetch all fields
    
    % TR
    RepetitionTime = get_field_one(content, 'RepetitionTime');
    if ~isempty(RepetitionTime) && par.read_sequence_param
        
        %------------------------------------------------------------------
        % Sequence
        %------------------------------------------------------------------
        
        data_file.RepetitionTime    = str2double( RepetitionTime ) / 1000           ;
        data_file.MRAcquisitionType = get_field_one( content, 'MRAcquisitionType' ) ;
        
        % Sequence name in Siemens console
        SequenceFileName = get_field_one(content, 'CsaSeries.MrPhoenixProtocol.tSequenceFileName');
        if ~isempty(SequenceFileName)
            split = regexp(SequenceFileName,'\\\\','split'); % example : "%SiemensSeq%\\ep2d_bold"
            data_file.SequenceFileName = split{end};
        else
            data_file.SequenceFileName = '';
        end
        
        % Sequence binary name ?
        SequenceName = get_field_one(content, 'SequenceName'); % '*tfl3d1_ns'
        data_file.SequenceName = SequenceName;
        
        data_file.EchoTime          = str2double( get_field_one( content, 'EchoTime'          ) ) / 1000; % second
        data_file.FlipAngle         = str2double( get_field_one( content, 'FlipAngle'         ) )       ; % degre
        data_file.InversionTime     = str2double( get_field_one( content, 'InversionTime'     ) ) / 1000; % second
        
        % Sequence number on the console
        % ex1 : mp2rage       will have paramput series but with identical SequenceID (INV1, INV2, UNI_Image)
        % ex2 : gre_field_map will have paramput series but with identical SequenceID (magnitude, phase)
        data_file.SequenceID = str2double( get_field_one(content, 'CsaSeries.MrPhoenixProtocol.lSequenceID') );
        
        data_file.ScanningSequence = get_field_mul(content, 'ScanningSequence');
        data_file.SequenceVariant  = get_field_mul(content, 'SequenceVariant' );
        data_file.ScanOptions      = get_field_mul(content, 'ScanOptions'     );
        
        % Slice Timing
        SliceTiming = get_field_mul(content, 'CsaImage.MosaicRefAcqTimes',0); SliceTiming = str2double(SliceTiming(2:end))' / 1000;
        data_file.SliceTiming = SliceTiming;
        
        % bvals & bvecs
        B_value                  =             get_field_mul     (content, 'CsaImage.B_value', 0);
        B_value                  = str2double(B_value)';
        data_file.B_value        = B_value;
        B_vect                   =             get_field_mul_vect(content, 'CsaImage.DiffusionGradientDirection');
        data_file.B_vect         = B_vect;
        data_file.BValue         = str2double( get_field_one     ( content, '"CsaSeries.MrPhoenixProtocol.sDiffusion.alBValue\[1\]"' ) );
        data_file.DiffDirections = str2double( get_field_one     ( content, 'CsaSeries.MrPhoenixProtocol.sDiffusion.lDiffDirections' ) );
        if ~isempty( B_value ) && isscalar(B_value) && B_value == 0 && isempty(B_vect) %#ok<BDSCI> % only a b0, special case...
            data_file.DiffDirections = -1;
        end
        
        %------------------------------------------------------------------
        % Machine
        %------------------------------------------------------------------
        data_file.MagneticFieldStrength = str2double( get_field_one( content, 'MagneticFieldStrength' ) ); % Tesla
        data_file.Manufacturer          =             get_field_one( content, 'Manufacturer'          )  ;
        data_file.ManufacturerModelName =             get_field_one( content, 'ManufacturerModelName' )  ;
        data_file.Modality              =             get_field_one( content, 'Modality'              )  ;
        
        %------------------------------------------------------------------
        % Subject
        %------------------------------------------------------------------
        data_file.PatientName      =clean_string(get_field_one( content, 'PatientName'      ) ) ;
        PatientAge       =             get_field_one( content, 'PatientAge'       )   ;
        if ~isempty(PatientAge), PatientAge(end) = []; end% remove Y from 053Y, (this if/)
        data_file.PatientAge       = str2double( PatientAge )   ;
        data_file.PatientBirthDate = str2double( get_field_one( content, 'PatientBirthDate' ) ) ;
        data_file.PatientWeight    = str2double( get_field_one( content, 'PatientWeight'    ) ) ;
        data_file.PatientSex       =             get_field_one( content, 'PatientSex'       )   ;
        
        %------------------------------------------------------------------
        % Date / Time
        %------------------------------------------------------------------
        data_file.AcquisitionDate = str2double( get_field_one( content, 'AcquisitionDate' ) ) ;
        data_file.StudyDate       = str2double( get_field_one( content, 'StudyDate'       ) ) ;
        data_file.StudyTime       = str2double( get_field_one( content, 'StudyTime'       ) ) ;
        data_file.AcquisitionTime = min(cellfun( @str2double, get_field_mul(content, 'AcquisitionTime',0) )); % AcquisitionTime is special, it depends on 3D vs 4D
        tt=num2str(data_file.AcquisitionDate) ;
        if ~isempty(tt) && ~strcmp(tt,'NaN')
            data_file.AcqDateStr = [tt(1:4), '_', tt(5:6), '_' tt(7:8)];
        else
            data_file.AcqDateStr = '';
        end
        
        %------------------------------------------------------------------
        % Study / Serie
        %------------------------------------------------------------------
        data_file.StudyID           = str2double( get_field_one( content, 'StudyID'           ) ) ;
        data_file.StudyInstanceUID  =             get_field_one( content, 'StudyInstanceUID'  )   ;
        data_file.SeriesInstanceUID =             get_field_one( content, 'SeriesInstanceUID' )   ;
        data_file.StudyDescription  =clean_string(get_field_one( content, 'StudyDescription'  ) ) ;
        data_file.SeriesDescription =             get_field_one( content, 'SeriesDescription' )   ;
        data_file.ProtocolName      =clean_string(get_field_one( content, 'ProtocolName'      ) ) ;
        data_file.SeriesNumber      = str2double( get_field_one( content, 'SeriesNumber'      ) ) ;
        data_file.TotalScanTimeSec  = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.lTotalScanTimeSec') );
        
        
        %------------------------------------------------------------------
        % Image
        %------------------------------------------------------------------
        data_file.ImageType                    =                       get_field_mul     ( content, '"ImageType'                  )  ; % M' / 'P' / ... % Magnitude ? Phase ? ...
        data_file.ImageOrientationPatient      = cellfun( @str2double, get_field_mul     ( content, 'ImageOrientationPatient' ,0 ) );
        switch data_file.MRAcquisitionType
            case '2D'
                data_file.ImagePositionPatient = cellfun( @str2double, get_field_mul     ( content, 'ImagePositionPatient'    ,0 ) );
            case '3D'
                ImagePositionPatient                    =              get_field_mul_vect( content, 'ImagePositionPatient'       )  ;
                data_file.ImagePositionPatient          = ImagePositionPatient(:,1);
                %data_file.ImagePositionPatient2         = ImagePositionPatient(:,2); %need of the same field in 2D
                %data_file.ImagePositionPatient_nbslice = size(ImagePositionPatient,2);
        end
        data_file.dInPlaneRot   = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sSliceArray.asSlice\[0\].dInPlaneRot'   ) ) ;
        data_file.sPositiondCor = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sSliceArray.asSlice\[0\].sPosition.dCor') ) ;
        data_file.sPositiondTra = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sSliceArray.asSlice\[0]\.sPosition.dTra') ) ;
        data_file.sNormaldTra   = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sSliceArray.asSlice\[0\].sNormal.dTra'  ) ) ;
        data_file.AbsTablePosition = str2double( get_field_one( content, 'CsaSeries.AbsTablePosition' ) );
        data_file.PatientPosition  = get_field_one( content, 'PatientPosition');

        %------------------------------------------------------------------
        % Matrix / Acq
        %------------------------------------------------------------------
        data_file.PixelBandwidth       = str2double( get_field_one( content, 'PixelBandwidth'       ) ) ; % Hz/pixel
        data_file.SliceThickness       = str2double( get_field_one( content, 'SliceThickness'       ) ) ; % millimeter
        data_file.SpacingBetweenSlices = str2double( get_field_one( content, 'SpacingBetweenSlices' ) ) ; % millimeter
        data_file.ProtocolSliceNumber  = str2double( get_field_one( content, 'CsaImage.ProtocolSliceNumber'                           ) ) ; % ?
        data_file.Rows                 = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sKSpace.lBaseResolution'    ) ) ;
        data_file.Columns              = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sKSpace.lPhaseEncodingLines') ) ;
        data_file.PixelSpacing         = cellfun( @str2double, get_field_mul( content, 'PixelSpacing',0) );
        switch data_file.MRAcquisitionType
            case '2D'
                data_file.Slices       = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sSliceArray.lSize'          ) ) ;
            case '3D'
                data_file.Slices       = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sKSpace.lImagesPerSlab'     ) ) ;
        end
        
        % iPat
        data_file.ParallelReductionFactorInPlane = str2double( get_field_one(content, 'CsaSeries.MrPhoenixProtocol.sPat.lAccelFactPE') );
        
        % MB factor
        MultibandAccelerationFactor = get_field_one(content, 'CsaSeries.MrPhoenixProtocol.sWipMemBlock.alFree\[13\]'); MultibandAccelerationFactor = str2double(MultibandAccelerationFactor);
        data_file.MultibandAccelerationFactor = MultibandAccelerationFactor;
        
        % EffectiveEchoSpacing & TotalReadoutTime
        ReconMatrixPE = str2double( get_field_one(content, 'NumberOfPhaseEncodingSteps') );
        data_file.NumberOfPhaseEncodingSteps = ReconMatrixPE;
        BWPPPE = str2double( get_field_one(content, 'CsaImage.BandwidthPerPixelPhaseEncode') );
        data_file.BandwidthPerPixelPhaseEncode = BWPPPE;
        data_file.EffectiveEchoSpacing = 1 / (BWPPPE * ReconMatrixPE); % SIEMENS
        data_file.TotalReadoutTime = data_file.EffectiveEchoSpacing * (ReconMatrixPE - 1); % FSL
        
        % Phase : encoding direction
        InPlanePhaseEncodingDirection = get_field_one(content, 'InPlanePhaseEncodingDirection');
        data_file.InPlanePhaseEncodingDirection = InPlanePhaseEncodingDirection;
        PhaseEncodingDirectionPositive = get_field_one(content, 'CsaImage.PhaseEncodingDirectionPositive'); PhaseEncodingDirectionPositive = str2double(PhaseEncodingDirectionPositive);
        data_file.PhaseEncodingDirectionPositive = PhaseEncodingDirectionPositive;
        if ~isempty( InPlanePhaseEncodingDirection ) % f*cking bug...
            switch InPlanePhaseEncodingDirection % InPlanePhaseEncodingDirection
                case 'COL'
                    phase_dir = 'j';
                case 'ROW'
                    phase_dir = 'i';
                otherwise
                    warning('wtf ? InPlanePhaseEncodingDirection')
                    phase_dir = '';
            end
            if PhaseEncodingDirectionPositive
                phase_dir = [phase_dir '-']; %#ok<AGROW>
            end
            data_file.PhaseEncodingDirection = phase_dir;
        else
            data_file.PhaseEncodingDirection = '';
        end
        
        data_file.PATMode     = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sPat.ucPATMode'     ) ) ;
        data_file.AccelFactPE = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sPat.lAccelFactPE'  ) ) ;
        data_file.AccelFact3D = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sPat.lAccelFact3D'  ) ) ;
        data_file.RefLinesP   = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sPat.lRefLinesP'    ) ) ;
        data_file.RefScanMode = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sPat.ucRefScanMode' ) ) ;
        
        data_file.SliceArrayMode           = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sSliceArray.ucMode'                    ) ) ;
        data_file.SliceArrayConcatenations = str2double( get_field_one( content, 'CsaSeries.SliceArrayConcatenations'                                ) ) ;
        data_file.PhysioECGScanWindow      = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sPhysioImaging.sPhysioECG.lScanWindow' ) ) ;
        
        data_file.Repetitions = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.lRepetitions' ) ) ; % nVolumes ?
        
        %------------------------------------------------------------------
        % Coil
        %------------------------------------------------------------------
        data_file.ImaCoilString            =             get_field_one( content, 'CsaImage.ImaCoilString'                                                                        );
        %same data_file.CoilString               =             get_field_one( content, 'CsaSeries.CoilString'                                                                          );
        data_file.CoilStringForConversion  =             get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sCoilSelectMeas.sCoilStringForConversion'                          );
        data_file.nRxCoilSelected          = str2double( get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sCoilSelectMeas.aRxCoilSelectData\[0\].asList.__attribute__.size') );
        
        CoilString               =  get_field_one( content, 'CsaSeries.MrPhoenixProtocol.asCoilSelectMeas\[0\].asList\[0\].sCoilElementID.tCoilID');
        if isempty(CoilString)
            CoilString           =  get_field_one( content, 'CsaSeries.MrPhoenixProtocol.sCoilSelectMeas.aRxCoilSelectData\[0\].asList\[0\].sCoilElementID.tCoilID');
        end
        data_file.CoilString = CoilString;
        
        
    end % if RepetitionTime not empty
    
    
    %% Fetch all normal fields at first level
    
    tokens = regexp(content,'\n  "(\w+)": ([0-9.-]+)','tokens');
    for t = 1 : length(tokens)
        data_file.(tokens{t}{1}) = str2double(tokens{t}{2});
    end
    
    if j == 1
        data = data_file;
    else
        data(j) = data_file;
    end
    
end % j

end % function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function out = get_list( content, list )
%
% out = struct;
% for i = 1 : size(list,1)
%     out.(list{i,1}) = get_field_one(content, list{i,1});
%     if size(list,2) > 1
%         switch list{i,2}
%             case 'str'
%                 % pass
%             case 'num'
%                 out.(list{i,1}) = str2double(out.(list{i,1}));
%         end
%     end
% end
%
% end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = get_field_one(content, regex)

% Fetch the line content
start = regexp(content           , regex, 'once');
stop  = regexp(content(start:end), ','  , 'once');
line = content(start:start+stop);
token = regexp(line, ': (.*),','tokens'); % extract the value from the line
if isempty(token)
    result = [];
    return
else
    res = token{1}{1};
    if strcmp(res(1),'"')
        result = res(2:end-1); % remove " @ beguining and end
    else
        result = res;
    end
end
result = strrep(result,';','_');

end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = get_field_mul(content, regex,concatenate)

if ~exist('concatenate','var'),    concatenate=1; end

% Fetch the line content
start = regexp(content           , regex, 'once');
idx1 = regexp(content(start:end),'[','once');
idx2 = regexp(content(start:end),',','once');
if idx1 < idx2
    stop  = regexp(content(start:end), ']'  , 'once');
else
    stop  = regexp(content(start:end), ','  , 'once');
end
line = content(start:start+stop);

if strfind(line(length(regex):end),'Csa') % in cas of single value, and not multiple ( such as signle B0 value for diff )
    stop  = regexp(content(start:end), ','  , 'once');
    line = content(start:start+stop);
end

token = regexp(line, ': (.*),','tokens'); % extract the value from the line
if isempty(token)
    result = [];
    return
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

if concatenate
    if ischar(result{1}) % instead of a cell vector of string just concatenate with _
        rr=result{1};
        for kk=2:length(result); rr=[rr '_' result{kk}];end
        result = rr;
    end
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
if isempty(v)
    result=v;
else
    result = reshape(v,[3 numel(v)/3]);
end
end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dirname = clean_string(dirname)


% cherche s'il y a des caracteres non alphanumeriques dans la chaine
str = isstrprop(dirname,'alphanum');
spec = find(~str);
% remplace les caracteres non alphanumeriques par des '_'
dirname(spec) = '_';

ii =strfind(dirname,'µ');
dirname(ii) = 'm';

%trouve le é
dirname(double(dirname)==233) = 'e';
%trouve le è
dirname(double(dirname)==232) = 'e';
%trouve le ^o
dirname(double(dirname)==244) = 'o';

% pour fignoler, on supprime un '_' s'il y en a 2 qui se suivent
while ~isempty(strfind(dirname,'__'));
    dirname = strrep(dirname,'__','_');
end
% toujours pour fignoler, si le nom se termine par un '_', on l'elimine
if(dirname(length(dirname)) == '_')
    dirname(length(dirname)) = '';
end
end % function
