function [ param ] = get_sequence_param_from_json( json_filename, all_fields )
%GET_SEQUENCE_PARAM_FROM_JSON read the content of the json file, and get the most useful parameters
%
% IMPORTANT : the parameters are BIDS compatible.
% Mostly, it means using SI units, with BIDS json names
%
% Syntax :  [ param ] = get_sequence_param_from_json( json_filename              )
% Syntax :  [ param ] = get_sequence_param_from_json( json_filename , all_fields )
%
% json_filename can be char, a cellstr, cellstr containing multi-line char
%
% all_fields is a flag, to add all fields in the structure, even if the paramter is not available
% ex : 3DT1 sequence do not have SliceTiming, but EPI does
% all_fields=1 is usefull if you want to convert the output structure into a cell
%
% see also gfile gdir
%

if nargin == 0
    help(mfilename)
    return
end

AssertIsCharOrCellstr( json_filename )
json_filename = cellstr(json_filename);

if nargin < 2
    all_fields = 0;
end

%% Main loop

param = cell(size(json_filename));

for lvl_1 = 1 : numel(json_filename)
    
    for lvl_2 = 1 : size(json_filename{lvl_1},1)
        
        % Open & read the file --------------------------------------------
        
        content = get_file_content_as_char(json_filename{lvl_1}(lvl_2,:));
        
        
        % Fetch all fields ------------------------------------------------
        
        % Sequence name in Siemens console
        SequenceFileName = get_field_one(content, 'CsaSeries.MrPhoenixProtocol.tSequenceFileName');
        split = regexp(SequenceFileName,'\\\\','split'); % example : "%SiemensSeq%\\ep2d_bold"
        param{lvl_1}(lvl_2).SequenceFileName = split{end};
        
        % Sequence binary name ?
        SequenceName = get_field_one(content, 'SequenceName'); % '*tfl3d1_ns'
        param{lvl_1}(lvl_2).SequenceName = SequenceName;
        
        % TR
        RepetitionTime = get_field_one(content, 'RepetitionTime'); RepetitionTime = str2double(RepetitionTime)/1000;
        param{lvl_1}(lvl_2).RepetitionTime = RepetitionTime;
        
        % TE
        EchoTime = get_field_one(content, 'EchoTime'); EchoTime = str2double(EchoTime)/1000;
        param{lvl_1}(lvl_2).EchoTime = EchoTime;
        
        %FA
        FlipAngle = get_field_one(content, 'FlipAngle'); FlipAngle = str2double(FlipAngle);
        param{lvl_1}(lvl_2).FlipAngle = FlipAngle;
        
        % 2D / 3D
        MRAcquisitionType = get_field_one(content, 'MRAcquisitionType');
        param{lvl_1}(lvl_2).MRAcquisitionType = MRAcquisitionType;
        
        % Tesla
        MagneticFieldStrength = get_field_one(content, 'MagneticFieldStrength'); MagneticFieldStrength = str2double(MagneticFieldStrength);
        param{lvl_1}(lvl_2).MagneticFieldStrength = MagneticFieldStrength;
        
        % Slice Timing
        if all_fields || any(regexp(param{lvl_1}(lvl_2).SequenceFileName, '(bold|pace)'))
            SliceTiming = get_field_mul(content, 'CsaImage.MosaicRefAcqTimes'); SliceTiming = str2double(SliceTiming(2:end))' / 1000;
            param{lvl_1}(lvl_2).SliceTiming = SliceTiming;
        end
        
        % Magnitude ? Phase ? ...
        ImageType  = get_field_mul(content, 'ImageType'); MAGorPHASE = ImageType{3};
        param{lvl_1}(lvl_2).ImageType = MAGorPHASE; % M' / 'P' / ...
        
        % Sequence number on the console
        % ex1 : mp2rage       will have paramput series but with identical SequenceID (INV1, INV2, UNI_Image)
        % ex2 : gre_field_map will have paramput series but with identical SequenceID (magnitude, phase)
        SequenceID  = get_field_one(content, 'CsaSeries.MrPhoenixProtocol.lSequenceID'); SequenceID = str2double(SequenceID);
        param{lvl_1}(lvl_2).SequenceID = SequenceID;
        
        % Name of the serie on the console (95% of cases)
        SeriesDescription = get_field_one(content, 'SeriesDescription');
        param{lvl_1}(lvl_2).SeriesDescription = SeriesDescription;
        
        % Name of the serie on the console : some sequences will have specific names, such as SWI
        ProtocolName = get_field_one(content, 'CsaSeries.MrPhoenixProtocol.tProtocolName');
        param{lvl_1}(lvl_2).ProtocolName = ProtocolName; % 'SWI_nigrosome'
        
        % bvals & bvecs
        if  all_fields || any(regexp(param{lvl_1}(lvl_2).SequenceFileName, 'diff'))
            
            B_value = get_field_mul(content, 'CsaImage.B_value'); B_value = str2double(B_value)';
            param{lvl_1}(lvl_2).B_value = B_value;
            
            B_vect  = get_field_mul_vect(content, 'CsaImage.DiffusionGradientDirection');
            param{lvl_1}(lvl_2).B_vect = B_vect;
            
        end
        
        % iPat
        ParallelReductionFactorInPlane = get_field_one(content, 'CsaSeries.MrPhoenixProtocol.sPat.lAccelFactPE'); ParallelReductionFactorInPlane = str2double(ParallelReductionFactorInPlane);
        param{lvl_1}(lvl_2).ParallelReductionFactorInPlane = ParallelReductionFactorInPlane;
        
        if  all_fields || any(regexp(SequenceFileName,'ep2d'))
            
            % MB factor
            MultibandAccelerationFactor = get_field_one(content, 'CsaSeries.MrPhoenixProtocol.sWipMemBlock.alFree\[13\]'); MultibandAccelerationFactor = str2double(MultibandAccelerationFactor);
            param{lvl_1}(lvl_2).MultibandAccelerationFactor = MultibandAccelerationFactor;
            
            % EffectiveEchoSpacing & TotalReadoutTime
            ReconMatrixPE = get_field_one(content, 'NumberOfPhaseEncodingSteps'); ReconMatrixPE = str2double(ReconMatrixPE);
            param{lvl_1}(lvl_2).NumberOfPhaseEncodingSteps = ReconMatrixPE;
            BWPPPE = get_field_one(content, 'CsaImage.BandwidthPerPixelPhaseEncode'); BWPPPE = str2double(BWPPPE);
            param{lvl_1}(lvl_2).BandwidthPerPixelPhaseEncode = BWPPPE;
            param{lvl_1}(lvl_2).EffectiveEchoSpacing = 1 / (BWPPPE * ReconMatrixPE); % SIEMENS
            param{lvl_1}(lvl_2).TotalReadoutTime = param{lvl_1}(lvl_2).EffectiveEchoSpacing * (ReconMatrixPE - 1); % FSL
            
        end
        
        % Phase : encoding direction
        InPlanePhaseEncodingDirection = get_field_one(content, 'InPlanePhaseEncodingDirection');
        param{lvl_1}(lvl_2).InPlanePhaseEncodingDirection = InPlanePhaseEncodingDirection;
        PhaseEncodingDirectionPositive = get_field_one(content, 'CsaImage.PhaseEncodingDirectionPositive');
        param{lvl_1}(lvl_2).PhaseEncodingDirectionPositive = PhaseEncodingDirectionPositive;
        switch InPlanePhaseEncodingDirection % InPlanePhaseEncodingDirection
            case 'COL'
                phase_dir = 'j';
            case 'ROW'
                phase_dir = 'i';
            otherwise
                warning('wtf ? InPlanePhaseEncodingDirection')
                phase_dir = '';
        end
        if PhaseEncodingDirectionPositive % PhaseEncodingDirectionPositive
            phase_dir = [phase_dir '-']; %#ok<AGROW>
        end
        param{lvl_1}(lvl_2).PhaseEncodingDirection = phase_dir;
        
    end % lvl_2
    
end % lvl_1

% Jut for conviniency
if numel(param) == 1
    param = param{1};
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
