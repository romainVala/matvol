function [ out ] = get_sequence_param_from_json( filename, sequence )

assert( ischar(filename)          , 'filename must be a char'       )
assert( exist(filename,'file')==2 , 'filename must be a valid file' )

%% Open & read the file

content = get_file_content_as_char(deblank(filename));


%% Fetch all fields

% Sequence name in Siemens console
SequenceFileName = get_field_one(content, 'CsaSeries.MrPhoenixProtocol.tSequenceFileName');
split = regexp(SequenceFileName,'\\\\','split'); % example : "%SiemensSeq%\\ep2d_bold"
out.SequenceFileName = split{end};

% Sequence binary name ?
SequenceName = get_field_one(content, 'SequenceName'); % '*tfl3d1_ns'
out.SequenceName = SequenceName;

% TR
RepetitionTime = get_field_one(content, 'RepetitionTime'); RepetitionTime = str2double(RepetitionTime)/1000;
out.RepetitionTime = RepetitionTime;

% TE
EchoTime = get_field_one(content, 'EchoTime'); EchoTime = str2double(EchoTime)/1000;
out.EchoTime = EchoTime;

 %FA
FlipAngle = get_field_one(content, 'FlipAngle'); FlipAngle = str2double(FlipAngle);
out.FlipAngle = FlipAngle;

% 2D / 3D
MRAcquisitionType = get_field_one(content, 'MRAcquisitionType');
out.MRAcquisitionType = MRAcquisitionType;

% Tesla
MagneticFieldStrength = get_field_one(content, 'MagneticFieldStrength'); MagneticFieldStrength = str2double(MagneticFieldStrength);
out.MagneticFieldStrength = MagneticFieldStrength;

% Slice Timing
if regexp(out.SequenceFileName, '(bold|pace)')
    SliceTiming = get_field_mul(content, 'CsaImage.MosaicRefAcqTimes'); SliceTiming = str2double(SliceTiming(2:end))' / 1000;
    out.SliceTiming = SliceTiming;
end

% Magnitude ? Phase ? ...
ImageType  = get_field_mul(content, 'ImageType'); MAGorPHASE = ImageType{3};
out.ImageType = MAGorPHASE; % M' / 'P' / ...

% Sequence number on the console
% ex1 : mp2rage       will have output series but with identical SequenceID (INV1, INV2, UNI_Image)
% ex2 : gre_field_map will have output series but with identical SequenceID (magnitude, phase)
SequenceID  = get_field_one(content, 'CsaSeries.MrPhoenixProtocol.lSequenceID'); SequenceID = str2double(SequenceID);
out.SequenceID = SequenceID;

% Name of the serie on the console (95% of cases)
SeriesDescription = get_field_one(content, 'SeriesDescription');
out.SeriesDescription = SeriesDescription;

% Name of the serie on the console : some sequences will have specific names, such as SWI
ProtocolName = get_field_one(content, 'CsaSeries.MrPhoenixProtocol.tProtocolName');
out.ProtocolName = ProtocolName; % 'SWI_nigrosome'

if regexp(out.SequenceFileName, 'diff')
    
    % B values
    B_value = get_field_mul(content, 'CsaImage.B_value'); B_value = str2double(B_value)';
    out.B_value = B_value;
    
    % B vectors
    B_vect  = get_field_mul_vect(content, 'CsaImage.DiffusionGradientDirection');
    out.B_vect = B_vect;
    
end

% iPat
ParallelReductionFactorInPlane = get_field_one(content, 'CsaSeries.MrPhoenixProtocol.sPat.lAccelFactPE'); ParallelReductionFactorInPlane = str2double(ParallelReductionFactorInPlane);
out.ParallelReductionFactorInPlane = ParallelReductionFactorInPlane;

if regexp(SequenceFileName,'ep2d')
    
    % MB factor
    MultibandAccelerationFactor = get_field_one(content, 'CsaSeries.MrPhoenixProtocol.sWipMemBlock.alFree\[13\]'); MultibandAccelerationFactor = str2double(MultibandAccelerationFactor);
    out.MultibandAccelerationFactor = MultibandAccelerationFactor;
    
    ReconMatrixPE = get_field_one(content, 'NumberOfPhaseEncodingSteps'); ReconMatrixPE = str2double(ReconMatrixPE);
    out.NumberOfPhaseEncodingSteps = ReconMatrixPE;
    BWPPPE = get_field_one(content, 'CsaImage.BandwidthPerPixelPhaseEncode'); BWPPPE = str2double(BWPPPE);
    out.BandwidthPerPixelPhaseEncode = BWPPPE;
    out.EffectiveEchoSpacing = 1 / (BWPPPE * ReconMatrixPE); % SIEMENS
    out.TotalReadoutTime = out.EffectiveEchoSpacing * (ReconMatrixPE - 1); % FSL
    
end

InPlanePhaseEncodingDirection = get_field_one(content, 'InPlanePhaseEncodingDirection');
out.InPlanePhaseEncodingDirection = InPlanePhaseEncodingDirection;
PhaseEncodingDirectionPositive = get_field_one(content, 'CsaImage.PhaseEncodingDirectionPositive');
out.PhaseEncodingDirectionPositive = PhaseEncodingDirectionPositive;
% Phase : encoding direction
switch InPlanePhaseEncodingDirection % InPlanePhaseEncodingDirection
    case 'COL'
        phase_dir = 'j';
    case 'ROW'
        phase_dir = 'i';
end
if PhaseEncodingDirectionPositive % PhaseEncodingDirectionPositive
    phase_dir = [phase_dir '-'];
end
out.PhaseEncodingDirection = phase_dir;


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
